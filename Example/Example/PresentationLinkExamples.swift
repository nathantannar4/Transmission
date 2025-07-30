//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Transmission

struct PresentationLinkExamples: View {

    enum Transition: Hashable {
        case `default`
        case sheet
        case popover
        case fullScreen
        case slide
        case zoom
        case card
        case matchedGeometry
        case toast
    }
    @State var transition: Transition = .default
    @State var isInteractive = true
    @State var initialOpacity: CGFloat = 0
    @State var prefersZoomEffect: Bool = false
    @State var prefersScaleEffect: Bool = true
    @State var preferredEdgeInset: Int = 4
    @State var preferredCornerRadius: Int = 10
    func makePresentationLinkTransition() -> PresentationLinkTransition {
        switch transition {
        case .default:
            return .default(
                options: .init(isInteractive: isInteractive)
            )
        case .sheet:
            return .sheet(
                options: .init(
                    detents: [.ideal, .medium, .large],
                    isInteractive: isInteractive
                )
            )
        case .popover:
            return .popover(
                options: .init(isInteractive: isInteractive)
            )
        case .fullScreen:
            return .fullscreen(
                options: .init(isInteractive: isInteractive)
            )
        case .slide:
            return .slide(
                edge: .bottom,
                prefersScaleEffect: prefersScaleEffect,
                isInteractive: isInteractive
            )
        case .zoom:
            if #available(iOS 18.0, *) {
                return .zoom(
                    options: .init(options: .init(isInteractive: isInteractive))
                )
            }
            return .default
        case .card:
            return .card(
                preferredEdgeInset: CGFloat(preferredEdgeInset),
                preferredCornerRadius: .rounded(cornerRadius: CGFloat(preferredCornerRadius), style: .circular),
                preferredAspectRatio: 1,
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: nil
            )
        case .matchedGeometry:
            return .matchedGeometry(
                preferredFromCornerRadius: .rounded(cornerRadius: CGFloat(preferredCornerRadius), style: .circular),
                preferredToCornerRadius: nil,
                prefersScaleEffect: prefersScaleEffect,
                prefersZoomEffect: prefersZoomEffect,
                minimumScaleFactor: 0.75,
                initialOpacity: initialOpacity,
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: nil
            )
        case .toast:
            return .toast(
                edge: .top,
                isInteractive: isInteractive,
                preferredPresentationBackgroundColor: nil
            )
        }
    }

    @State var isPresented = false
    @State var isMatchedGeometryPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Transition")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker(selection: $transition) {
                    Text(".default").tag(Transition.default)
                    Text(".sheet").tag(Transition.sheet)
                    Text(".popover").tag(Transition.popover)
                    Text(".fullScreen").tag(Transition.fullScreen)
                    Text(".slide").tag(Transition.slide)
                    Text(".zoom").tag(Transition.zoom)
                    Text(".card").tag(Transition.card)
                    Text(".matchedGeometry").tag(Transition.matchedGeometry)
                    Text(".toast").tag(Transition.toast)
                } label: {
                    Text("Presentation Link Transition")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            .tint(.blue)
            .fontWeight(.bold)
            .foregroundStyle(.blue)

            Toggle(isOn: $isInteractive) {
                Text("Interactive Dismiss Enabled")
            }
            .tint(.blue)
            .fontWeight(.bold)
            .foregroundStyle(.blue)

            if transition == .card {
                Stepper(value: $preferredCornerRadius, step: 1) {
                    Text("Preferred Corner Radius: \(preferredCornerRadius)")
                }
                .tint(.blue)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            }

            if transition == .card || transition == .matchedGeometry {
                Stepper(value: $preferredEdgeInset, step: 1) {
                    Text("Preferred Edge Inset: \(preferredEdgeInset)")
                }
                .tint(.blue)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            }


            if transition == .matchedGeometry {
                HStack {
                    Text("Initial Opacity")

                    Slider(value: $initialOpacity, in: 0...1)

                    Text(initialOpacity, format: .number.precision(.significantDigits(0..<2)))
                }
                .tint(.blue)
                .fontWeight(.bold)
                .foregroundStyle(.blue)

                Toggle(isOn: $prefersZoomEffect) {
                    Text("Prefers Zoom Effect")
                }
                .tint(.blue)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            }

            if transition == .slide || transition == .matchedGeometry {
                Toggle(isOn: $prefersScaleEffect) {
                    Text("Prefers Scale Effect")
                }
                .tint(.blue)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            }

            PresentationLink(
                transition: makePresentationLinkTransition()
            ) {
                AppContentView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Present Destination")
                    Text("w/ `PresentationLink`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            Button {
                // You can use custom animation curves for non-standard
                // transitions (.sheet, .popover, .etc)
                withAnimation(.spring) {
                    isPresented = true
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("Present Destination")
                    Text("w/ `PresentationLinkModifier`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .presentation(
                transition: makePresentationLinkTransition(),
                isPresented: $isPresented
            ) {
                AppContentView()
            }

            // `PresentationSourceViewLink` makes the `label` view available to transition
            // alongside as the "source view"
            if transition == .zoom || transition == .matchedGeometry {
                PresentationSourceViewLink(
                    transition: makePresentationLinkTransition()
                ) {
                    AppContentView()
                } label: {
                    VStack(alignment: .leading) {
                        Text("Present Destination")
                        Text("w/ `PresentationSourceViewLink`")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
            }
        }
        .padding(.bottom)

        VStack(alignment: .leading) {
            Text("Examples")
                .font(.subheadline.weight(.medium))

            PresentationLink {
                TransitionReader { proxy in
                    Color.blue
                        .opacity(proxy.progress)
                        .overlay {
                            Text(proxy.progress.description)
                                .foregroundStyle(.white)
                        }
                        .ignoresSafeArea()
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("Animate alongside presentation")
                    Text("w/ `TransitionReader`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .sheet(detent: .ideal),
                animation: .spring(duration: 0.5, bounce: 0.35)
            ) {
                InfoCardView()
                    .padding()
            } label: {
                VStack(alignment: .leading) {
                    Text("Self sizing sheet")
                    Text("w/ `.sheet` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .toast(
                    edge: .top,
                    isInteractive: isInteractive,
                    preferredPresentationBackgroundColor: .clear
                ),
                animation: .spring(duration: 0.5, bounce: 0.35)
            ) {
                ToastView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Simple notifications")
                    Text("w/ `.toast` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .card(
                    preferredAspectRatio: nil,
                    isInteractive: isInteractive
                ),
                animation: .spring(duration: 0.5, bounce: 0.35)
            ) {
                InfoCardView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Self sizing card view")
                    Text("w/ `.card` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .dynamicIsland,
                animation: .bouncy
            ) {
                DynamicIslandView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Custom transition")
                    Text("w/ `.dynamicIsland` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .popover(
                    isInteractive: isInteractive,
                    preferredPresentationBackgroundColor: nil
                )
            ) {
                ZStack {
                    SafeAreaVisualizerView()

                    PopoverView()
                        .foregroundStyle(.white)
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("Popover")
                    Text("w/ `.popover` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .zoomIfAvailable(
                    options: .init(
                        dimmingVisualEffect: .systemThickMaterial
                    )
                )
            ) {
                ScrollableView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Zoom w/ visual effect")
                    Text("w/ `.zoom` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            PresentationLink(
                transition: .slide(
                    edge: .bottom,
                    isInteractive: isInteractive,
                    preferredPresentationBackgroundColor: .clear
                )
            ) {
                ScrollableView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Fullscreen sheet")
                    Text("w/ `.slide` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            Button {
                withAnimation {
                    isMatchedGeometryPresented = true
                }
            } label: {
                HStack {
                    // `DestinationLinkAdapter` makes the `label` view available to transition
                    // alongside as the "source view"
                    PresentationLinkAdapter(
                        transition: .matchedGeometry,
                        isPresented: $isMatchedGeometryPresented,
                    ) {
                        RoundedRectangle(cornerRadius: 10, style: .circular)
                            .fill(Color.blue)
                            .aspectRatio(1, contentMode: .fit)
                    } content: {
                        RoundedRectangle(cornerRadius: 10, style: .circular)
                            .fill(Color.blue)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 44, height: 44)
                    }

                    VStack(alignment: .leading) {
                        Text("Hero transition")
                        Text("w/ `.matchedGeometry` Transition")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
            }

            PresentationLink(
                transition: .matchedGeometry(
                    prefersZoomEffect: true,
                    initialOpacity: 0,
                    isInteractive: isInteractive,
                    preferredPresentationBackgroundColor: .clear
                )
            ) {
                ScrollableView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Backwards compatible zoom")
                    Text("w/ `.matchedGeometryZoom` Transition")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            VStack(alignment: .leading) {
                Text("Extra fancy matched geometry transition")
                    .font(.callout.weight(.medium))

                PresentationSourceViewLink(
                    transition: .asymmetric(
                        presented: CardPresentationLinkTransition(
                            options: .init(
                                preferredAspectRatio: nil,
                            )
                        ),
                        presenting: MatchedGeometryPresentationLinkTransition(
                            options: .init(
                                preferredFromCornerRadius: .circle,
                                preferredToCornerRadius: CardPresentationLinkTransition.defaultAdjustedCornerRadius,
                                initialOpacity: 1
                            )
                        ),
                        dismissing: MatchedGeometryPresentationLinkTransition(
                            options: .init(
                                preferredFromCornerRadius: .circle,
                                preferredToCornerRadius: CardPresentationLinkTransition.defaultAdjustedCornerRadius,
                                initialOpacity: 1
                            )
                        ),
                        options: .init(
                            preferredPresentationBackgroundColor: nil
                        )
                    ),
                    animation: .bouncy(duration: 0.5)
                ) {
                    TransitionReader { proxy in
                        InfoCardView(isPresented: proxy.isPresented)
                    }
                } label: {
                    Text("Delete")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            Capsule().fill(.red)
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }
}

struct ToastView: View {
    @Environment(\.presentationCoordinator) var presentationCoordinator

    var body: some View {
        Button {
            presentationCoordinator.dismiss()
        } label: {
            Text("Hello, World")
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color.blue)
                }
                .padding(8)
                .background {
                    ZStack {
                        Rectangle()
                            .fill(.thickMaterial)

                        Color.blue.opacity(0.3)
                    }
                    .clipShape(Capsule(style: .continuous))
                }
        }
        .buttonStyle(ToastButtonStyle())
    }

    struct ToastButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.interactiveSpring, value: configuration.isPressed)
        }
    }
}

struct DynamicIslandView: View {
    var body: some View {
        HStack {
            Circle()
                .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: 0) {
                Text("Title")
                Text("Subtitle")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.1)

            DismissPresentationLink {
                ZStack {
                    Circle()
                        .fill(.red)

                    Image(systemName: "phone.down.fill")
                }
            }
            .aspectRatio(1, contentMode: .fit)

            DismissPresentationLink {
                ZStack {
                    Circle()
                        .fill(.green)

                    Image(systemName: "phone.fill")
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .frame(minHeight: 48, maxHeight: .infinity)
        .buttonStyle(.plain)
        .prefersStatusBarHidden()
        .environment(\.colorScheme, .dark)
        .padding(12)
        .ignoresSafeArea(edges: .vertical)
    }
}

struct PopoverView: View {
    @State var isExpanded: Bool = false

    var body: some View {
        VStack {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Text("Toggle Size")
            }

            DismissPresentationLink {
                Text("Dismiss")
            }
        }
        .frame(width: isExpanded ? 200 : 100, height: isExpanded ? 200 : 100)
    }
}

struct InfoCardView: View {
    var isPresented: Bool = true

    var body: some View {
        VStack {
            if isPresented {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("Lorem ipsum")
                            .font(.title3.bold())

                        Spacer()

                        DismissPresentationLink {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Lorem ipsum dolor sit amet consectetur adipiscing elit quisque faucibus ex sapien vitae pellentesque sem placerat in id cursus mi pretium tellus duis convallis tempus leo eu aenean sed diam.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .transition(.opacity.animation(.default.speed(2)))
            }

            let layout = isPresented ? AnyLayout(HStackLayout()) : AnyLayout(ZStackLayout())
            layout {
                DismissPresentationLink {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            Capsule()
                                .fill(.black)
                        }
                }

                PresentationLink(
                    transition: .asymmetric(
                        presented: CardPresentationLinkTransition(
                            options: .init(
                                preferredAspectRatio: nil
                            )
                        ),
                        presenting: MatchedGeometryPresentationLinkTransition(
                            options: .init(
                                preferredFromCornerRadius: .circle,
                                preferredToCornerRadius: CardPresentationLinkTransition.defaultAdjustedCornerRadius,
                                initialOpacity: 1
                            )
                        ),
                        dismissing: MatchedGeometryPresentationLinkTransition(
                            options: .init(
                                preferredFromCornerRadius: .circle,
                                preferredToCornerRadius: CardPresentationLinkTransition.defaultAdjustedCornerRadius,
                                initialOpacity: 1
                            )
                        ),
                        options: .init(
                            preferredPresentationBackgroundColor: nil
                        )
                    ),
                    animation: .bouncy(duration: 0.5)
                ) {
                    TransitionReader { proxy in
                        InfoCardView(isPresented: proxy.isPresented)
                    }
                } label: {
                    Text("Delete")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            Capsule().fill(.red)
                        }
                }
            }
        }
    }
}

struct ScrollableView: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                DismissPresentationLink {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .overlay {
                            Text("Dismiss")
                                .foregroundStyle(.white)
                        }
                        .frame(height: 44)
                }

                ForEach(0...40, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.75))
                        .frame(height: 44)
                }
            }
            .padding(12)
        }
        .background {
            SafeAreaVisualizerView()
        }
    }
}

struct SafeAreaVisualizerView: View {
    var body: some View {
        ZStack {
            Color.blue
                .opacity(0.3)
                .ignoresSafeArea()

            Color.blue
                .opacity(0.3)
        }
    }
}

#Preview {
    PresentationLinkExamples()
}
