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
@available(iOS 14.0, *)
public struct AdaptiveColorSchemeModifier: ViewModifier {

    var preferredColorScheme: ColorScheme?
    var options: LuminanceTrackingOptions
    var isEnabled: Bool

    @State var adaptiveColorScheme: ColorScheme?
    @Environment(\.colorScheme) var colorScheme

    public init(
        preferredColorScheme: ColorScheme? = nil,
        options: LuminanceTrackingOptions = .default,
        isEnabled: Bool = true
    ) {
        self.options = options
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
                    options: options,
                    isEnabled: isEnabled && preferredColorScheme != colorScheme
                )
            )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that samples the rendered containing view and modifies the color scheme
    /// to be light/dark depending on the average color
    ///
    /// Only adapts if the `preferredColorScheme` is not the current color scheme
    ///
    public func adaptiveColorScheme(
        preferredColorScheme: ColorScheme? = nil,
        options: LuminanceTrackingOptions = .default,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            AdaptiveColorSchemeModifier(
                preferredColorScheme: preferredColorScheme,
                options: options,
                isEnabled: isEnabled
            )
        )
    }
}

@frozen
@available(iOS 14.0, *)
public struct LuminanceTrackingOptions: Equatable, Sendable {

    public struct ColorSchemeThresholds: Equatable, Sendable {
        public var dark: Double
        public var light: Double

        public init(dark: Double = 0.45, light: Double = 0.55) {
            self.dark = dark
            self.light = light
        }

        public static let `default` = ColorSchemeThresholds()
    }

    public var colorSchemeThresholds: ColorSchemeThresholds
    public var trackingRegionInsets: EdgeInsets

    public init(
        colorSchemeThresholds: ColorSchemeThresholds = .default,
        trackingRegionInsets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    ) {
        self.colorSchemeThresholds = colorSchemeThresholds
        self.trackingRegionInsets = trackingRegionInsets
    }

    public static let `default` = LuminanceTrackingOptions()
}

/// A modifier that samples the rendered containing view depending on the average color
@frozen
@available(iOS 14.0, *)
public struct LuminanceTrackingReaderModifier: ViewModifier {

    var luminance: Binding<Double?>?
    var colorScheme: Binding<ColorScheme?>?
    var options: LuminanceTrackingOptions
    var isEnabled: Bool

    public init(
        luminance: Binding<Double?>? = nil,
        colorScheme: Binding<ColorScheme?>? = nil,
        options: LuminanceTrackingOptions = .default,
        isEnabled: Bool = true
    ) {
        self.luminance = luminance
        self.colorScheme = colorScheme
        self.options = options
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
                            options: options
                        )
                    }
                }
            )
    }
}

@available(iOS 14.0, *)
private struct LuminanceTrackingReaderAdapter: UIViewRepresentable {
    var luminance: Binding<Double?>?
    var colorScheme: Binding<ColorScheme?>?
    var options: LuminanceTrackingOptions

    func makeUIView(context: Context) -> LuminanceTrackingReader {
        let uiView = LuminanceTrackingReader()
        return uiView
    }

    func updateUIView(_ uiView: LuminanceTrackingReader, context: Context) {
        uiView.luminance = luminance
        uiView.colorScheme = colorScheme
        uiView.colorSchemeThresholds = options.colorSchemeThresholds
        uiView.trackingRegionInsets = options.trackingRegionInsets.toUIEdgeInsets(layoutDirection: context.environment.layoutDirection)
    }
}

@available(iOS 14.0, *)
open class LuminanceTrackingReader: UIView {

    public var luminance: Binding<Double?>?
    public var colorScheme: Binding<ColorScheme?>?
    public var colorSchemeThresholds: LuminanceTrackingOptions.ColorSchemeThresholds = .default {
        didSet {
            guard oldValue != colorSchemeThresholds else { return }
            didUpdateLevelBoundaries()
        }
    }
    public var trackingRegionInsets: UIEdgeInsets = .zero {
        didSet {
            guard oldValue != trackingRegionInsets else { return }
            setNeedsLayout()
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
            let view = fn(instance, initSelector, CGPoint(x: colorSchemeThresholds.dark, y: colorSchemeThresholds.light), self, .zero)
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

        let trackingRegion = bounds.inset(by: trackingRegionInsets)
        // setBackdropRect:
        if let aSelector = NSStringFromBase64EncodedString("c2V0QmFja2Ryb3BSZWN0Og=="),
            backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
            // backdropRect
            let keyPath = NSStringFromBase64EncodedString("YmFja2Ryb3BSZWN0")
        {
            backdropView.layer.setValue(trackingRegion, forKey: keyPath)
        }
        // setLumaSubrect:
        if let aSelector = NSStringFromBase64EncodedString("c2V0THVtYVN1YnJlY3Q6"),
            backdropView.layer.responds(to: NSSelectorFromString(aSelector)),
            // lumaSubrect
            let keyPath = NSStringFromBase64EncodedString("bHVtYVN1YnJlY3Q=")
        {
            backdropView.layer.setValue(trackingRegion, forKey: keyPath)
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
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
                if newValue > colorSchemeThresholds.light {
                    didUpdateColorScheme(.light)
                }
            case 2:
                if newValue < colorSchemeThresholds.dark {
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

    private func didUpdateLevelBoundaries() {
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
        fn(backdropView, aSelector, CGPoint(x: colorSchemeThresholds.dark, y: colorSchemeThresholds.light))
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct LuminanceTrackingReaderModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(3) {
                        Color.black
                            .frame(height: 100)
                        Color.yellow
                            .frame(height: 100)
                        Color.red
                            .frame(height: 100)
                        Color.white
                            .frame(height: 100)
                        Color.green
                            .frame(height: 100)
                        Color.purple
                            .frame(height: 100)
                        Color.orange
                            .frame(height: 100)
                        Color.cyan
                            .frame(height: 100)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                NavigationBar()
            }
        }

        struct NavigationBar: View {

            @State var luminance: Double?
            @State var adaptiveColorScheme: ColorScheme?
            @State var isInset = false

            var body: some View {
                Button {
                    isInset.toggle()
                } label: {
                    Text(luminance ?? 1, format: .number.precision(.fractionLength(3)))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    LinearGradient(
                        colors: [
                            Color.primary,
                            Color.primary.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .transformEnvironment(\.colorScheme) { colorScheme in
                        switch colorScheme {
                        case .light:
                            colorScheme = .dark
                        case .dark:
                            colorScheme = .light
                        default:
                            break
                        }
                    }
                }
                .environment(\.colorScheme, adaptiveColorScheme)
                .animation(.default, value: adaptiveColorScheme)
                .modifier(
                    LuminanceTrackingReaderModifier(
                        luminance: $luminance,
                        colorScheme: $adaptiveColorScheme,
                        options: LuminanceTrackingOptions(
                            colorSchemeThresholds: .default,
                            trackingRegionInsets: EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: isInset ? -100 : 0,
                                trailing: 0
                            )
                        )
                    )
                )
            }
        }
    }
}

#endif
