//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import EngineCore

extension Animation {

    public func duration(defaultDuration: CGFloat) -> TimeInterval {
        guard let resolved = Resolved(animation: self) else { return defaultDuration }
        switch resolved.timingCurve {
        case .default:
            return defaultDuration / resolved.speed
        default:
            return (resolved.timingCurve.duration ?? defaultDuration) / resolved.speed
        }
    }

    public var delay: TimeInterval? {
        guard let resolved = Resolved(animation: self) else { return nil }
        return resolved.delay
    }

    public var timingParameters: UITimingCurveProvider? {
        guard let resolved = Resolved(animation: self) else { return nil }
        switch resolved.timingCurve {
        case .default:
            return nil
        case .bezier, .spring, .fluidSpring:
            return AnimationTimingCurveProvider(
                timingCurve: resolved.timingCurve
            )
        }
    }

    struct Resolved {
        enum TimingCurve: Codable, Equatable {
            case `default`

            struct BezierAnimation: Codable, Equatable {
                struct AnimationCurve: Codable, Equatable {
                    var ax: Double
                    var bx: Double
                    var cx: Double
                    var ay: Double
                    var by: Double
                    var cy: Double
                }

                var duration: TimeInterval
                var curve: AnimationCurve
            }
            case bezier(BezierAnimation)

            struct SpringAnimation: Codable, Equatable {
                var mass: Double
                var stiffness: Double
                var damping: Double
                var initialVelocity: Double
            }
            case spring(SpringAnimation)

            struct FluidSpringAnimation: Codable, Equatable {
                var duration: Double
                var dampingFraction: Double
                var blendDuration: TimeInterval
            }
            case fluidSpring(FluidSpringAnimation)

            init?(animator: Any) {
                func project<T>(_ animator: T) -> TimingCurve? {
                    switch _typeName(T.self, qualified: false) {
                    case "DefaultAnimation":
                        return .default
                    case "BezierAnimation":
                        guard MemoryLayout<BezierAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let bezier = unsafeBitCast(animator, to: BezierAnimation.self)
                        return .bezier(bezier)
                    case "SpringAnimation":
                        guard MemoryLayout<SpringAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let spring = unsafeBitCast(animator, to: SpringAnimation.self)
                        return .spring(spring)
                    case "FluidSpringAnimation":
                        guard MemoryLayout<FluidSpringAnimation>.size == MemoryLayout<T>.size else {
                            return nil
                        }
                        let fluidSpring = unsafeBitCast(animator, to: FluidSpringAnimation.self)
                        return .fluidSpring(fluidSpring)
                    default:
                        return nil
                    }
                }
                guard let timingCurve = _openExistential(animator, do: project) else {
                    return nil
                }
                self = timingCurve
            }

            var duration: TimeInterval? {
                switch self {
                case .default:
                    return nil
                case .bezier(let bezierCurve):
                    return bezierCurve.duration
                case .spring(let springCurve):
                    let naturalFrequency = sqrt(springCurve.stiffness / springCurve.mass)
                    let dampingRatio = springCurve.damping / (2.0 * naturalFrequency)
                    guard dampingRatio < 1 else {
                        let duration = 2 * .pi / (naturalFrequency * dampingRatio)
                        return duration
                    }
                    let decayRate = dampingRatio * naturalFrequency
                    let duration = -log(0.01) / decayRate
                    return duration
                case .fluidSpring(let fluidSpringCurve):
                    return fluidSpringCurve.duration + fluidSpringCurve.blendDuration
                }
            }
        }

        var timingCurve: TimingCurve
        var delay: TimeInterval
        var speed: TimeInterval

        init(
            timingCurve: TimingCurve,
            delay: TimeInterval,
            speed: TimeInterval
        ) {
            self.timingCurve = timingCurve
            self.delay = delay
            self.speed = speed
        }

        init?(animation: Animation) {
            var animator: Any
            if #available(iOS 17.0, *) {
                animator = animation.base
            } else {
                guard let base = Mirror(reflecting: animation).descendant("base") else {
                    return nil
                }
                animator = base
            }
            var delay: TimeInterval = 0
            var speed: TimeInterval = 1
            var mirror = Mirror(reflecting: animator)
            while let base = mirror.descendant("_base") ?? mirror.descendant("base") ?? mirror.descendant("animation") {
                if let modifier = mirror.descendant("modifier") {
                    mirror = Mirror(reflecting: modifier)
                }
                if let d = mirror.descendant("delay") as? TimeInterval {
                    delay += d
                }
                if let s = mirror.descendant("speed") as? TimeInterval {
                    speed *= s
                }
                animator = base
                mirror = Mirror(reflecting: animator)
            }
            guard let timingCurve = TimingCurve(animator: animator) else {
                return nil
            }
            self.timingCurve = timingCurve
            self.delay = delay
            self.speed = speed
        }
    }

    func resolved() -> Resolved? {
        Resolved(animation: self)
    }
}

extension UIViewPropertyAnimator {

    public convenience init(
        animation: Animation?,
        defaultDuration: TimeInterval = 0.35,
        defaultCompletionCurve: UIView.AnimationCurve = .easeInOut
    ) {
        if let resolved = animation?.resolved() {
            switch resolved.timingCurve {
            case .default:
                self.init(duration: defaultDuration / resolved.speed, curve: defaultCompletionCurve.toSwiftUI())
            case .bezier, .spring, .fluidSpring:
                let duration = (resolved.timingCurve.duration ?? defaultDuration) / resolved.speed
                self.init(
                    duration: duration,
                    timingParameters: AnimationTimingCurveProvider(
                        timingCurve: resolved.timingCurve
                    )
                )
            }
        } else {
            self.init(duration: defaultDuration, curve: defaultCompletionCurve.toSwiftUI())
        }
    }
}

extension UIView {

    @available(iOS, deprecated: 18.0, message: "Use the builtin UIView.animate")
    public static func animate(
        with animation: Animation?,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let animation else {
            animations()
            completion?(true)
            return
        }

        let animator = UIViewPropertyAnimator(animation: animation)
        animator.addAnimations(animations)
        if let completion {
            animator.addCompletion { position in
                completion(position == .end)
            }
        }
        animator.startAnimation(afterDelay: animation.delay ?? 0)
    }
}

@objc(TransmissionAnimationTimingCurveProvider)
private class AnimationTimingCurveProvider: NSObject, UITimingCurveProvider {

    let timingCurve: Animation.Resolved.TimingCurve
    init(timingCurve: Animation.Resolved.TimingCurve) {
        self.timingCurve = timingCurve
    }

    required init?(coder: NSCoder) {
        if let data = coder.decodeData(),
            let timingCurve = try? JSONDecoder().decode(Animation.Resolved.TimingCurve.self, from: data) {
            self.timingCurve = timingCurve
        } else {
            return nil
        }
    }

    func encode(with coder: NSCoder) {
        if let data = try? JSONEncoder().encode(timingCurve) {
            coder.encode(data)
        }
    }

    func copy(with zone: NSZone? = nil) -> Any {
        AnimationTimingCurveProvider(timingCurve: timingCurve)
    }


    // MARK: - UITimingCurveProvider

    var timingCurveType: UITimingCurveType {
        switch timingCurve {
        case .default:
            return .builtin
        case .bezier:
            return .cubic
        case .spring, .fluidSpring:
            return .spring
        }
    }

    var cubicTimingParameters: UICubicTimingParameters? {
        switch timingCurve {
        case .bezier(let bezierCurve):
            let curve = bezierCurve.curve
            let p1x = curve.cx / 3
            let p1y = curve.cy / 3
            let p1 = CGPoint(x: p1x, y: p1y)
            let p2x = curve.cx - (1 / 3) * (curve.cx - curve.bx)
            let p2y = curve.cy - (1 / 3) * (curve.cy - curve.by)
            let p2 = CGPoint(x: p2x, y: p2y)
            return UICubicTimingParameters(
                controlPoint1: p1,
                controlPoint2: p2
            )
        case .default, .spring, .fluidSpring:
            return nil
        }
    }

    var springTimingParameters: UISpringTimingParameters? {
        switch timingCurve {
        case .spring(let springCurve):
            return UISpringTimingParameters(
                mass: springCurve.mass,
                stiffness: springCurve.stiffness,
                damping: springCurve.damping,
                initialVelocity: CGVector(
                    dx: springCurve.initialVelocity,
                    dy: springCurve.initialVelocity
                )
            )
        case .fluidSpring(let fluidSpringCurve):
            let initialVelocity = log(fluidSpringCurve.dampingFraction) / (fluidSpringCurve.duration - fluidSpringCurve.blendDuration)
            return UISpringTimingParameters(
                dampingRatio: fluidSpringCurve.dampingFraction,
                initialVelocity: CGVector(
                    dx: initialVelocity,
                    dy: initialVelocity
                )
            )
        case .default, .bezier:
            return nil
        }
    }
}
