//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

open class HostingView<
    Content: View
>: _UIHostingView<_HostingViewContent<Content>> {

    public var content: Content {
        get { adapter.content }
        set { adapter.content = newValue }
    }

    public var disablesSafeArea: Bool = false

    public override var safeAreaInsets: UIEdgeInsets {
        if disablesSafeArea {
            return .zero
        }
        return super.safeAreaInsets
    }

    private let adapter: HostingViewContentAdapter<Content>

    public init(content: Content) {
        let adapter = HostingViewContentAdapter(content: content)
        self.adapter = adapter
        super.init(rootView: _HostingViewContent(adapter: adapter))
        backgroundColor = nil
    }

    public convenience init(@ViewBuilder content: () -> Content) {
        self.init(content: content())
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS, obsoleted: 13.0, renamed: "init(content:)")
    public required init(rootView: _HostingViewContent<Content>) {
        fatalError("init(rootView:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event), result != self else {
            return nil
        }
        return result
    }
}

private class HostingViewContentAdapter<Content: View>: ObservableObject {
    var content: Content {
        didSet {
            withCATransaction {
                self.objectWillChange.send()
            }
        }
    }

    init(content: Content) {
        self.content = content
    }
}

public struct _HostingViewContent<Content: View>: View {
    @ObservedObject fileprivate var adapter: HostingViewContentAdapter<Content>

    public var body: some View {
        adapter.content
    }
}

#endif
