//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Transmission

struct ShareSheetLinkExamples: View {

    @State var isPresented: Bool = false

    var body: some View {
        ShareSheetLink(
            items: [
                URL(string: "https://github.com/nathantannar4")!
            ]
        ) { result in
            // Callback on share action
            switch result {
            case .success(let activity):
                if let activity {
                    print("Performed \(activity)")
                } else {
                    print("Shared")
                }
            case .failure(let error):
                print("Error \(error)")
            }
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("URL")

                    Text(verbatim: "https://github.com/nathantannar4")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text("w/ `ShareSheetLink`")
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44, alignment: .trailing)
        }

        Button {
            withAnimation {
                isPresented = true
            }
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("String")

                    Text(verbatim: "Hello, World")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text("w/ `ShareSheetLink`")
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 44, alignment: .trailing)
        }
        // Also available as a modifier
        .share(items: ["Hello, World"], isPresented: $isPresented)

        ShareSheetLink(
            items: [
                // Use `ShareSheetItem` for any `NSItemProviderWriting`
                ShareSheetItem(label: "Logo", UIImage(resource: .logo))
            ]
        ) {
            HStack {
                VStack(alignment: .leading) {
                    Text("UIImage")
                    Text("w/ `ShareSheetLink`")
                        .foregroundStyle(.secondary)
                }

                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }

        let snapshot = Text("Hello, World")
            .foregroundColor(.white)
            .frame(width: 200, height: 200)
            .background(Color.blue)
        ShareSheetLink(
            items: [
                SnapshotItemProvider(label: "Image") {
                    snapshot
                }
            ]
        ) {
            HStack {
                VStack(alignment: .leading) {
                    Text("SnapshotItemProvider (View)")
                    Text("w/ `ShareSheetLink`")
                        .foregroundStyle(.secondary)
                }
                .layoutPriority(1)

                snapshot
                    .frame(width: 40, height: 40)
                    .scaleEffect(40 / 200)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview {
    ShareSheetLinkExamples()
}
