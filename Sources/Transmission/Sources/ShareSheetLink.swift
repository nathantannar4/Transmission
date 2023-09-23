//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import UniformTypeIdentifiers
import LinkPresentation

/// A protocol that defines an interface for creating activities for a `UIActivityViewController`
///
/// > Important: Conforming types should be a struct or an enum
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol ShareSheetItemProvider {
    /// The `UIActivityItemSource` representation of the provider
    func makeUIActivityItemSource(context: Context) -> UIActivityItemSource

    /// The `UIActivity` representation of the provider
    ///
    /// > Note: This protocol implementation is optional and defaults to `nil`
    /// 
    func makeUIActivity(context: Context) -> UIActivity?

    typealias Context = ShareSheetItemProviderContext
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ShareSheetItemProvider {
    public func makeUIActivity(context: Context) -> UIActivity? { nil }
}

/// The resolution context for a ``ShareSheetItemProvider``
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct ShareSheetItemProviderContext {
    public var environment: EnvironmentValues
}

/// A button that presents a `UIActivityViewController`
///
/// To present the share sheet with an animation, `isPresented` should
/// be updated with a transaction that has an animation. For example:
///
/// ```
/// withAnimation {
///     isPresented = true
/// }
/// ```
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct ShareSheetLink<
    Label: View
>: View {
    var label: Label
    var items: [ShareSheetItemProvider]
    var action: ((Result<UIActivity.ActivityType?, Error>) -> Void)?

    @StateOrBinding var isPresented: Bool

    public init(
        items: [ShareSheetItemProvider],
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.items = items
        self.action = action
        self._isPresented = .init(false)
    }

    public init(
        items: [ShareSheetItemProvider],
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.items = items
        self.action = action
        self._isPresented = .init(isPresented)
    }

    public init(
        items: ShareSheetItemProvider...,
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.init(items: items, action: action, label: label)
    }

    public init(
        items: ShareSheetItemProvider...,
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.init(items: items, action: action, isPresented: isPresented, label: label)
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
            ShareSheetLinkModifier(
                items: items,
                action: action,
                isPresented: $isPresented
            )
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    
    /// A modifier that presents a `UIActivityViewController`
    ///
    /// To present the share sheet with an animation, `isPresented` should
    /// be updated with a transaction that has an animation. For example:
    ///
    /// ```
    /// withAnimation {
    ///     isPresented = true
    /// }
    /// ```
    ///
    /// See Also:
    ///  - ``ShareSheetLinkModifier``
    ///  
    public func share(
        items: [ShareSheetItemProvider],
        isPresented: Binding<Bool>,
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil
    ) -> some View {
        modifier(
            ShareSheetLinkModifier(
                items: items,
                action: action,
                isPresented: isPresented
            )
        )
    }

    /// A modifier that presents a `UIActivityViewController`
    ///
    /// To present the share sheet with an animation, `isPresented` should
    /// be updated with a transaction that has an animation. For example:
    ///
    /// ```
    /// withAnimation {
    ///     isPresented = true
    /// }
    /// ```
    ///
    /// See Also:
    ///  - ``ShareSheetLinkModifier``
    ///
    public func share(
        item: Binding<ShareSheetItemProvider?>,
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil
    ) -> some View {
        self.share(items: item.wrappedValue.map { [$0] } ?? [], isPresented: item.isNotNil(), action: action)
    }
}

/// A modifier that presents a `UIActivityViewController`
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct ShareSheetLinkModifier: ViewModifier {

    var items: [ShareSheetItemProvider]
    var action: ((Result<UIActivity.ActivityType?, Error>) -> Void)?
    var isPresented: Binding<Bool>

    public init(
        items: [ShareSheetItemProvider],
        action: ((Result<UIActivity.ActivityType?, Error>) -> Void)? = nil,
        isPresented: Binding<Bool>
    ) {
        self.items = items
        self.action = action
        self.isPresented = isPresented
    }

    public func body(content: Content) -> some View {
        content
            .modifier(
                PresentationLinkModifier(
                    transition: .default,
                    isPresented: isPresented,
                    destination: Destination(
                        items: items,
                        action: action,
                        isPresented: isPresented
                    )
                )
            )
    }

    private struct Destination: UIViewControllerRepresentable {
        var items: [ShareSheetItemProvider]
        var action: ((Result<UIActivity.ActivityType?, Error>) -> Void)?
        var isPresented: Binding<Bool>

        func makeUIViewController(context: Context) -> UIActivityViewController {
            assert(items.allSatisfy({ !isClassType($0) }), "ShareSheetItemProvider must be value types (either a struct or an enum); it was a class")
            let ctx = ShareSheetItemProviderContext(environment: context.environment)
            let activityItems = items.map { $0.makeUIActivityItemSource(context: ctx) }
            let applicationActivities = items.compactMap { $0.makeUIActivity(context: ctx) }
            let uiViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
            uiViewController.completionWithItemsHandler = { activity, completed, _, error in
                if completed {
                    action?(.success(activity))
                } else if let error = error {
                    action?(.failure(error))
                }
                isPresented.wrappedValue = false
            }
            return uiViewController
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
    }
}

/// A share sheet provider for a string.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension String: ShareSheetItemProvider {
    public func makeUIActivityItemSource(context: Context) -> UIActivityItemSource {
        Source(content: self)
    }

    private class Source: NSObject, UIActivityItemSource {
        let content: String

        init(content: String) {
            self.content = content
        }

        func activityViewControllerPlaceholderItem(
            _ activityViewController: UIActivityViewController
        ) -> Any {
            content
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            itemForActivityType activityType: UIActivity.ActivityType?
        ) -> Any? {
            content
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            subjectForActivityType activityType: UIActivity.ActivityType?
        ) -> String {
            content
        }

        func activityViewControllerLinkMetadata(
            _ activityViewController: UIActivityViewController
        ) -> LPLinkMetadata? {
            let metadata = LPLinkMetadata()
            metadata.title = content
            return metadata
        }
    }
}

/// A share sheet provider for a url.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension URL: ShareSheetItemProvider {
    public func makeUIActivityItemSource(context: Context) -> UIActivityItemSource {
        Source(url: self)
    }

    private class Source: UIActivityItemProvider {
        let url: URL

        init(url: URL) {
            self.url = url
            super.init(placeholderItem: url)
        }

        override var item: Any { url }
    }

    public func makeUIActivity(context: Context) -> UIActivity? {
        let title = Text("Safari").resolve(in: context.environment)
        return Activity(title: title)
    }

    private class Activity: UIActivity {

        var title: String
        var items: [Any] = []

        init(title: String) {
            self.title = title
        }

        override var activityType: UIActivity.ActivityType? {
            UIActivity.ActivityType("SFSafariActivity")
        }

        override var activityTitle: String? {
            title
        }

        override var activityImage: UIImage? {
            UIImage(systemName: "safari")
        }

        public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
            for item in activityItems {
                if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                    return true
                }
            }
            return false
        }

        public override func prepare(withActivityItems activityItems: [Any]) {
            items = activityItems
        }

        private func openURL(checksCanOpenURL: Bool) -> Bool {
            for item in items {
                if let url = item as? URL, (!checksCanOpenURL || UIApplication.shared.canOpenURL(url)) {
                    UIApplication.shared.open(url) { success in
                        self.activityDidFinish(success)
                    }
                    return true
                }
            }
            return false
        }

        public override func perform() {
            var didOpen = openURL(checksCanOpenURL: true)
            if !didOpen {
                didOpen = openURL(checksCanOpenURL: false)
            }
            if !didOpen {
                activityDidFinish(false)
            }
        }
    }
}

/// A share sheet provider for an object that conforms to `NSItemProviderWriting`.
public struct ShareSheetItem<T: NSItemProviderWriting> {

    var label: String?
    var object: T

    public init(label: String? = nil, _ object: T) {
        self.label = label
        self.object = object
    }
}

extension ShareSheetItem: ShareSheetItemProvider {
    public func makeUIActivityItemSource(context: Context) -> UIActivityItemSource {
        Source(item: self)
    }

    private class Source: NSObject, UIActivityItemSource {
        let item: ShareSheetItem<T>

        init(item: ShareSheetItem<T>) {
            self.item = item
        }

        func activityViewControllerPlaceholderItem(
            _ activityViewController: UIActivityViewController
        ) -> Any {
            item.object
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            itemForActivityType activityType: UIActivity.ActivityType?
        ) -> Any? {
            item.object
        }

        func activityViewControllerLinkMetadata(
            _ activityViewController: UIActivityViewController
        ) -> LPLinkMetadata? {
            let metadata = LPLinkMetadata()
            metadata.title = item.label
            metadata.imageProvider = NSItemProvider(object: item.object)
            return metadata
        }
    }
}

/// A share sheet provider for generating an image from a view.
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct SnapshotItemProvider<Content: View>: ShareSheetItemProvider {
    var label: Text
    var content: Content

    public init(label: LocalizedStringKey, content: Content) {
        self.label = Text(label)
        self.content = content
    }

    public init(label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(label: label, content: content())
    }

    @_disfavoredOverload
    public init(label: String, content: Content) {
        self.label = Text(verbatim: label)
        self.content = content
    }

    @_disfavoredOverload
    public init(label: String, @ViewBuilder content: () -> Content) {
        self.init(label: label, content: content())
    }

    public func makeUIActivityItemSource(context: Context) -> UIActivityItemSource {
        Source(label: label.resolve(in: context.environment), content: content)
    }

    private class Source: NSObject, UIActivityItemSource {
        private let label: String
        private let provider: SnapshotRenderProvider

        init(label: String, content: Content) {
            self.label = label
            self.provider = SnapshotRenderProvider(content: content)
        }

        func activityViewControllerPlaceholderItem(
            _ activityViewController: UIActivityViewController
        ) -> Any {
            label
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            itemForActivityType activityType: UIActivity.ActivityType?
        ) -> Any? {
            if let data = provider.data {
                return UIImage(data: data)
            } else {
                return provider
            }
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            subjectForActivityType activityType: UIActivity.ActivityType?
        ) -> String {
            label
        }

        func activityViewControllerLinkMetadata(
            _ activityViewController: UIActivityViewController
        ) -> LPLinkMetadata? {
            let metadata = LPLinkMetadata()
            metadata.title = label
            metadata.imageProvider = NSItemProvider(object: provider)
            return metadata
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
        ) -> String {
            UTType.image.identifier
        }

        private class SnapshotRenderProvider: NSObject, NSItemProviderWriting {
            let content: Content

            var data: Data?

            init(content: Content) {
                self.content = content
            }

            static var writableTypeIdentifiersForItemProvider: [String] {
                UIImage.writableTypeIdentifiersForItemProvider
            }

            func loadData(
                withTypeIdentifier typeIdentifier: String,
                forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
            ) -> Progress? {
                DispatchQueue.main.async {
                    let renderer = SnapshotRenderer(content: self.content)
                    guard let image = renderer.uiImage else {
                        completionHandler(nil, nil)
                        return
                    }
                    image.loadData(withTypeIdentifier: typeIdentifier) { data, error in
                        self.data = data
                        completionHandler(data, error)
                    }
                }
                return nil
            }
        }
    }
}

#endif
