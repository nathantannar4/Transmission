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
                DisclosureGroup {
                    PresentationLinkExamples()
                } label: {
                    HeaderView("Presentation Link")
                }

                DisclosureGroup {
                    DestinationLinkExamples()
                } label: {
                    HeaderView("Destination Link")
                }

                DisclosureGroup {
                    WindowLinkExamples()
                } label: {
                    HeaderView("Window Link")
                }

                DisclosureGroup {
                    ShareSheetLinkExamples()
                } label: {
                    HeaderView("Share Sheet Link")
                }

                DisclosureGroup {
                    QuickLookPreviewLinkExamples()
                } label: {
                    HeaderView("Quick Look Preview Link")
                }

                DisclosureGroup {
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
            .disclosureGroupStyle(DisclosureGroupSectionStyle())
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

struct DisclosureGroupSectionStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.compact.down")
                }
                .padding(.horizontal, 12)
            }

            if configuration.isExpanded {
                VariadicViewAdapter {
                    configuration.content
                } content: { content in
                    VStack(alignment: .leading) {
                        ForEachSubview(content) { index, subview in
                            subview
                                .padding(.horizontal, 12)

                            if index < content.count - 1 {
                                Color.primary.opacity(0.06)
                                    .frame(height: 2)
                                    .padding(.horizontal, 2)
                            }
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .buttonStyle(_ButtonStyle())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.vertical, 6)
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
