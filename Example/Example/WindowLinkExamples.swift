//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Transmission

struct WindowLinkExamples: View {

    @State var level: WindowLinkLevel = .default

    enum Transition: Hashable {
        case `default`
        case opacity
        case move
        case scale
    }
    @State var transition: Transition = .opacity
    func makeWindowLinkTransition() -> WindowLinkTransition {
        switch transition {
        case .default:
            return .opacity
        case .opacity:
            return .opacity
        case .move:
            return .move(edge: .bottom).combined(with: .opacity)
        case .scale:
            return .scale(scale: 0.8).combined(with: .opacity)
        }
    }

    @State var isPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Level")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker(selection: $level) {
                    Text(".default").tag(WindowLinkLevel.default)
                    Text(".background").tag(WindowLinkLevel.background)
                    Text(".overlay").tag(WindowLinkLevel.overlay)
                    Text(".alert").tag(WindowLinkLevel.alert)
                } label: {
                    Text("Window Link Level")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            HStack {
                Text("Transition")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker(selection: $transition) {
                    Text(".default").tag(Transition.default)
                    Text(".opacity").tag(Transition.opacity)
                    Text(".move").tag(Transition.move)
                    Text(".scale").tag(Transition.scale)
                } label: {
                    Text("Window Link Transition")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            WindowLink(
                level: level,
                transition: makeWindowLinkTransition()
            ) {
                ZStack {
                    SafeAreaVisualizerView()

                    DismissPresentationLink {
                        Text("Dismiss")
                            .foregroundStyle(.white)
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("Present Window")
                    Text("w/ `WindowLink`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            Button {
                // You can use custom animation curves
                withAnimation(.spring(duration: 2)) {
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
            .window(
                level: level,
                transition: makeWindowLinkTransition(),
                isPresented: $isPresented
            ) {
                ZStack {
                    SafeAreaVisualizerView()

                    DismissPresentationLink {
                        Text("Dismiss")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(.bottom)

        VStack(alignment: .leading) {
            Text("Examples")
                .font(.subheadline.weight(.medium))

            PresentationLink {
                Text("Hello, World")
                    .window(level: .background, isPresented: .constant(true)) {
                        Color.blue.ignoresSafeArea()
                    }
            } label: {
                VStack(alignment: .leading) {
                    Text("Present Sheet w/ Background Window")
                    Text("w/ `WindowLinkModifier`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }

            WindowLink(
                level: .alert,
                transition: .move(edge: .top).combined(with: .opacity),
                animation: .spring
            ) {
                ToastView()
            } label: {
                VStack(alignment: .leading) {
                    Text("Present Toast")
                    Text("w/ `WindowLink`")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
        }
    }
}

#Preview {
    WindowLinkExamples()
}
