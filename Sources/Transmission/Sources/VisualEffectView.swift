//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import UIKit
import SwiftUI
import Engine

@available(iOS 14.0, *)
@MainActor @preconcurrency
public protocol VisualEffectRepresentable: Equatable {

    associatedtype UIVisualEffectType: UIVisualEffect

    @MainActor @preconcurrency func makeUIVisualEffect(in environment: EnvironmentValues) -> UIVisualEffectType
}

@frozen
@available(iOS 14.0, *)
public struct VisualEffectContext {
    public var environment: EnvironmentValues
    public var transaction: Transaction
}

@frozen
public struct BlurEffect: Equatable {

    @frozen
    public enum Style: Equatable, CaseIterable {
        // A mostly translucent material.
        case ultraThin
        // A material that’s more translucent than opaque.
        case thin
        // A material that’s somewhat translucent.
        case regular
        // A material that’s more opaque than translucent.
        case thick
        // A mostly opaque material.
        case ultraThick
        // A material matching the style of system toolbars.
        case bar
        // A non-material blur thats mostly translucent
        case `default`

        func toUIKit() -> UIBlurEffect.Style {
            switch self {
            case .ultraThin:
                return .systemUltraThinMaterial
            case .thin:
                return .systemThinMaterial
            case .regular:
                return .systemMaterial
            case .thick, .ultraThick:
                return .systemThickMaterial
            case .bar:
                return .systemChromeMaterial
            case .default:
                return .regular
            }
        }

        @available(iOS 15.0, *)
        func toSwiftUI() -> Material {
            switch self {
            case .ultraThin:
                return .ultraThin
            case .thin:
                return .thin
            case .regular:
                return .regular
            case .thick:
                return .thick
            case .ultraThick:
                return .ultraThick
            case .bar:
                return .bar
            case .default:
                return .regular
            }
        }
    }

    public var style: Style

    @inlinable
    public init(
        style: Style
    ) {
        self.style = style
    }
}

@available(iOS 14.0, *)
extension BlurEffect: VisualEffectRepresentable {

    public func makeUIVisualEffect(in environment: EnvironmentValues) -> UIBlurEffect {
        let uiVisualEffect = UIBlurEffect(
            style: style.toUIKit()
        )
        return uiVisualEffect
    }
}

@available(iOS 14.0, *)
extension VisualEffectRepresentable where Self == BlurEffect {

    @inlinable
    public static func blur(style: BlurEffect.Style) -> BlurEffect {
        BlurEffect(style: style)
    }
}

@frozen
public struct VibrancyEffect: Equatable {

    @frozen
    public enum Style: Equatable, CaseIterable {
        case label
        case secondaryLabel
        case tertiaryLabel
        case quaternaryLabel
        case fill
        case secondaryFill
        case tertiaryFill
        case separator

        func toUIKit() -> UIVibrancyEffectStyle {
            switch self {
            case .label:
                return .label
            case .secondaryLabel:
                return .secondaryLabel
            case .tertiaryLabel:
                return .tertiaryLabel
            case .quaternaryLabel:
                return .quaternaryLabel
            case .fill:
                return .fill
            case .secondaryFill:
                return .secondaryFill
            case .tertiaryFill:
                return .tertiaryFill
            case .separator:
                return .separator
            }
        }
    }

    public var blur: BlurEffect
    public var style: Style

    @inlinable
    public init(
        blur: BlurEffect,
        style: Style
    ) {
        self.blur = blur
        self.style = style
    }
}

@available(iOS 14.0, *)
extension VibrancyEffect: VisualEffectRepresentable {

    public func makeUIVisualEffect(in environment: EnvironmentValues) -> UIVibrancyEffect {
        let uiVisualEffect = UIVibrancyEffect(
            blurEffect: blur.makeUIVisualEffect(in: environment),
            style: style.toUIKit()
        )
        return uiVisualEffect
    }
}

@available(iOS 14.0, *)
extension VisualEffectRepresentable where Self == VibrancyEffect {

    @inlinable
    public static func vibrancy(blur: BlurEffect, style: VibrancyEffect.Style) -> VibrancyEffect {
        VibrancyEffect(blur: blur, style: style)
    }
}

@frozen
public struct GlassEffect: Equatable {

    @frozen
    public enum Style: Equatable, CaseIterable {
        /// Standard glass effect style.
        case regular

        /// Clear glass effect style.
        case clear

        #if canImport(FoundationModels) // Xcode 26
        @available(iOS 26.0, *)
        func toUIKit() -> UIGlassEffect.Style {
            switch self {
            case .regular:
                return .regular
            case .clear:
                return .clear
            }
        }

        @available(iOS 26.0, *)
        func toSwiftUI() -> Glass {
            switch self {
            case .regular:
                return .regular
            case .clear:
                return .clear
            }
        }
        #endif
    }

    public var style: Style
    public var isInteractive: Bool
    public var tintColor: Color?
    public var prefersShadowHidden: Bool = false

    @inlinable
    public init(
        style: Style,
        isInteractive: Bool = false,
        tintColor: Color? = nil,
        prefersShadowHidden: Bool = false
    ) {
        self.style = style
        self.isInteractive = isInteractive
        self.tintColor = tintColor
        self.prefersShadowHidden = prefersShadowHidden
    }
}

#if canImport(FoundationModels) // Xcode 26
@available(iOS 26.0, *)
extension GlassEffect: VisualEffectRepresentable {

    public func makeUIVisualEffect(in environment: EnvironmentValues) -> UIGlassEffect {
        let uiVisualEffect = UIGlassEffect(
            style: style.toUIKit()
        )
        let tintColor = tintColor?.toUIColor(in: environment)
        uiVisualEffect.isInteractive = isInteractive
        uiVisualEffect.tintColor = tintColor

        // _explicitGlass
        if #unavailable(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0),
            prefersShadowHidden,
            let aSelector = NSStringFromBase64EncodedString("X2V4cGxpY2l0R2xhc3M="),
            let iVar = class_getInstanceVariable(UIGlassEffect.self, aSelector)
        {
            var glass = object_getIvar(uiVisualEffect, iVar) as? NSObject
            // glass
            if glass == nil,
                let aSelector = NSStringFromBase64EncodedString("Z2xhc3M="),
                uiVisualEffect.responds(to: NSSelectorFromString(aSelector))
            {
                glass = uiVisualEffect.value(forKey: aSelector) as? NSObject
            }
            if let glass {
                // flexible
                if let aSelector = NSStringFromBase64EncodedString("ZmxleGlibGU="),
                    glass.responds(to: NSSelectorFromString(aSelector))
                {
                    glass.setValue(isInteractive, forKey: aSelector)
                }
                // excludingShadow
                if let aSelector = NSStringFromBase64EncodedString("ZXhjbHVkaW5nU2hhZG93"),
                    glass.responds(to: NSSelectorFromString(aSelector))
                {
                    glass.setValue(prefersShadowHidden, forKey: aSelector)
                }
                // tintColor
                if let aSelector = NSStringFromBase64EncodedString("dGludENvbG9y"),
                    glass.responds(to: NSSelectorFromString(aSelector))
                {
                    glass.setValue(tintColor, forKey: aSelector)
                }
                object_setIvar(uiVisualEffect, iVar, glass)
            }
        }
        return uiVisualEffect
    }
}

@available(iOS 14.0, *)
extension VisualEffectRepresentable where Self == GlassEffect {

    @inlinable
    public static func glass(
        style: GlassEffect.Style,
        isInteractive: Bool = false,
        tintColor: Color? = nil
    ) -> GlassEffect {
        GlassEffect(style: style, isInteractive: isInteractive, tintColor: tintColor)
    }
}
#endif

@frozen
public struct GlassContainerEffect: Equatable {

    public var spacing: CGFloat

    @inlinable
    public init(
        spacing: CGFloat = 0
    ) {
        self.spacing = spacing
    }
}

#if canImport(FoundationModels) // Xcode 26
@available(iOS 26.0, *)
extension GlassContainerEffect: VisualEffectRepresentable {

    public func makeUIVisualEffect(in environment: EnvironmentValues) -> UIGlassContainerEffect {
        let uiVisualEffect = UIGlassContainerEffect()
        uiVisualEffect.spacing = spacing
        return uiVisualEffect
    }
}

@available(iOS 14.0, *)
extension VisualEffectRepresentable where Self == GlassContainerEffect {

    @inlinable
    public static func glassContainer(
        spacing: CGFloat
    ) -> GlassContainerEffect {
        GlassContainerEffect(spacing: spacing)
    }
}
#endif

@frozen
@available(iOS 14.0, *)
public struct AnyVisualEffect: @preconcurrency VisualEffectRepresentable {

    private var storage: AnyVisualEffectStorageBase

    public init<Effect: VisualEffectRepresentable>(_ effect: Effect) {
        self.storage = AnyVisualEffectStorage(effect)
    }

    public func makeUIVisualEffect(in environment: EnvironmentValues) -> UIVisualEffect {
        storage.makeUIVisualEffect(in: environment)
    }

    public static func == (lhs: AnyVisualEffect, rhs: AnyVisualEffect) -> Bool {
        return lhs.storage.isEqual(to: rhs.storage)
    }

    @usableFromInline
    @MainActor @preconcurrency
    class AnyVisualEffectStorageBase {
        func makeUIVisualEffect(in environment: EnvironmentValues) -> UIVisualEffect {
            fatalError("base")
        }

        func isEqual(to other: AnyVisualEffectStorageBase) -> Bool {
            fatalError("base")
        }
    }

    @usableFromInline
    @MainActor @preconcurrency
    class AnyVisualEffectStorage<Effect: VisualEffectRepresentable>: AnyVisualEffectStorageBase {

        var effect: Effect

        @usableFromInline
        init(_ effect: Effect) {
            self.effect = effect
        }

        override func makeUIVisualEffect(in environment: EnvironmentValues) -> UIVisualEffect {
            effect.makeUIVisualEffect(in: environment)
        }

        override func isEqual(to other: AnyVisualEffect.AnyVisualEffectStorageBase) -> Bool {
            guard let other = other as? AnyVisualEffectStorage<Effect> else { return false }
            return effect == other.effect
        }
    }
}

@available(iOS 14.0, *)
public struct VisualEffectView<
    Effect: VisualEffectRepresentable,
    Content: View
>: View {

    public var effect: Effect
    public var isEnabled: Bool
    public var cornerRadius: CornerRadiusOptions?
    public var backgroundColor: Color?
    public var content: Content

    public init(
        effect: Effect,
        isEnabled: Bool = true,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.effect = effect
        self.isEnabled = isEnabled
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        VisualEffectViewAdapter(
            effect: isEnabled ? effect : nil,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            content: content
        )
    }
}

extension View {

    @available(iOS 14.0, *)
    public func visualEffectBackground<Effect: VisualEffectRepresentable>(
        effect: Effect,
        isEnabled: Bool = true,
        cornerRadius: CornerRadiusOptions? = nil
    ) -> some View {
        VisualEffectView(
            effect: effect,
            isEnabled: isEnabled,
            cornerRadius: cornerRadius
        ) {
            self
        }
    }
}

@available(iOS 14.0, *)
private struct VisualEffectViewAdapter<
    Effect: VisualEffectRepresentable,
    Content: View
>: UIViewRepresentable {

    var effect: Effect?
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var content: Content

    typealias UIViewType = VisualEffectHostingView<Effect, Content>

    func makeUIView(
        context: Context
    ) -> UIViewType {
        let uiView = UIViewType(
            effect: effect,
            content: content,
            context: context
        )
        return uiView
    }

    func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        uiView.update(
            effect: effect,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor?.toUIColor(in: context.environment),
            content: content,
            context: context
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIViewType,
        context: Context
    ) -> CGSize? {
        return uiView.sizeThatFits(ProposedSize(proposal))
    }

    func _overrideSizeThatFits(
        _ size: inout CGSize,
        in proposedSize: _ProposedSize,
        uiView: UIViewType
    ) {
        size = uiView.sizeThatFits(ProposedSize(proposedSize)) ?? size
    }
}

@available(iOS 14.0, *)
private class VisualEffectHostingView<
    Effect: VisualEffectRepresentable,
    Content: View
>: UIVisualEffectView {

    private var visualEffect: Effect?

    private var cornerRadius: CornerRadiusOptions? {
        didSet {
            guard cornerRadius != oldValue else { return }
            cornerRadius?.apply(to: self, masksToBounds: visualEffect != nil || backgroundColor != nil)
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            guard backgroundColor != oldValue else { return }
            cornerRadius?.apply(to: self, masksToBounds: visualEffect != nil || backgroundColor != nil)
        }
    }

    private let hostingView: TransitionSourceView<Content>

    override var intrinsicContentSize: CGSize {
        hostingView.intrinsicContentSize
    }

    init(
        effect: Effect?,
        content: Content,
        context: VisualEffectViewAdapter<Effect, Content>.Context
    ) {
        hostingView = TransitionSourceView(
            content: content
        )
        visualEffect = effect
        let effect = effect?.makeUIVisualEffect(in: context.environment)
        super.init(effect: effect)
        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(hostingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        effect: Effect?,
        cornerRadius: CornerRadiusOptions?,
        backgroundColor: UIColor?,
        content: Content,
        context: VisualEffectViewAdapter<Effect, Content>.Context
    ) {
        hostingView.update(
            content: content,
            transaction: context.transaction,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor
        )

        if visualEffect != effect {
            visualEffect = effect
            let effect = effect?.makeUIVisualEffect(in: context.environment)
            if context.transaction.isAnimated {
                UIView.animate(with: context.transaction.animation) {
                    self.effect = effect
                    self.cornerRadius = cornerRadius
                }
            } else {
                self.effect = nil
                self.effect = effect
                self.cornerRadius = cornerRadius
            }

            let frame = frame
            self.frame = .zero
            self.frame = frame
        } else {
            UIView.animate(with: context.transaction.animation) {
                self.cornerRadius = cornerRadius
            }
        }

        layoutIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedSize) -> CGSize? {
        return hostingView.sizeThatFits(proposal)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return hostingView.sizeThatFits(size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 26.0) {
            cornerRadius?.apply(to: self, masksToBounds: visualEffect != nil || backgroundColor != nil)
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct VisualEffectView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var cornerRadius: CGFloat = 20
        @State var backgroundColor: Color?
        @State var isSubtitleHidden = false

        @State var glassEffect = GlassEffect(style: .regular, isInteractive: true)
        @State var blurEffect = BlurEffect(style: .regular)
        @State var vibrancyEffectStyle: VibrancyEffect.Style = .secondaryLabel
        @State var prefersGlassEffect = true

        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    let label = VStack {
                        Text("Title")
                            .font(.headline)

                        if !isSubtitleHidden {
                            Text("Lorem ipsum dolor")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal)

                    Toggle(isOn: $isSubtitleHidden.animation()) {
                        Text(verbatim: "isSubtitleHidden")
                    }

                    HStack {
                        Text(verbatim: "cornerRadius")

                        Slider(
                            value: $cornerRadius.animation(),
                            in: 0...30
                        )

                        Button {
                            withAnimation {
                                cornerRadius = 30
                            }
                        } label: {
                            Text("Max")
                        }
                    }

                    HStack {
                        ColorPicker(
                            selection: $backgroundColor[default: .accentColor],
                            supportsOpacity: true
                        ) {
                            Text("backgroundColor")
                        }

                        Button("Reset") {
                            backgroundColor = nil
                        }
                    }

                    #if canImport(FoundationModels) // Xcode 26
                    if #available(iOS 26.0, *) {
                        VStack(alignment: .leading) {
                            Text("Glass")
                                .font(.headline)

                            VStack {
                                HStack {
                                    VisualEffectView(
                                        effect: glassEffect,
                                        cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                        backgroundColor: backgroundColor
                                    ) {
                                        label
                                    }

                                    label
                                        .glassEffect(
                                            glassEffect.style.toSwiftUI().tint(glassEffect.tintColor).interactive(glassEffect.isInteractive),
                                            in: RoundedRectangle(cornerRadius: cornerRadius)
                                        )
                                }

                                HStack {
                                    VisualEffectView(
                                        effect: glassEffect,
                                        cornerRadius: .unevenRounded(
                                            topLeading: cornerRadius,
                                            bottomLeading: 0,
                                            bottomTrailing: cornerRadius,
                                            topTrailing: 0,
                                        ),
                                        backgroundColor: backgroundColor
                                    ) {
                                        label
                                    }

                                    label
                                        .glassEffect(
                                            glassEffect.style.toSwiftUI().tint(glassEffect.tintColor).interactive(glassEffect.isInteractive),
                                            in: UnevenRoundedRectangle(
                                                topLeadingRadius: cornerRadius,
                                                bottomLeadingRadius: 0,
                                                bottomTrailingRadius: cornerRadius,
                                                topTrailingRadius: 0
                                            )
                                        )
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .animation(.default, value: glassEffect)

                            Text("Glass Container")
                                .font(.headline)

                            VStack {
                                VisualEffectView(
                                    effect: .glassContainer(spacing: 8)
                                ) {
                                    HStack(spacing: 8) {
                                        VisualEffectView(
                                            effect: glassEffect,
                                            cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                            backgroundColor: backgroundColor
                                        ) {
                                            label
                                        }

                                        VisualEffectView(
                                            effect: glassEffect,
                                            cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                            backgroundColor: backgroundColor
                                        ) {
                                            label
                                        }
                                    }
                                    .padding(8)
                                }
                                .padding(-8)

                                GlassEffectContainer(spacing: 8) {
                                    HStack(spacing: 8) {
                                        label
                                            .glassEffect(
                                                glassEffect.style.toSwiftUI().tint(glassEffect.tintColor).interactive(glassEffect.isInteractive),
                                                in: RoundedRectangle(cornerRadius: cornerRadius)
                                            )

                                        label
                                            .glassEffect(
                                                glassEffect.style.toSwiftUI().tint(glassEffect.tintColor).interactive(glassEffect.isInteractive),
                                                in: RoundedRectangle(cornerRadius: cornerRadius)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .animation(.default, value: glassEffect)

                            Picker(
                                sources: GlassEffect.Style.allCases,
                                selection: $glassEffect.style
                            ) { style in
                                Text(verbatim: "\(style)")
                            } label: {
                                Text("Glass Style")
                            }
                            .pickerStyle(.segmented)

                            Toggle(isOn: $glassEffect.isInteractive) {
                                Text(verbatim: "isInteractive")
                            }

                            Toggle(isOn: $glassEffect.prefersShadowHidden) {
                                Text(verbatim: "prefersShadowHidden")
                            }

                            HStack {
                                ColorPicker(
                                    selection: $glassEffect.tintColor[default: .accentColor],
                                    supportsOpacity: true
                                ) {
                                    Text("tintColor")
                                }

                                Button("Reset") {
                                    glassEffect.tintColor = nil
                                }
                            }
                        }
                    }
                    #endif

                    VStack(alignment: .leading) {
                        Text("Blur")
                            .font(.headline)

                        VStack {
                            HStack {
                                VisualEffectView(
                                    effect: blurEffect,
                                    cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                    backgroundColor: backgroundColor
                                ) {
                                    label
                                }

                                label
                                    .background {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .fill(blurEffect.style.toSwiftUI())
                                    }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)

                            HStack {
                                VisualEffectView(
                                    effect: blurEffect,
                                    cornerRadius: .capsule(maxCornerRadius: cornerRadius)
                                ) {
                                    label
                                }

                                VisualEffectView(
                                    effect: blurEffect,
                                    cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                    backgroundColor: backgroundColor
                                ) {
                                    label
                                }
                            }
                        }
                        .animation(.default, value: blurEffect)

                        Picker(
                            sources: BlurEffect.Style.allCases,
                            selection: $blurEffect.style
                        ) { style in
                            Text(verbatim: "\(style)")
                        } label: {
                            Text("Blur Style")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading) {
                        Text("Vibrancy")
                            .font(.headline)

                        HStack {
                            VisualEffectView(
                                effect: blurEffect,
                                cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                backgroundColor: backgroundColor
                            ) {
                                VisualEffectView(
                                    effect: .vibrancy(
                                        blur: blurEffect,
                                        style: vibrancyEffectStyle
                                    )
                                ) {
                                    label
                                }
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .animation(.default, value: blurEffect)
                        .animation(.default, value: vibrancyEffectStyle)

                        Picker(
                            sources: VibrancyEffect.Style.allCases,
                            selection: $vibrancyEffectStyle
                        ) { style in
                            Text(verbatim: "\(style)")
                        } label: {
                            Text("Vibrancy Style")
                        }
                        .pickerStyle(.segmented)
                    }

                    #if canImport(FoundationModels) // Xcode 26
                    if #available(iOS 26.0, *) {
                        VStack(alignment: .leading) {
                            Text("AnyEffect")
                                .font(.headline)

                            VisualEffectView(
                                effect: prefersGlassEffect ? AnyVisualEffect(glassEffect) : AnyVisualEffect(blurEffect),
                                cornerRadius: .capsule(maxCornerRadius: cornerRadius),
                                backgroundColor: backgroundColor
                            ) {
                                label
                            }
                            .padding(.vertical)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .animation(.default, value: prefersGlassEffect)
                        }

                        Toggle(isOn: $prefersGlassEffect) {
                            Text("Prefers Glass Effect")
                        }
                    }
                    #endif
                }
                .padding()
            }
        }
    }
}

#endif
