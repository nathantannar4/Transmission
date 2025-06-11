//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Transmission

struct QuickLookPreviewLinkExamples: View {

    @State var isPresented: Bool = false
    @State var isSourceViewPresented: Bool = false

    var body: some View {
        let url = Bundle.main.url(forResource: "Logo", withExtension: "png")!
        QuickLookPreviewLink(
            url: url,
            transition: .default
        ) {
            HStack {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text("Default Transition")
                    Text("w/ `QuickLookPreviewLink`")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

        QuickLookPreviewLink(
            url: url,
            transition: .matchedGeometry
        ) {
            HStack {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text("Matched Geometry Transition")
                    Text("w/ `QuickLookPreviewLink`")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

        Button {
            withAnimation {
                isPresented = true
            }
        } label: {
            HStack {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .quickLookPreview(
                        url: url,
                        transition: .matchedGeometry,
                        isPresented: $isPresented
                    )

                VStack(alignment: .leading) {
                    Text("Matched Geometry Transition")
                    Text("w/ `QuickLookPreviewLinkModifier`")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }

        Button {
            withAnimation {
                isSourceViewPresented = true
            }
        } label: {
            HStack {
                // By using `PresentationLinkAdapter` the logo image will
                // transition alongside the presentation
                PresentationLinkAdapter(
                    transition: .default,
                    isPresented: $isSourceViewPresented
                ) {
                    QuickLookPreviewView(
                        items: [
                            QuickLookPreviewItem(url: url)
                        ],
                        transition: .matchedGeometry
                    )
                } content: {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text("Matched Geometry Transition")
                    Text("w/ `QuickLookPreviewView`")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }
}

#Preview {
    QuickLookPreviewLinkExamples()
}
