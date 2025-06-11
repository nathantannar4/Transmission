//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import QuickLook

/// A quick look preview provider.
@available(iOS 14.0, *)
@frozen
public struct QuickLookPreviewItem: Equatable {

    public var url: URL
    public var label: Text?

    public init(url: URL, label: Text? = nil) {
        self.url = url
        self.label = label
    }
}

/// A quick look preview transition.
@available(iOS 14.0, *)
@frozen
public struct QuickLookPreviewTransition: Equatable {
    
    var rawValue: UInt8

    /// The default transition effect
    public static let `default` = QuickLookPreviewTransition(rawValue: 0)

    /// The matched geometry transition effect
    public static let matchedGeometry = QuickLookPreviewTransition(rawValue: 1 << 0)
}

/// A button that presents a `QLPreviewController`
///
/// To present the preview with an animation, `isPresented` should
/// be updated with a transaction that has an animation. For example:
///
/// ```
/// withAnimation {
///     isPresented = true
/// }
/// ```
///
@available(iOS 14.0, *)
@frozen
public struct QuickLookPreviewLink<
    Label: View
>: View {
    var label: Label
    var items: [QuickLookPreviewItem]
    var transition: QuickLookPreviewTransition

    @StateOrBinding var isPresented: Bool

    public init(
        items: [QuickLookPreviewItem],
        transition: QuickLookPreviewTransition = .default,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.items = items
        self.transition = transition
        self._isPresented = .init(false)
    }

    public init(
        items: [QuickLookPreviewItem],
        transition: QuickLookPreviewTransition = .default,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.items = items
        self.transition = transition
        self._isPresented = .init(isPresented)
    }

    public init(
        url: URL,
        transition: QuickLookPreviewTransition = .default,
        @ViewBuilder label: () -> Label
    ) {
        self.init(items: [.init(url: url)], transition: transition, label: label)
    }

    public var body: some View {
        Button {
            withAnimation {
                isPresented = true
            }
        } label: {
            label
        }
        .modifier(
            QuickLookPreviewLinkModifier(
                items: items,
                transition: transition,
                isPresented: $isPresented
            )
        )
    }
}

@available(iOS 14.0, *)
extension View {

    /// A modifier that presents a `QLPreviewController`
    public func quickLookPreview(
        items: [QuickLookPreviewItem],
        transition: QuickLookPreviewTransition = .default,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            QuickLookPreviewLinkModifier(
                items: items,
                transition: transition,
                isPresented: isPresented
            )
        )
    }

    /// A modifier that presents a `QLPreviewController`
    public func quickLookPreview(
        url: URL,
        transition: QuickLookPreviewTransition = .default,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            QuickLookPreviewLinkModifier(
                items: [.init(url: url)],
                transition: transition,
                isPresented: isPresented
            )
        )
    }
}

/// A modifier that presents a `QLPreviewController`
@available(iOS 14.0, *)
@frozen
public struct QuickLookPreviewLinkModifier: ViewModifier {

    var items: [QuickLookPreviewItem]
    var transition: QuickLookPreviewTransition
    var isPresented: Binding<Bool>

    public init(
        items: [QuickLookPreviewItem],
        transition: QuickLookPreviewTransition = .default,
        isPresented: Binding<Bool>
    ) {
        self.items = items
        self.transition = transition
        self.isPresented = isPresented
    }

    public func body(content: Content) -> some View {
        content
            .modifier(
                PresentationLinkModifier(
                    transition: .default,
                    isPresented: isPresented,
                    destination: QuickLookPreviewView(
                        items: items,
                        transition: transition
                    )
                )
            )
    }
}

@available(iOS 14.0, *)
public struct QuickLookPreviewView: UIViewControllerRepresentable {
    var items: [QuickLookPreviewItem]
    var transition: QuickLookPreviewTransition

    public init(
        items: [QuickLookPreviewItem],
        transition: QuickLookPreviewTransition
    ) {
        self.items = items
        self.transition = transition
    }

    public func makeUIViewController(
        context: Context
    ) -> UIViewController {
        let uiViewController = PreviewController()
        return uiViewController
    }

    public func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
        let items = items.map { $0.resolve(in: context.environment) }
        let uiViewController = uiViewController as! PreviewController
        uiViewController.openURL = context.environment.openURL
        uiViewController.sourceView = transition == .default ? nil : context.environment.presentationCoordinator.sourceView
        uiViewController.items = items
    }

    class PreviewController: QLPreviewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        var openURL: OpenURLAction?
        weak var sourceView: UIView?
        var items: [QuickLookPreviewItem.Resolved] = [] {
            didSet {
                guard oldValue != items else { return }
                previewItems = items.map { $0.makeQLPreviewItem() }
                if viewIfLoaded != nil {
                    reloadData()
                }
            }
        }

        private var previewItems: [QuickLookPreviewItem.Resolved.PreviewItem] = []

        init() {
            super.init(nibName: nil, bundle: nil)
            dataSource = self
            delegate = self
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func numberOfPreviewItems(
            in controller: QLPreviewController
        ) -> Int {
            previewItems.count
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            previewItems[index]
        }

        func previewController(
            _ controller: QLPreviewController,
            shouldOpen url: URL,
            for item: QLPreviewItem
        ) -> Bool {
            if let openURL {
                openURL(url)
                return false
            }
            return true
        }

        func previewController(
            _ controller: QLPreviewController,
            transitionViewFor item: QLPreviewItem
        ) -> UIView? {
            if item === previewItems.first {
                return sourceView
            }
            return nil
        }
    }
}

@available(iOS 14.0, *)
extension QuickLookPreviewItem {
    struct Resolved: Equatable {
        var label: String?
        var url: URL

        class PreviewItem: NSObject, QLPreviewItem {
            var item: QuickLookPreviewItem.Resolved

            var previewItemTitle: String? { item.label }
            var previewItemURL: URL? { item.url }

            init(item: QuickLookPreviewItem.Resolved) {
                self.item = item
            }
        }
        func makeQLPreviewItem() -> PreviewItem {
            PreviewItem(item: self)
        }
    }

    func resolve(in environment: EnvironmentValues) -> Resolved {
        Resolved(label: label?.resolve(in: environment), url: url)
    }
}

#endif
