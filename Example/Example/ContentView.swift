//
//  ContentView.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI

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
    @State var progress: CGFloat = 0

    var body: some View {
        NavigationView {
            List {
                DisclosureGroup {
                    Section {
                        PresentationLink(transition: .fullscreen) {
                            VStack {
                                Text("Hello, World")

                                DismissPresentationLink {
                                    Text("Dismiss")
                                }
                            }
                        } label: {
                            Text("Fullscreen")
                        }

                        PresentationLink(transition: .currentContext) {
                            VStack {
                                Text("Hello, World")

                                DismissPresentationLink {
                                    Text("Dismiss")
                                }
                            }
                        } label: {
                            Text("Current Context")
                        }

                        PresentationLink(transition: .popover) {
                            Popover()
                        } label: {
                            Text("Popover")
                        }
                    } header: {
                        Text("Default Transitions")
                    }

                    Section {
                        PresentationLink(transition: .sheet) {
                            ContentView()
                        } label: {
                            Text("Sheet (default Detent)")
                        }

                        PresentationLink(transition: .sheet(detents: [.ideal])) {
                            ScrollView {
                                VStack {
                                    Color.blue.aspectRatio(1, contentMode: .fit)

                                    Text("Hello, World")
                                }
                            }
                        } label: {
                            Text("Sheet (ideal Detent)")
                        }

                        PresentationLink(transition: .sheet(detents: [.constant("constant", height: 100)])) {
                            Text("Hello, World")
                        } label: {
                            Text("Sheet (constant Detent)")
                        }

                        PresentationLink(transition: .sheet(detents: [.custom("custom", resolver: { context in return context.maximumDetentValue * 0.67 })])) {
                            Text("Hello, World")
                        } label: {
                            Text("Sheet (constant Detent)")
                        }
                    } header: {
                        Text("Sheet Transitions")
                    }

                    Section {
                        ForEach(Edge.allCases, id: \.self) { edge in
                            PresentationLink(transition: .slide(edge: edge)) {
                                EdgeView(edge: edge)
                            } label: {
                                Text("Slide (\(String(describing: edge)))")
                            }
                        }
                    } header: {
                        Text("Slide Transitions")
                    }

                    Section {
                        PresentationLink(transition: .card) {
                            Text("Hello, World")
                        } label: {
                            Text("Card")
                        }

                        PresentationLink(
                            transition: .card(
                                options: .init(preferredEdgeInset: 0, preferredCornerRadius: 0)
                            )
                        ) {
                            Text("Hello, World")
                        } label: {
                            Text("Card (custom insets)")
                        }
                    } header: {
                        Text("Card Transitions")
                    }

                    Section {
                        Button {
                            withAnimation {
                                isHeroPresented = true
                            }
                        } label: {
                            HStack {
                                // Hero Move picks up the source frame from where the modifier or PresentationLink was used
                                Color.blue.frame(width: 44, height: 44)
                                    .presentation(transition: .heroMove, isPresented: $isHeroPresented) {
                                        ScrollView {
                                            VStack {
                                                Color.blue.aspectRatio(1, contentMode: .fit)

                                                Text("Hello, World")
                                            }
                                        }
                                    }

                                Text("Hero Move")
                            }
                        }

                        PresentationLink(
                            transition: .toast
                        ) {
                            DismissPresentationLink {
                                Text("Hello, World")
                                    .padding()
                                    .background {
                                        Capsule()
                                            .fill(.background)
                                            .shadow(radius: 10)
                                    }
                            }
                        } label: {
                            Text("Toast")
                        }


                        NavigationLink {
                            ScrollView {
                                LazyVGrid(columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)]) {
                                    ForEach(["C", "B", "A", "D", "E"], id: \.self) { user in
                                        ProfileCell(user: user)
                                    }
                                }
                            }
                        } label: {
                            Text("View More Hero Move")
                        }
                    } header: {
                        Text("Custom Transitions")
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
                        NavigationView {
                            VStack {
                                Text("Hello, World")

                                DismissPresentationLink {
                                    Text("Dismiss")
                                }
                            }
                        }
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


                    WindowLink(level: .alert, transition: .move(edge: .top).combined(with: .opacity)) {
                        Toast()
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

                DisclosureGroup {
                    PresentationLink {
                        TransitionReader { proxy in
                            Color.blue.opacity(proxy.progress)
                                .ignoresSafeArea()
                                .onChange(of: proxy.progress) { newValue in
                                    progress = newValue
                                }
                        }
                    } label: {
                        HStack {
                            Text("PresentationLink")

                            Text(progress.description)
                        }
                    }

                    NavigationLink {
                        TransitionReader { proxy in
                            Color.blue.opacity(proxy.progress)
                                .ignoresSafeArea()
                                .onChange(of: proxy.progress) { newValue in
                                    progress = newValue
                                }
                        }
                    } label: {
                        HStack {
                            Text("NavigationLink")

                            Text(progress.description)
                        }
                    }

                } label: {
                    Text("TransitionReader")
                        .font(.headline)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Transmission")
            .prefersStatusBarHidden(isStatusBarHidden)
            .preferredStatusBarStyle(statusBarStyle.toUIKit())
        }
        .navigationViewStyle(.stack)
    }
}

struct EdgeView: View {
    var edge: Edge

    var body: some View {
        let isHorizontal = (edge == .leading || edge == .trailing)
        ScrollView(isHorizontal ? [.horizontal] : [.vertical]) {
            if isHorizontal {
                HStack {
                    Color.blue
                        .frame(width: 44)

                    ForEach(0...20, id: \.self) { _ in
                        Color.red
                            .frame(width: 44)
                    }
                }
            } else {
                VStack {
                    Color.blue
                        .frame(height: 44)

                    ForEach(0...20, id: \.self) { _ in
                        Color.red
                            .frame(height: 44)
                    }
                }
            }
        }
    }
}

struct Toast: View {
    @Environment(\.presentationCoordinator) var presentationCoordinator

    var body: some View {
        Button {
            presentationCoordinator.dismiss()
        } label: {
            Text("Hello, World")
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color.blue)
                }
        }
        .buttonStyle(.plain)
    }
}

struct Popover: View {
    @State var isExpanded: Bool = false

    var body: some View {
        Text("Hello, World")
            .frame(width: isExpanded ? 200 : 100, height: isExpanded ? 200 : 100)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
    }
}

struct ProfileCell: View {
    var user: String

    var body: some View {
        PresentationLink(transition: .heroMove) {
            NavigationView {
                ProfileView(user: user)
                    .navigationTitle("Profile")
            }
        } label: {
            Image("Headshot\(user)")
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)
        }
    }
}

struct ProfileView: View {
    var user: String
    @Environment(\.presentationCoordinator) var presentationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Image("Headshot\(user)")
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture {
                        presentationCoordinator.dismiss()
                    }

                Text("@username")
                    .font(.headline)

                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris sit amet nunc bibendum, luctus metus vel, bibendum metus. Nam efficitur interdum leo sit amet aliquet. Sed nec placerat leo, non iaculis erat. Donec vulputate varius sapien eget sodales. Nunc faucibus, ipsum eu imperdiet convallis, diam lacus suscipit felis")
                    .foregroundColor(.secondary)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
