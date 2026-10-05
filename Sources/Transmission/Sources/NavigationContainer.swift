//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct NavigationContainer<
    Content: View,
    Controller: NavigationContainerController<Content>
>: View {

    var content: Content

    public init(
        _ as: Controller.Type,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public init(
        @ViewBuilder content: () -> Content
    ) where Controller == NavigationContainerController<Content> {
        self.init(
            NavigationContainerController<Content>.self,
            content: content
        )
    }

    public var body: some View {
        ControllerContainer(
            ContainerBody(
                content: content
            )
        )
    }

    private struct ContainerBody: ControllerContainerRepresentable {
        var content: Content

        func makeBody(configuration: Configuration) -> some View {
            NavigationContainerAdapter<Content, Controller>(
                configuration: configuration,
                content: content
            )
        }
    }
}

@available(iOS 14.0, *)
private struct NavigationContainerAdapter<
    Content: View,
    Controller: NavigationContainerController<Content>
>: UIViewControllerRepresentable {

    var configuration: ControllerContainerConfiguration
    var content: Content

    typealias UIViewControllerType = Controller

    func makeUIViewController(
        context: Context
    ) -> UIViewControllerType {
        let uiViewController = UIViewControllerType(
            content: content
        )
        return uiViewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        uiViewController.update(
            content,
            configuration: configuration,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
open class NavigationContainerController<
    Content: View
>: UINavigationController {

    private var safeAreaInsets: UIEdgeInsets? {
        didSet {
            guard oldValue != safeAreaInsets else { return }
            updateAdditionalSafeAreaInsets()
        }
    }

    private let host: HostingController<Content>

    public required init(
        content: Content
    ) {
        self.host = HostingController(content: content)
        host.view.backgroundColor = nil
        super.init(rootViewController: host)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        isToolbarHidden = false
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateAdditionalSafeAreaInsets()
    }

    private func updateAdditionalSafeAreaInsets() {
        let additionalSafeAreaInsets = additionalSafeAreaInsets(
            safeAreaInsets: safeAreaInsets
        )
        if self.additionalSafeAreaInsets != additionalSafeAreaInsets {
            self.additionalSafeAreaInsets = additionalSafeAreaInsets
        }
    }

    open func update(
        _ content: Content,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        host.update(content: content, transaction: transaction)
    }

    fileprivate func update(
        _ content: Content,
        configuration: ControllerContainerConfiguration,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = configuration.safeAreaInsets.toUIEdgeInsets(layoutDirection: environment.layoutDirection)
        update(content, environment: environment, transaction: transaction)
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            PreviewA()
        }
        ZStack {
            PreviewB()
        }
    }

    struct PreviewA: View {
        @State var isNavigationBarHidden = false

        var body: some View {
            NavigationContainer {
                VStack {
                    Toggle(isOn: $isNavigationBarHidden.animation()) {
                        Text("isNavigationBarHidden")
                    }

                    DestinationLink {
                        Text("Hello, World")
                    } label: {
                        Text("Next")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue.opacity(0.3))
                .background(Color.blue.opacity(0.3).ignoresSafeArea())
                .navigationTitle("Title")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {

                        } label: {
                            Text("Button")
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button {

                        } label: {
                            Text("Button")
                        }
                    }
                }
            }
        }
    }

    struct PreviewB: View {
        class Controller<Content: View>: NavigationContainerController<Content> {
            override func viewDidLoad() {
                super.viewDidLoad()
                view.backgroundColor = .red
            }
        }

        var body: some View {
            NavigationContainer(Controller.self) {
                Text("Hello, World")
            }
        }
    }
}

#endif
