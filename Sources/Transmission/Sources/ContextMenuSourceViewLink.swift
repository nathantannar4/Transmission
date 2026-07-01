//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A view that manages the presentation of a context menu. The presentation is
/// sourced from this view.
///
/// See Also:
///  - ``ContextMenuLinkAdapter``
///  - ``ContextMenuLinkModifier``
///  - ``ContextMenuAccessoryView``
///
@frozen
@available(iOS 14.0, *)
public struct ContextMenuSourceViewLink<
    Label: View,
    Menu: MenuElement,
    AccessoryViews: View,
    Preview: View
>: View {

    var label: Label
    var menu: Menu
    var accessoryViews: AccessoryViews
    var preview: Preview
    var transition: ContextMenuLinkPreviewTransition
    var cornerRadius: CornerRadiusOptions?
    var backgroundColor: Color?
    var visibleInset: CGFloat

    @StateOrBinding var isPresented: Bool

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) {
        self.label = label()
        self.menu = menu()
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(false)
    }

    public init(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        @ViewBuilder preview: () -> Preview = { EmptyView() },
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) {
        self.label = label()
        self.menu = menu()
        self.accessoryViews = accessoryViews()
        self.preview = preview()
        self.transition = transition
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.visibleInset = visibleInset
        self._isPresented = .init(isPresented)
    }

    public var body: some View {
        ContextMenuLinkAdapter(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: $isPresented
        ) {
            menu
        } preview: {
            preview
        } content: {
            label
        } accessoryViews: {
            accessoryViews
        }
    }
}

@available(iOS 14.0, *)
extension ContextMenuSourceViewLink {

    public init<PreviewViewController: UIViewController>(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        @MenuBuilder menu: () -> Menu,
        preview: @escaping () -> PreviewViewController,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) where Preview == ViewControllerRepresentableAdapter<PreviewViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset
        ) {
            menu()
        } preview: {
            ViewControllerRepresentableAdapter(preview)
        } label: {
            label()
        } accessoryViews: {
            accessoryViews()
        }
    }

    public init<PreviewViewController: UIViewController>(
        transition: ContextMenuLinkPreviewTransition = .default,
        cornerRadius: CornerRadiusOptions? = nil,
        backgroundColor: Color? = nil,
        visibleInset: CGFloat = 0,
        isPresented: Binding<Bool>,
        @MenuBuilder menu: () -> Menu,
        preview: @escaping () -> PreviewViewController,
        @ViewBuilder label: () -> Label,
        @ViewBuilder accessoryViews: () -> AccessoryViews = { EmptyView() }
    ) where Preview == ViewControllerRepresentableAdapter<PreviewViewController> {
        self.init(
            transition: transition,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            visibleInset: visibleInset,
            isPresented: isPresented
        ) {
            menu()
        } preview: {
            ViewControllerRepresentableAdapter(preview)
        } label: {
            label()
        } accessoryViews: {
            accessoryViews()
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct ContextMenuSourceViewLink_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContextMenuSourceViewLink {
                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }
            } label: {
                Text("Single Action Menu")
            }

            ContextMenuSourceViewLink {
                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }

                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }
            } preview: {
                Color.white
                    .frame(width: 300, height: 300)
            } label: {
                Text("Single Action Menu w/ Custom Preview")
            }

            ContextMenuSourceViewLink {
                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }

                MenuButton {

                } label: {
                    Image(systemName: "apple.logo")
                    Text("Option A")
                    Text("Subtitle")
                }
            } label: {
                Text("Single Action Menu w/ Accessory")
            } accessoryViews: {
                ContextMenuAccessoryView(
                    location: .preview,
                    alignment: .topLeading,
                    trackingAxis: [.vertical, .horizontal]
                ) {
                    if #available(iOS 26.0, *) {
                        #if canImport(FoundationModels) // Xcode 26
                        Text("Accessory")
                            .padding()
                            .glassEffect()
                        #endif
                    } else if #available(iOS 15.0, *) {
                        Text("Accessory")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThickMaterial))
                    } else {
                        Text("Accessory")
                            .padding()
                    }
                }
            }
        }
    }
}

#endif
