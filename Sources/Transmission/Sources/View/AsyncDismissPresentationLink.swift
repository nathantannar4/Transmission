//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI

/// A button that's action asynchronously dismisses the presented view.
///
/// > Note: The button is disabled if there is no presented view or when running the task
///
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct AsyncDismissPresentationLink<Label: View>: View {

    var label: (Bool) -> Label
    var task: AsyncTask

    @usableFromInline
    enum AsyncTask {
        case task(() async throws -> Void)
        case block(((Result<Void, Error>) -> Void) -> Void)
    }

    @State var isLoading: Bool = false
    @Environment(\.presentationCoordinator) var presentationCoordinator

    public init(
        task: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.label = label
        self.task = .task(task)
    }

    public init(
        task: @escaping ((Result<Void, Error>) -> Void) -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.label = label
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
                        try await task()
                        await MainActor.run {
                            withAnimation {
                                presentationCoordinator.dismiss(animation: .default)
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
                            if case .success = result {
                                presentationCoordinator.dismiss(animation: .default)
                            }
                            isLoading = false
                        }
                    }
                }
            }
        } label: {
            label(isLoading)
        }
        .disabled(!presentationCoordinator.isPresented || isLoading)
    }
}

#endif
