//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A modifier that samples the rendered containing view and modifies the color scheme
/// to be light/dark depending on the average color
///
/// Only adapts if the `preferredColorScheme` is not the current color scheme
///
@frozen
public struct AdaptiveColorSchemeModifier: ViewModifier {

    var preferredColorScheme: ColorScheme?
    var boundaries: LuminanceColorSchemeBoundaries
    var isEnabled: Bool

    @State var adaptiveColorScheme: ColorScheme?
    @Environment(\.colorScheme) var colorScheme

    public init(
        preferredColorScheme: ColorScheme? = nil,
        boundaries: LuminanceColorSchemeBoundaries = .default,
        isEnabled: Bool = true
    ) {
        self.boundaries = boundaries
        self.preferredColorScheme = preferredColorScheme
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, adaptiveColorScheme)
            .animation(.default, value: adaptiveColorScheme)
            .modifier(
                LuminanceTrackingReaderModifier(
                    colorScheme: $adaptiveColorScheme,
                    boundaries: boundaries,
                    isEnabled: isEnabled && preferredColorScheme != colorScheme
                )
            )
    }
}

extension View {

    /// A modifier that samples the rendered containing view and modifies the color scheme
    /// to be light/dark depending on the average color
    ///
    /// Only adapts if the `preferredColorScheme` is not the current color scheme
    ///
    public func adaptiveColorScheme(
        preferredColorScheme: ColorScheme? = nil,
        boundaries: LuminanceColorSchemeBoundaries = .default,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            AdaptiveColorSchemeModifier(
                preferredColorScheme: preferredColorScheme,
                boundaries: boundaries,
                isEnabled: isEnabled
            )
        )
    }
}

@frozen
public struct LuminanceColorSchemeBoundaries: Equatable, Sendable {
    public var dark: Double
    public var light: Double

    public init(dark: Double, light: Double) {
        self.dark = dark
        self.light = light
    }

    public static let `default` = LuminanceColorSchemeBoundaries(dark: 0.45, light: 0.55)
}

/// A modifier that samples the rendered containing view depending on the average color
@frozen
public struct LuminanceTrackingReaderModifier: ViewModifier {

    var luminance: Binding<Double?>?
    var colorScheme: Binding<ColorScheme?>?
    var boundaries: LuminanceColorSchemeBoundaries
    var isEnabled: Bool

    public init(
        luminance: Binding<Double?>? = nil,
        colorScheme: Binding<ColorScheme?>? = nil,
        boundaries: LuminanceColorSchemeBoundaries = .default,
        isEnabled: Bool = true
    ) {
        self.luminance = luminance
        self.colorScheme = colorScheme
        self.boundaries = boundaries
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isEnabled {
                        LuminanceTrackingReaderAdapter(
                            luminance: luminance,
                            colorScheme: colorScheme,
                            boundaries: boundaries
                        )
                    }
                }
            )
    }
}

private struct LuminanceTrackingReaderAdapter: UIViewRepresentable {
    var luminance: Binding<Double?>?
    var colorScheme: Binding<ColorScheme?>?
    var boundaries: LuminanceColorSchemeBoundaries

    func makeUIView(context: Context) -> LuminanceTrackingReader {
        let uiView = LuminanceTrackingReader()
        return uiView
    }

    func updateUIView(_ uiView: LuminanceTrackingReader, context: Context) {
        uiView.luminance = luminance
        uiView.colorScheme = colorScheme
        uiView.boundaries = boundaries
    }
}

open class LuminanceTrackingReader: UIView {

    public var luminance: Binding<Double?>?
    public var colorScheme: Binding<ColorScheme?>?
    public var boundaries: LuminanceColorSchemeBoundaries = .default {
        didSet {
            guard oldValue != boundaries else { return }
            guard
                let backdropView,
                // setTransitionBoundaries:
                let aSelector = NSSelectorFromBase64EncodedString("c2V0VHJhbnNpdGlvbkJvdW5kYXJpZXM6"),
                backdropView.responds(to: aSelector),
                let method = class_getInstanceMethod(object_getClass(backdropView), aSelector)
            else {
                return
            }
            let imp = method_getImplementation(method)
            typealias Fn = @convention(c) (
                AnyObject, Selector, CGPoint
            ) -> Void

            let fn = unsafeBitCast(imp, to: Fn.self)
            fn(backdropView, aSelector, CGPoint(x: boundaries.dark, y: boundaries.light))
        }
    }

    private var backdropView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false

        backdropView = {
            guard
                // _UILumaTrackingBackdropView
                let aClassName = NSStringFromBase64EncodedString("X1VJTHVtYVRyYWNraW5nQmFja2Ryb3BWaWV3"),
                let aClass = NSClassFromString(aClassName) as? NSObject.Type,
                // initWithTransitionBoundaries:delegate:frame:
                let initSelectorName = NSStringFromBase64EncodedString("aW5pdFdpdGhUcmFuc2l0aW9uQm91bmRhcmllczpkZWxlZ2F0ZTpmcmFtZTo=")
            else {
                return nil
            }
            let instance = aClass.perform(NSSelectorFromString("alloc")).takeUnretainedValue()
            let initSelector = NSSelectorFromString(initSelectorName)
            guard let method = class_getInstanceMethod(aClass, initSelector) else {
                return nil
            }
            let imp = method_getImplementation(method)
            typealias Fn = @convention(c) (
                AnyObject, Selector, CGPoint, AnyObject?, CGRect
            ) -> Unmanaged<UIView>?

            let fn = unsafeBitCast(imp, to: Fn.self)
            let view = fn(instance, initSelector, CGPoint(x: boundaries.dark, y: boundaries.light), self, .zero)
            return view?.takeRetainedValue()
        }()
        if let backdropView {
            backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(backdropView)
            // groupDelegate
            if let keyPath = NSStringFromBase64EncodedString("Z3JvdXBEZWxlZ2F0ZQ==") {
                backdropView.setValue(self, forKey: keyPath)
            }

            // CABackdropLayer
            if let aClassName = NSStringFromBase64EncodedString("Q0FCYWNrZHJvcExheWVy"),
                let aClass = NSClassFromString(aClassName),
                backdropView.layer.isKind(of: aClass)
            {
                // setTracksLuma:
                if let aSelector = NSStringFromBase64EncodedString("c2V0VHJhY2tzTHVtYTo="),
                    backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
                    // tracksLuma
                    let keyPath = NSStringFromBase64EncodedString("dHJhY2tzTHVtYQ==")
                {
                    backdropView.layer.setValue(true, forKey: keyPath)
                }
                // setTracksLumaWhileHidden:
                if let aSelector = NSStringFromBase64EncodedString("c2V0VHJhY2tzTHVtYVdoaWxlSGlkZGVuOg=="),
                    backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
                    // tracksLumaWhileHidden
                    let keyPath = NSStringFromBase64EncodedString("dHJhY2tzTHVtYVdoaWxlSGlkZGVu")
                {
                    backdropView.layer.setValue(true, forKey: keyPath)
                }
                // setAllowsFilteredLuma:
                if let aSelector = NSStringFromBase64EncodedString("c2V0QWxsb3dzRmlsdGVyZWRMdW1hOg=="),
                    backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
                    // allowsFilteredLuma
                    let keyPath = NSStringFromBase64EncodedString("YWxsb3dzRmlsdGVyZWRMdW1h")
                {
                    backdropView.layer.setValue(true, forKey: keyPath)
                }
                // setLumaUpdateRate:
                if let aSelector = NSStringFromBase64EncodedString("c2V0THVtYVVwZGF0ZVJhdGU6"),
                    backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
                    // lumaUpdateRateRate
                    let keyPath = NSStringFromBase64EncodedString("bHVtYVVwZGF0ZVJhdGVSYXRl")
                {
                    backdropView.layer.setValue(20.0 / 60.0, forKey: keyPath)
                }
            }
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            didUpdateLuminosity(nil)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let backdropView else { return }

        // setBackdropRect:
        if let aSelector = NSStringFromBase64EncodedString("c2V0QmFja2Ryb3BSZWN0Og=="),
            backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
            // backdropRect
            let keyPath = NSStringFromBase64EncodedString("YmFja2Ryb3BSZWN0")
        {
            backdropView.layer.setValue(bounds, forKey: keyPath)
        }
        // setLumaSubrect:
        if let aSelector = NSStringFromBase64EncodedString("c2V0THVtYVN1YnJlY3Q6"),
            backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
            // lumaSubrect
            let keyPath = NSStringFromBase64EncodedString("bHVtYVN1YnJlY3Q=")
        {
            backdropView.layer.setValue(bounds, forKey: keyPath)
        }
    }

    @objc
    func backgroundLumaView(_ view: UIView, didTransitionToLevel level: UInt64) {
        switch level {
        case 1:
            didUpdateColorScheme(.light)
        case 2:
            didUpdateColorScheme(.dark)
        default:
            didUpdateColorScheme(nil)
        }
    }

    @objc
    func backgroundLumaView(_ view: UIView, didChangeLuma luminosity: Double) {
        didUpdateLuminosity(luminosity)
    }

    private func didUpdateLuminosity(_ luminosity: Double?) {
        // backgroundLuminanceLevel
        if let aSelector = NSStringFromBase64EncodedString("YmFja2dyb3VuZEx1bWluYW5jZUxldmVs"),
            backdropView?.responds(to: NSSelectorFromString(aSelector)) == true,
            let level = backdropView?.value(forKey: aSelector) as? UInt64
        {
            didUpdateLuminosity(luminosity, level: level)
        }
    }

    private func didUpdateLuminosity(_ newValue: Double?, level: UInt64) {
        if luminance?.wrappedValue != newValue {
            luminance?.wrappedValue = newValue
        }
        if let newValue {
            switch level {
            case 1:
                if newValue > boundaries.light {
                    didUpdateColorScheme(.light)
                }
            case 2:
                if newValue < boundaries.dark {
                    didUpdateColorScheme(.dark)
                }
            default:
                didUpdateColorScheme(nil)
            }
        } else {
            didUpdateColorScheme(nil)
        }
    }

    private func didUpdateColorScheme(_ newValue: ColorScheme?) {
        guard colorScheme?.wrappedValue != newValue else { return }
        colorScheme?.wrappedValue = newValue
    }
}

#endif
