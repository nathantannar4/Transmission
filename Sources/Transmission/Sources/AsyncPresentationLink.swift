//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

/// A button that asynchronously presents a destination view in a new `UIViewController`.
///
/// The destination view is presented with the provided `transition`.
/// By default, the ``PresentationLinkTransition/default`` transition is used.
///
/// See Also:
///  - ``PresentationLink``
///  - ``PresentationLinkTransition``
///  - ``TransitionReader``
///
/// > Tip: You can implement custom transitions with a `UIPresentationController` and/or
/// `UIViewControllerInteractiveTransitioning` with the ``PresentationLinkTransition/custom(_:)``
///  transition.
///
/// > Note: The button is disabled when running the task
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct AsyncPresentationLink<
    Value,
    Label: View,
    Destination: View
>: View {
    var label: (Bool) -> Label
    var destination: (Value) -> Destination
    var transition: PresentationLinkTransition
    var task: AsyncTask

    @usableFromInline
    enum AsyncValue {
        case unloaded(Bool)
        case loaded(Value)

        var isLoading: Bool {
            switch self {
            case .unloaded(let isLoading):
                return isLoading
            case .loaded:
                return false
            }
        }
    }

    @usableFromInline
    enum AsyncTask {
        case task(() async throws -> Value)
        case block(((Result<Value, Error>) -> Void) -> Void)
    }

    @State var value: Value?
    @State var isLoading: Bool = false

    public init(
        transition: PresentationLinkTransition = .default,
        task: @escaping () async throws -> Value,
        @ViewBuilder destination: @escaping (Value) -> Destination,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.label = label
        self.destination = destination
        self.transition = transition
        self.task = .task(task)
    }

    public init(
        transition: PresentationLinkTransition = .default,
        task: @escaping ((Result<Value, Error>) -> Void) -> Void,
        @ViewBuilder destination: @escaping (Value) -> Destination,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.label = label
        self.destination = destination
        self.transition = transition
        self.task = .block(task)
    }

    public var body: some View {
        Button {
            withAnimation {
                isLoading = true
            }
            switch task {
            case .task(let task):
                Task(priority: .userInitiated) {
                    do {
                        let result = try await task()
                        await MainActor.run {
                            withAnimation {
                                value = result
                                isLoading = false
                            }
                        }
                    } catch {
                        await MainActor.run {
                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
                }
            case .block(let block):
                block { result in
                    DispatchQueue.main.async {
                        withAnimation {
                            if case .success(let value) = result {
                                self.value = value
                            }
                            isLoading = false
                        }
                    }
                }
            }
        } label: {
            label(isLoading)
        }
        .disabled(isLoading)
        .presentation($value, transition: transition) { $value in
            destination(value)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AsyncPresentationLink {
    public init<ViewController: UIViewController>(
        transition: PresentationLinkTransition = .default,
        task: @escaping () async throws -> Value,
        destination: @escaping (Value, Destination.Context) -> ViewController,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) where Destination == _ViewControllerRepresentableAdapter<ViewController> {
        self.init(transition: transition, task: task, destination: { value in
            _ViewControllerRepresentableAdapter { ctx in
                destination(value, ctx)
            }
        }, label: label)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AsyncPresentationLink_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            VStack(spacing: 20) {
                AsyncPresentationLink {
                    return "Hello, World"
                } destination: { value in
                    Text(value)
                } label: { isLoading in
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Default")
                    }
                }
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
