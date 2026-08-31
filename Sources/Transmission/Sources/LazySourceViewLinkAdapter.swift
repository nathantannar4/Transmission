//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct LazySourceViewTransitionKey: TransactionKey {
    static let defaultValue: Bool = false
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Transaction {

    public var isLazySourceViewTransition: Bool {
        self[LazySourceViewTransitionKey.self]
    }
}

@frozen
public struct LazySourceViewTransitionModifier: VersionedViewModifier {

    public init() { }

    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public func v5Body(content: Content) -> some View {
        content
            .transaction { transaction in
                if transaction.isLazySourceViewTransition {
                    transaction.animation = nil
                }
            }
    }
}

@frozen
public struct LazySourceViewLinkAdapter<
    IsLazy: ViewInputsCondition,
    Content: View,
    SourceView: View,
>: View {

    var isPresented: Bool
    var content: Content
    var sourceView: SourceView

    public init(
        _ : IsLazy.Type = IsLazy.self,
        isPresented: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder sourceView: () -> SourceView = { EmptyView() }
    ) {
        self.isPresented = isPresented
        self.content = content()
        self.sourceView = sourceView()
    }

    public var body: some View {
        ZStack {
            ViewInputConditionalContent(IsLazy.self) {
                LazyBody(
                    isPresented: isPresented,
                    content: content,
                    sourceView: sourceView
                )
            } otherwise: {
                content
            }
        }
    }

    private struct LazyBody: View {

        var isPresented: Bool
        var content: Content
        var sourceView: SourceView

        @State var isLazyLoaded: Bool

        init(
            isPresented: Bool,
            content: Content,
            sourceView: SourceView
        ) {
            self.isPresented = isPresented
            self.content = content
            self.sourceView = sourceView
            self._isLazyLoaded = State(wrappedValue: isPresented)
        }

        var body: some View {
            ZStack {
                if isPresented || isLazyLoaded {
                    content
                        .transition(.identity)
                        .transaction { transaction in
                            guard !isLazyLoaded else { return }
                            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
                                transaction[LazySourceViewTransitionKey.self] = true
                            }
                            transaction.disablesAnimations = true
                        }
                        .onAppear {
                            withCATransaction {
                                isLazyLoaded = true
                            }
                        }
                }

                if !isLazyLoaded {
                    sourceView
                        .transition(.identity)
                        .zIndex(1)
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct LazySourceViewLinkAdapter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {

        @State var isPresented = false
        @State var id = 0

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(100) {
                        HStack(spacing: 16) {
                            LazySourceViewLinkAdapter(
                                IsInLazyContainer.self,
                                isPresented: isPresented
                            ) {
                                Color.blue
                                    .frame(width: 100, height: 100)
                            } sourceView: {
                                Color.red
                                    .frame(width: 100, height: 100)
                            }
                            .id(id)

                            LazySourceViewLinkAdapter(
                                IsInLazyContainer.self,
                                isPresented: isPresented
                            ) {
                                LinkView()
                            } sourceView: {
                                LinkView()
                            }
                            .id(id)

                            LazySourceViewLinkAdapter(
                                IsInLazyContainer.self,
                                isPresented: true
                            ) {
                                LinkView()
                            } sourceView: {
                                LinkView()
                            }
                            .id(id)

                            LazySourceViewLinkAdapter(
                                IsInLazyContainer.self,
                                isPresented: isPresented
                            ) {
                                Color.blue
                                    .frame(width: 100, height: 100)
                            }
                            .id(id)
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                HStack {
                    Button {
                        isPresented = false
                        id += 1
                    } label: {
                        Text("Reset")
                    }

                    Button {
                        withAnimation {
                            isPresented.toggle()
                        }
                    } label: {
                        Text("Load")
                    }
                }
                .padding()
            }
        }

        struct LinkView: View {
            @State var didAppear = false

            var body: some View {
                Color.yellow
                    .frame(width: 100, height: 100)
                    .opacity(didAppear ? 1 : 0)
                    .animation(.default, value: didAppear)
                    .onAppear {
                        withAnimation {
                            didAppear = true
                        }
                    }
                    .modifier(LazySourceViewTransitionModifier())
            }
        }
    }
}
