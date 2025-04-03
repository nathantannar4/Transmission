//
//  ContentView.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI
import WebKit

import Transmission

enum StatusBarStyle: CaseIterable, Hashable {
    case `default`
    case lightContent
    case darkContent

    func toUIKit() -> UIStatusBarStyle {
        switch self {
        case .default:
            return .default
        case .lightContent:
            return .lightContent
        case .darkContent:
            return .darkContent
        }
    }
}

struct ContentView: View {

    @State var isStatusBarHidden: Bool = false
    @State var statusBarStyle: StatusBarStyle = .default
    @State var isHeroPresented: Bool = false
    @State var isMatchedGeometryPresented = false
    @State var isMatchedGeometryPushPresented = false
    @State var isZoomPresented = false
    @State var isCardMatchedGeometryPresented = false
    @State var isSourceViewZoomPresented = false
    @State var progress: CGFloat = 0
    @State var isDestinationLinkExpanded: Bool = true
    @State var isPresentationLinkExpanded: Bool = true

    @Environment(\.presentationCoordinator) var presentationCoordinator
    @Environment(\.destinationCoordinator) var destinationCoordinator

    var body: some View {
        List {
            DisclosureGroup(isExpanded: $isDestinationLinkExpanded) {
                Section {
                    DestinationLink {
                        ContentView()
                    } label: {
                        Text("Push")
                    }

                    Button {
                        withAnimation {
                            isMatchedGeometryPushPresented = true
                        }
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 44, height: 44)
                                .destination(
                                    transition: .matchedGeometry,
                                    isPresented: $isMatchedGeometryPushPresented
                                ) {
                                    ContentView()
                                }

                            Text("Push w/ Matched Geometry")
                        }
                    }

                    DestinationSourceViewLink(transition: .zoomIfAvailable) {
                        ContentView()
                    } label: {
                        Text("Push w/ Zoom")
                    }

                    Button("Pop All") {
                        destinationCoordinator.popToRoot()
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("DestinationLink")
                        .font(.headline)
                    Text("via DestinationLinkModifier")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            DisclosureGroup(isExpanded: $isPresentationLinkExpanded) {
                Section {
                    PresentationLink(
                        transition: .sheet,
                        animation: .linear(duration: 1)
                    ) {
                        ContentView()
                    } label: {
                        Text("Sheet (default Detent)")
                    }

                    PresentationLink(
                        transition: .sheet(
                            detents: [.ideal]
                        )
                    ) {
                        ScrollView {
                            SafeAreaVisualizerView()
                                .aspectRatio(1, contentMode: .fit)
                        }
                    } label: {
                        Text("Sheet (ideal Detent)")
                    }

                    PresentationLink(
                        transition: .sheet(
                            detents: [
                                .constant("constant", height: 100)
                            ]
                        )
                    ) {
                        SafeAreaVisualizerView()
                    } label: {
                        Text("Sheet (constant Detent)")
                    }

                    PresentationLink(
                        transition: .sheet(
                            detents: [
                                .custom("custom", resolver: { context in
                                    return context.maximumDetentValue * 0.67
                                })
                            ]
                        )
                    ) {
                        SafeAreaVisualizerView()
                    } label: {
                        Text("Sheet (constant Detent)")
                    }
                } header: {
                    Text("Sheet Transitions")
                }

                Section {
                    PresentationLink(
                        transition: .matchedGeometry
                    ) {
                        ScrollableCollectionView(edge: .bottom)
                    } label: {
                        Text("Matched Geometry")
                    }

                    PresentationLink(
                        transition: .matchedGeometryZoom
                    ) {
                        ScrollableCollectionView(edge: .bottom)
                    } label: {
                        Text("Matched Geometry w/ Zoom")
                    }

                    Button {
                        withAnimation {
                            isMatchedGeometryPresented = true
                        }
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 44, height: 44)
                                .presentation(
                                    transition: .matchedGeometry(
                                        preferredCornerRadius: 10
                                    ),
                                    isPresented: $isMatchedGeometryPresented
                                ) {
                                    TransitionReader { proxy in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                            .aspectRatio(1, contentMode: .fit)
                                            .padding(proxy.progress * 16)
                                            .frame(maxHeight: .infinity, alignment: .top)
                                    }
                                }

                            Text("Matched Geometry")
                        }
                    }
                } header: {
                    Text("Matched Geometry Transitions")
                }

                if #available(iOS 18.0, *) {
                    Section {
                        ImageLink()

                        Button {
                            withAnimation {
                                isZoomPresented = true
                            }
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .frame(width: 44, height: 44)
                                    .presentation(
                                        transition: .zoom,
                                        isPresented: $isZoomPresented
                                    ) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                    }

                                Text("Zoom")
                            }
                        }

                        Button {
                            withAnimation {
                                isSourceViewZoomPresented = true
                            }
                        } label: {
                            HStack {
                                PresentationLinkAdapter(
                                    transition: .zoom,
                                    isPresented: $isSourceViewZoomPresented
                                ) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                } content: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                        .frame(width: 44, height: 44)
                                }

                                Text("Zoom w/ Source View")
                            }
                        }

                        PresentationSourceViewLink(
                            transition: .zoom
                        ) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        } label: {
                            HStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .frame(width: 44, height: 44)

                                Text("Zoom w/ Source View")
                            }
                        }

                    } header: {
                        Text("Zoom Transitions")
                    }
                }

                Section {
                    PresentationLink(
                        transition: .card,
                        animation: .spring(duration: 0.5, bounce: 0.35)
                    ) {
                        CardView()
                    } label: {
                        Text("Card")
                    }

                    PresentationLink(
                        transition: .card(
                            preferredEdgeInset: 0,
                            preferredCornerRadius: 0
                        )
                    ) {
                        CardView()
                    } label: {
                        Text("Card (custom insets)")
                    }

                    Button {
                        withAnimation(.spring(duration: 0.5)) {
                            isCardMatchedGeometryPresented = true
                        }
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                                .frame(width: 44, height: 44)
                                .presentation(
                                    transition: .asymmetric(
                                        presented: CardPresentationLinkTransition(
                                            options: .init(
                                                preferredAspectRatio: nil
                                            )
                                        ),
                                        presenting: MatchedGeometryPresentationLinkTransition(
                                            options: .init(
                                                prefersZoomEffect: true,
                                                initialOpacity: 1
                                            )
                                        ),
                                        dismissing: .default
                                    ),
                                    isPresented: $isCardMatchedGeometryPresented
                                ) {
                                    InfoCardView()
                                }

                            Text("Card w/ Matched Geometry")
                        }
                    }

                } header: {
                    Text("Card Transitions")
                }

                Section {
                    PresentationLink(
                        transition: .toast(edge: .top),
                        animation: .spring(duration: 0.5, bounce: 0.35)
                    ) {
                        ToastView()
                    } label: {
                        Text("Toast (top)")
                    }

                    PresentationLink(
                        transition: .toast(edge: .bottom),
                        animation: .spring(duration: 0.5, bounce: 0.35)
                    ) {
                        ToastView()
                    } label: {
                        Text("Toast (bottom)")
                    }
                } header: {
                    Text("Toast Transitions")
                }

                Section {
                    ForEach(Edge.allCases, id: \.self) { edge in
                        PresentationLink(
                            transition: .slide(edge: edge)
                        ) {
                            ScrollableCollectionView(edge: edge)
                        } label: {
                            Text("Slide (\(String(describing: edge)))")
                        }
                    }

                    PresentationLink(
                        transition: .slide(
                            edge: .bottom,
                            preferredPresentationBackgroundColor: .clear
                        )
                    ) {
                        VStack {
                            Text("Hello, World")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Material.ultraThin, ignoresSafeAreaEdges: .all)
                    } label: {
                        Text("Slide (Clear Background)")
                    }
                } header: {
                    Text("Slide Transitions")
                }

                Section {
                    PresentationLink(
                        transition: .dynamicIsland
                    ) {
                        DynamicIslandView()
                    } label: {
                        Text("Dynamic Island")
                    }
                } header: {
                    Text("Custom Transitions")
                }

                Section {
                    PresentationLink(transition: .fullscreen) {
                        SafeAreaVisualizerView()
                    } label: {
                        Text("Fullscreen")
                    }

                    PresentationLink(transition: .currentContext) {
                        SafeAreaVisualizerView()
                    } label: {
                        Text("Current Context")
                    }

                    PresentationLink(transition: .popover) {
                        PopoverView()
                    } label: {
                        Text("Popover")
                    }
                } header: {
                    Text("Default Transitions")
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("PresentationLink")
                        .font(.headline)
                    Text("via PresentationLinkModifier")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            DisclosureGroup {
                WindowLink(level: .overlay, transition: .opacity) {
                    SafeAreaVisualizerView()
                } label: {
                    Text("Overlay")
                }

                PresentationLink {
                    Text("Hello, World")
                        .window(level: .background, isPresented: .constant(true)) {
                            Color.blue.ignoresSafeArea()
                        }
                } label: {
                    Text("Background")
                }

                WindowLink(
                    level: .alert,
                    transition: .move(edge: .top).combined(with: .opacity),
                    animation: .spring
                ) {
                    ToastView()
                } label: {
                    Text("Toast")
                }

                WindowLink(level: .overlay) {
                    DismissPresentationLink {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Color.blue)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding([.bottom, .trailing])
                } label: {
                    Text("Fab Button")
                }

            } label: {
                VStack(alignment: .leading) {
                    Text("WindowLink")
                        .font(.headline)
                    Text("via WindowLinkModifier")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            DisclosureGroup {
                ShareSheetLink(items: [URL(string: "https://github.com/nathantannar4")!]) { result in
                    switch result {
                    case .success(let activity):
                        if let activity {
                            print("Performed \(activity)")
                        } else {
                            print("Shared")
                        }
                    case .failure(let error):
                        print("Cancelled/Error \(error)")
                    }
                } label: {
                    Text("URL")
                }

                ShareSheetLink(items: ["https://github.com/nathantannar4"]) {
                    Text("String")
                }

                ShareSheetLink(items: [
                    SnapshotItemProvider(label: "Image") {
                        Text("Hello, World")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color.blue)
                    }
                ]) {
                    Text("View")
                }

            } label: {
                VStack(alignment: .leading) {
                    Text("ShareSheetLink")
                        .font(.headline)
                    Text("via ShareSheetLinkModifier")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            if let url = Bundle.main.url(forResource: "Logo", withExtension: "png") {
                DisclosureGroup {
                    QuickLookPreviewLink(url: url, transition: .default) {
                        Text("Default")
                    }

                    QuickLookPreviewLink(url: url, transition: .scale) {
                        Text("Scale")
                    }
                } label: {
                    Text("QuickLookPreviewLink")
                        .font(.headline)
                }
            }

            DisclosureGroup {
                PresentationLink {
                    TransitionReader { proxy in
                        Color.blue.opacity(proxy.progress)
                            .overlay {
                                Text(proxy.progress.description)
                                    .foregroundStyle(.white)
                            }
                            .ignoresSafeArea()
                            .onChange(of: proxy.progress) { newValue in
                                progress = newValue
                            }
                    }
                } label: {
                    Text("PresentationLink")
                }

                NavigationLink {
                    TransitionReader { proxy in
                        Color.blue.opacity(proxy.progress)
                            .overlay {
                                Text(proxy.progress.description)
                                    .foregroundStyle(.white)
                            }
                            .ignoresSafeArea()
                            .onChange(of: proxy.progress) { newValue in
                                progress = newValue
                            }
                    }
                } label: {
                    Text("NavigationLink")
                }

            } label: {
                Text("TransitionReader")
                    .font(.headline)
            }

            PresentationLink(transition: .slide) {
                PageView()
            } label: {
                Text("TabView")
            }

            PresentationLink(transition: .slide) {
                WebView()
            } label: {
                Text("WebView")
            }

            Toggle(isOn: $isStatusBarHidden) {
                Text("isStatusBarHidden")
            }

            Picker(selection: $statusBarStyle) {
                ForEach(StatusBarStyle.allCases, id: \.self) { style in
                    Text(verbatim: "\(style)")
                }
            } label: {
                Text("UIStatusBarStyle")
            }

            Button("Dismiss All") {
                presentationCoordinator.dismissToRoot()
            }
            .disabled(!presentationCoordinator.isPresented)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Transmission")
        .prefersStatusBarHidden(isStatusBarHidden)
        .preferredStatusBarStyle(statusBarStyle.toUIKit())
    }
}

struct PopoverView: View {
    @State var isExpanded: Bool = false

    var body: some View {
        SafeAreaVisualizerView {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Text("Toggle Size")
            }
        }
        .frame(width: isExpanded ? 200 : 100, height: isExpanded ? 200 : 100)
    }
}

struct SafeAreaVisualizerView<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init() where Content == EmptyView {
        self.content = EmptyView()
    }

    var body: some View {
        ZStack {
            Color.blue
                .opacity(0.3)
                .ignoresSafeArea()

            Color.blue
                .opacity(0.3)

            TransitionReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)

                    VStack {
                        content

                        DismissPresentationLink {
                            Text("Dismiss")
                        }
                    }
                    .foregroundStyle(.white)
                }
                .padding(12)
            }
        }
    }
}

struct ScrollableCollectionView: View {
    var edge: Edge

    var body: some View {
        let isHorizontal = (edge == .leading || edge == .trailing)
        ScrollView(isHorizontal ? [.horizontal] : [.vertical]) {
            if isHorizontal {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: 44)

                    ForEach(0...20, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 44)
                    }
                }
                .padding(12)
            } else {
                VStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(height: 44)

                    ForEach(0...40, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 44)
                    }
                }
                .padding(12)
            }
        }
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThickMaterial)

                Color.blue
                    .opacity(0.3)
            }
            .ignoresSafeArea()
        }
    }
}

struct CardView: View {
    @State var text = ""

    var body: some View {
        SafeAreaVisualizerView {
            TextField("Placeholder", text: $text)
                .fixedSize()
        }
    }
}

struct InfoCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lorem ipsum")
                    .font(.title3.bold())

                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            DismissPresentationLink {
                Text("Done")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity, alignment: .top)
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
        .frame(minHeight: 48)
        .buttonStyle(.plain)
        .prefersStatusBarHidden()
        .environment(\.colorScheme, .dark)
        .padding(12)
        .ignoresSafeArea(edges: .vertical)
    }
}

@available(iOS 18.0, *)
struct ImageLink: View {

    var images: [String] = [
        "Landscape1",
        "Landscape2",
        "Landscape3",
    ]
    @State var selectedImage: String?

    var body: some View {
        Button {
            withAnimation {
                selectedImage = images.first
            }
        } label: {
            HStack {
                PresentationSourceViewLink(
                    transition: .zoom(options: .init(preferredPresentationBackgroundColor: .black)),
                    isPresented: $selectedImage.isNotNil()
                ) {
                    Destination(
                        images: images,
                        selectedImage: $selectedImage
                    )
                } label: {
                    Image(selectedImage ?? images.first!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipped()
                }
                .animation(.default, value: selectedImage)

                Text("Image Link")
            }
        }
    }

    struct Destination: View {
        var images: [String]
        @Binding var selectedImage: String?
        @State var scrollPosition: String?

        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(images, id: \.self) { image in
                        Image(image)
                            .resizable()
                            .scaledToFit()
                    }
                    .containerRelativeFrame(.horizontal)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedImage)
        }
    }
}

struct PageView: View {
    var body: some View {
        TabView {
            ForEach(0..<10, id: \.self) { index in
                Text(index.description)
            }
        }
        .tabViewStyle(.page)
    }
}

struct WebView: View {

    var body: some View {
        _Body()
            .ignoresSafeArea()
    }

    struct _Body: UIViewRepresentable {
        func makeUIView(context: Context) -> WKWebView {
            let uiView = WKWebView(frame: .zero)
            return uiView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            uiView.load(URLRequest(url: URL(string: "https://github.com/nathantannar4")!))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
