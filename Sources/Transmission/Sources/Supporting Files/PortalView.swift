//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import UIKit

open class PortalView: UIView {

    let portalView: UIView

    public var sourceView: UIView? {
        get {
            // sourceView
            let aSelector = NSSelectorFromBase64EncodedString("c291cmNlVmlldw==")
            guard portalView.responds(to: aSelector) else { return nil }
            return portalView.perform(aSelector)?.takeUnretainedValue() as? UIView
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("c291cmNlVmlldw=="),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public var hidesSourceView: Bool {
        get {
            // hidesSourceView
            guard
                let aSelector = NSStringFromBase64EncodedString("aGlkZXNTb3VyY2VWaWV3"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("aGlkZXNTb3VyY2VWaWV3"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public var matchesAlpha: Bool {
        get {
            // matchesAlpha
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc0FscGhh"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc0FscGhh"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public var matchesTransform: Bool {
        get {
            // matchesTransform
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc1RyYW5zZm9ybQ=="),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc1RyYW5zZm9ybQ=="),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public var matchesPosition: Bool {
        get {
            // matchesPosition
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc1Bvc2l0aW9u"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("bWF0Y2hlc1Bvc2l0aW9u"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public var allowsHitTesting: Bool {
        get {
            // allowsHitTesting
            guard
                let aSelector = NSStringFromBase64EncodedString("YWxsb3dzSGl0VGVzdGluZw=="),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            // setAllowsHitTesting:
            let aSelector = NSSelectorFromBase64EncodedString("c2V0QWxsb3dzSGl0VGVzdGluZzo=")
            guard portalView.responds(to: aSelector) else { return }
            portalView.perform(aSelector, with: newValue)
        }
    }

    public var forwardsClientHitTestingToSourceView: Bool {
        get {
            // forwardsClientHitTestingToSourceView
            guard
                let aSelector = NSStringFromBase64EncodedString("Zm9yd2FyZHNDbGllbnRIaXRUZXN0aW5nVG9Tb3VyY2VWaWV3"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return false
            }
            return portalView.value(forKey: aSelector) as? Bool ?? false
        }
        set {
            guard
                let aSelector = NSStringFromBase64EncodedString("Zm9yd2FyZHNDbGllbnRIaXRUZXN0aW5nVG9Tb3VyY2VWaWV3"),
                portalView.responds(to: NSSelectorFromString(aSelector))
            else {
                return
            }
            portalView.setValue(newValue, forKey: aSelector)
        }
    }

    public init?(sourceView: UIView) {
        let allocSelector = NSSelectorFromString("alloc")
        // initWithSourceView:
        let initSelector = NSSelectorFromBase64EncodedString("aW5pdFdpdGhTb3VyY2VWaWV3Og==")
        // _UIPortalView
        let portalViewClass = NSClassFromBase64EncodedString("X1VJUG9ydGFsVmlldw==")
        guard
            let portalViewClass = portalViewClass as? UIView.Type
        else {
            return nil
        }
        let instance = portalViewClass.perform(allocSelector).takeUnretainedValue()
        guard
            instance.responds(to: initSelector),
            let portalView = instance.perform(initSelector, with: sourceView).takeUnretainedValue() as? UIView
        else {
            return nil
        }
        self.portalView = portalView
        super.init(frame: sourceView.frame)
        portalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(portalView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Previews

struct PortalView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.alpha = 0.5
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                    }
                    return contentView
                }
                .frame(width: 100, height: 100)

                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.alpha = 0.5
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.matchesAlpha = true
                        portalView.hidesSourceView = true
                    }
                    return contentView
                }
                .frame(width: 100, height: 100)

                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                    }
                    contentView.alpha = 0.5
                    return contentView
                }
                .frame(width: 100, height: 100)
            }

            HStack {
                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                    }
                    return contentView
                }
                .frame(width: 100, height: 100)


                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.alpha = 0.5
                    }
                    return contentView
                }
                .frame(width: 100, height: 100)

                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                        portalView.matchesTransform = true
                    }
                    contentView.backgroundColor = .yellow
                    return contentView
                }
                .frame(width: 100, height: 100)
            }

            HStack {
                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.alpha = 0.5
                    view.layer.cornerRadius = 16
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                        portalView.matchesAlpha = true
                        portalView.matchesPosition = true
                    }
                    contentView.backgroundColor = .yellow
                    return contentView
                }
                .frame(width: 100, height: 200)

                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.alpha = 0.5
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    view.layer.cornerRadius = 16
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                        portalView.matchesAlpha = true
                        portalView.matchesTransform = true
                    }
                    contentView.backgroundColor = .yellow
                    contentView.transform = CGAffineTransform(scaleX: 1.25, y: 2)
                    return contentView
                }
                .frame(width: 100, height: 100)

                ViewRepresentableAdapter {
                    let view = UIView()
                    view.backgroundColor = .red
                    view.alpha = 0.5
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    view.layer.cornerRadius = 16
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                        portalView.matchesAlpha = true
                    }
                    contentView.backgroundColor = .yellow
                    contentView.transform = CGAffineTransform(scaleX: 1.25, y: 2)
                    return contentView
                }
                .frame(width: 100, height: 100)
            }

            if #available(iOS 14.0, *) {
                ViewRepresentableAdapter {
                    let view = HostingView(
                        content: Color.red.onTapGesture {
                            print("Tapped")
                        }
                    )
                    let contentView = PortalViewContentView(
                        contentView: view
                    ) { portalView in
                        portalView.hidesSourceView = true
                        portalView.forwardsClientHitTestingToSourceView = true
                    }
                    return contentView
                }
                .frame(width: 100, height: 100)
            }

            ViewRepresentableAdapter {
                let containerView = UIView()
                let view = UIView()
                view.backgroundColor = .red
                containerView.addSubview(view)
                view.frame = .init(
                    x: 0,
                    y: 0,
                    width: 100,
                    height: 100
                )
                view.alpha = 0.5
                view.transform = .init(scaleX: 0.8, y: 0.8)
                if let portalView = PortalView(sourceView: view) {
                    containerView.addSubview(portalView)
                    portalView.frame = .init(
                        x: 110,
                        y: 0,
                        width: 100,
                        height: 100
                    )
                }
                return containerView
            }
            .frame(width: 220, height: 100)
        }
    }

    class PortalViewContentView: UIView {
        var contentView: UIView
        var portalView: PortalView?
        var insets: UIEdgeInsets = .zero

        override var frame: CGRect {
            get { super.frame }
            set {
                setFramePreservingTransform(newValue)
            }
        }

        init(contentView: UIView, configure: (PortalView) -> Void) {
            self.contentView = contentView
            super.init(frame: .zero)
            addSubview(contentView)

            if let portalView = PortalView(sourceView: contentView) {
                configure(portalView)
                addSubview(portalView)
                self.portalView = portalView
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.setFramePreservingTransform(.init(origin: .zero, size: CGSize(width: 100, height: 100)))
            portalView?.setFramePreservingTransform(bounds)
        }
    }
}

#endif
