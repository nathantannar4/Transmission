//
// Copyright (c) Nathan Tannar
//

import UIKit
import SwiftUI

@available(iOS 14.0, *)
open class PresentedContainerView: UIView {

    open var presentedView: UIView? {
        didSet {
            guard presentedView != oldValue else { return }
            oldValue?.removeFromSuperview()
            (layer as? PresentedContainerViewLayer)?.presentedViewLayer = presentedView?.layer
            guard let presentedView else { return }
            presentedView.layer.masksToBounds = true
            presentedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if let effectView {
                effectView.contentView.addSubview(presentedView)
            } else {
                addSubview(presentedView)
            }
        }
    }

    open var preferredBackground: BackgroundOptions? {
        didSet {
            guard preferredBackground != oldValue else { return }
            colorView.backgroundColor = preferredBackground?.color?.toUIColor()
            if let effect = preferredBackground?.effect?.toVisualEffect() {
                if colorView.backgroundColor == nil {
                    colorView.backgroundColor = .clear
                }
                #if canImport(FoundationModels) // Xcode 26
                if #available(iOS 26.0, *), let glassEffect = effect as? UIGlassEffect {
                    glassEffect.isInteractive = true
                    if let effectView {
                        effectView.effect = effect
                    } else {
                        let effectView = UIVisualEffectView(effect: effect)
                        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        addSubview(effectView)
                        if let presentedView {
                            effectView.contentView.addSubview(presentedView)
                        }
                        self.effectView = effectView
                    }
                    return
                }
                #endif
                if let effectView {
                    effectView.effect = effect
                } else {
                    let effectView = UIVisualEffectView(effect: effect)
                    effectView.layer.masksToBounds = true
                    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    addSubview(effectView)
                    if let presentedView {
                        effectView.contentView.addSubview(presentedView)
                    }
                    self.effectView = effectView
                }
            } else if let effectView {
                effectView.removeFromSuperview()
                self.effectView = nil
                if let presentedView, presentedView.superview != self {
                    addSubview(presentedView)
                }
            }
        }
    }

    private var effectView: UIVisualEffectView? {
        didSet {
            (layer as? PresentedContainerViewLayer)?.effectViewLayer = effectView?.layer
        }
    }

    private var colorView = UIView()

    open override class var layerClass: AnyClass {
        PresentedContainerViewLayer.self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        colorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(colorView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    open func updateCornerConfiguration(_ newValue: UICornerConfiguration) {
        colorView.cornerConfiguration = newValue
        presentedView?.cornerConfiguration = newValue
        effectView?.cornerConfiguration = newValue
    }
    #endif

    open func updateCornerRadius(_ newValue: CornerRadiusOptions.RoundedRectangle) {
        newValue.apply(to: colorView.layer)
        if let presentedView {
            newValue.apply(to: presentedView.layer)
        }
        if let effectView {
            newValue.apply(to: effectView.layer)
        }
    }
}

private class PresentedContainerViewLayer: CALayer {

    weak var presentedViewLayer: CALayer?
    weak var effectViewLayer: CALayer?

    override var cornerRadius: CGFloat {
        didSet {
            presentedViewLayer?.cornerRadius = cornerRadius
            effectViewLayer?.cornerRadius = cornerRadius
        }
    }

    override var mask: CALayer? {
        get { return nil }
        set {
            (effectViewLayer ?? presentedViewLayer)?.mask = newValue
        }
    }

    override var maskedCorners: CACornerMask {
        didSet {
            presentedViewLayer?.maskedCorners = maskedCorners
            effectViewLayer?.maskedCorners = maskedCorners
        }
    }

    override var cornerCurve: CALayerCornerCurve {
        didSet {
            presentedViewLayer?.cornerCurve = cornerCurve
            effectViewLayer?.cornerCurve = cornerCurve
        }
    }
}

@available(iOS 14.0, *)
struct PresentedContainerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ViewRepresentableAdapter {
                let presentedView = UIView()
                presentedView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                let uiView = PresentedContainerView()
                uiView.presentedView = presentedView
                uiView.backgroundColor = .white
                uiView.layer.shadowOpacity = 0.3
                uiView.layer.shadowRadius = 12
                uiView.layer.shadowColor = UIColor.black.cgColor
                uiView.layer.cornerRadius = 24
                return uiView
            }
            .frame(width: 100, height: 100)

            ViewRepresentableAdapter {
                let presentedView = UIView()
                presentedView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                let uiView = PresentedContainerView()
                uiView.presentedView = presentedView
                uiView.backgroundColor = .white
                uiView.layer.shadowOpacity = 0.3
                uiView.layer.shadowRadius = 3
                uiView.layer.shadowColor = UIColor.black.cgColor
                uiView.layer.cornerRadius = 24
                uiView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                return uiView
            }
            .frame(width: 100, height: 100)

            ViewRepresentableAdapter {
                let presentedView = UIView()
                presentedView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                let uiView = PresentedContainerView()
                uiView.presentedView = presentedView
                uiView.backgroundColor = .white
                uiView.layer.shadowOpacity = 0.3
                uiView.layer.shadowRadius = 3
                uiView.layer.shadowColor = UIColor.black.cgColor
                uiView.layer.cornerRadius = 24
                let maskLayer = CAShapeLayer()
                maskLayer.frame = .init(origin: .zero, size: CGSize(width: 100, height: 100))
                maskLayer.path = UIBezierPath(roundedRect: maskLayer.bounds, cornerRadius: 12).cgPath
                uiView.layer.mask = maskLayer
                return uiView
            }
            .frame(width: 100, height: 100)
        }
    }
}
