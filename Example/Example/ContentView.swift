//
//  ContentView.swift
//  Example
//
//  Created by Nathan Tannar on 2022-12-06.
//

import SwiftUI
import Transmission

struct ContentView: View {

    // Access to dismiss views
    @Environment(\.presentationCoordinator) var presentationCoordinator

    // Access to pop views
    @Environment(\.destinationCoordinator) var destinationCoordinator

    var body: some View {
        ScrollView {
            VStack {
                ExampleGroup {
                    PresentationLinkExamples()
                } label: {
                    HeaderView("Presentation Link")
                }

                ExampleGroup {
                    DestinationLinkExamples()
                } label: {
                    HeaderView("Destination Link")
                }

                ExampleGroup {
                    WindowLinkExamples()
                } label: {
                    HeaderView("Window Link")
                }

                ExampleGroup {
                    ShareSheetLinkExamples()
                } label: {
                    HeaderView("Share Sheet Link")
                }

                ExampleGroup {
                    QuickLookPreviewLinkExamples()
                } label: {
                    HeaderView("Quick Look Preview Link")
                }

                ExampleGroup {
                    StatusBarAppearanceExamples()
                } label: {
                    HeaderView("Status Bar Appearance")
                }

                DismissPresentationLink {
                    Text("Dismiss")
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
        }
        .background {
            Color.primary.opacity(0.04)
                .ignoresSafeArea()
        }
    }
}

struct HeaderView: View {
    var text: String
    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.headline.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExampleGroup<Label: View, Content: View>: View {
    var content: Content
    var label: Label

    @State var isExpanded = false

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    label
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.compact.down")
                }
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
            }

            if isExpanded {
                VStack(alignment: .leading) {
                    content
                        .padding(.horizontal, 12)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .buttonStyle(_ButtonStyle())
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)

                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 1)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 2)
            }
        }
    }

    struct _ButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.callout.weight(.medium))
                .padding(8)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.04))

                        RoundedRectangle(cornerRadius: 4)
                            .inset(by: 1)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 2)
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppContentView()
    }
}
