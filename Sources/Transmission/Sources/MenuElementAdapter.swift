//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@frozen
@available(iOS 14.0, *)
public struct MenuElementAdapter<Content: MenuElement>: MenuElement {

    public var content: Content

    @inlinable
    public init(
        @MenuBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public var body: some MenuElement {
        content
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
public struct MenuElementAdapter_Previews: PreviewProvider {
    public static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        var body: some View {
            VStack {
                let options = MenuElementAdapter {
                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.smaller")
                        Text("Small")
                    }

                    MenuButton {

                    } label: {
                        Image(systemName: "textformat.size.larger")
                        Text("Large")
                    }
                }

                MenuSourceViewLink {
                    options

                    MenuButton {

                    } label: {
                        Image(systemName: "character.text.justify")
                        Text("More")
                    }
                } label: {
                    Text("Menu")
                }
            }
        }
    }
}

#endif
