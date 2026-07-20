//
//  UnevenCornerRadiiExamples.swift
//  Example
//

import SwiftUI
import Transmission

/// A grid whose outer top corners are rounded more than its inner corners, so that the
/// grid reads as a single card. Each cell transitions to a full screen, animating each
/// corner independently.
struct UnevenCornerRadiiExamples: View {

    private static let columnCount = 2
    private static let spacing: CGFloat = 4
    private static let outerCornerRadius: CGFloat = 28
    private static let innerCornerRadius: CGFloat = 6

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: spacing),
        count: columnCount
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: Self.spacing) {
            ForEach(0..<6) { index in
                let cornerRadius = CornerRadiusOptions.unevenRounded(
                    cornerRadii: cornerRadii(for: index),
                    style: .continuous
                )

                PresentationSourceViewLink(
                    transition: .matchedGeometry(
                        preferredFromCornerRadius: cornerRadius,
                        preferredToCornerRadius: .screen(),
                        initialOpacity: 1
                    ),
                    animation: .bouncy(duration: 0.5)
                ) {
                    ThumbnailDetailView(index: index)
                } label: {
                    ThumbnailView(index: index, cornerRadius: cornerRadius)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Only the two cells of the top row are rounded, and only on their outer corner.
    private func cornerRadii(for index: Int) -> CornerRadiusOptions.CornerRadii {
        CornerRadiusOptions.CornerRadii(
            topLeading: index == 0 ? Self.outerCornerRadius : Self.innerCornerRadius,
            bottomLeading: Self.innerCornerRadius,
            bottomTrailing: Self.innerCornerRadius,
            topTrailing: index == Self.columnCount - 1 ? Self.outerCornerRadius : Self.innerCornerRadius
        )
    }
}

private struct ThumbnailView: View {
    var index: Int
    var cornerRadius: CornerRadiusOptions

    var body: some View {
        // `CornerRadiusOptions` is a `Shape`, so the source view can be clipped to
        // the same corners the transition animates from.
        Color.thumbnail(index)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(cornerRadius)
    }
}

private struct ThumbnailDetailView: View {
    var index: Int

    @Environment(\.presentationCoordinator) var presentationCoordinator

    var body: some View {
        ZStack {
            Color.thumbnail(index)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Thumbnail \(index + 1)")
                    .font(.largeTitle.bold())

                Button {
                    presentationCoordinator.dismiss(animation: .bouncy(duration: 0.5))
                } label: {
                    Text("Dismiss")
                }
                .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
        }
    }
}

extension Color {
    fileprivate static func thumbnail(_ index: Int) -> Color {
        Color(hue: 0.55 + Double(index) * 0.04, saturation: 0.7, brightness: 0.85)
    }
}
