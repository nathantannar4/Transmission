//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// Ensures a subgraph is created in the view graph to workaround data flow update issues
public struct ViewGraphBridgeAdapter<
    Source: View,
    Content: View
>: View {

    public typealias SourceAlias = ViewGraphBridgeAdapterSourceAlias<Source>

    var source: Source
    var content: (SourceAlias) -> Content

    public init(
        @ViewBuilder source: @escaping () -> Source,
        @ViewBuilder content: @escaping (SourceAlias) -> Content
    ) {
        self.source = source()
        self.content = content
    }

    public var body: some View {
        VariadicViewAdapter {
            source
        } content: { content in
            self.content(SourceAlias(content: content))
        }
    }
}

public struct ViewGraphBridgeAdapterSourceAlias<Source: View>: View {
    var content: VariadicView<Source>

    public var body: some View {
        content
    }
}

#endif
