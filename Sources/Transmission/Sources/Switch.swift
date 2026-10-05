//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine

@available(iOS 14.0, *)
public struct Switch: View {

    var isOn: Binding<Bool>

    public init(isOn: Binding<Bool>) {
        self.isOn = isOn
    }

    public var body: some View {
        SwitchBody(
            isOn: isOn
        )
        .accessibilityActivationPoint(.center)
        .accessibilityAddTraits({
            var traits: AccessibilityTraits = [.isButton]
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                traits.formUnion(.isToggle)
            }
            return traits
        }())
        .accessibilityAction {
            withAnimation {
                isOn.wrappedValue.toggle()
            }
        }
    }
}

@available(iOS 14.0, *)
private struct SwitchBody: UIViewRepresentable {

    var isOn: Binding<Bool>

    typealias UIViewType = SwitchPlatformView

    func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

        context.coordinator.isOn = isOn

        let tintColor = context.environment.foregroundColor?.toUIColor()
        let onTintColor = context.environment.tintColor?.toUIColor()
        uiView.tintColor = tintColor
        uiView.onTintColor = onTintColor

        let isOn = isOn.wrappedValue
        if uiView.isOn != isOn {
            uiView.setOn(isOn, animated: context.transaction.isAnimated)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: isOn)
    }

    class SwitchPlatformView: UISwitch {

        override func layoutSubviews() {
            super.layoutSubviews()
            updateBackgroundColor()
        }

        private func updateBackgroundColor() {
            guard let tintColor else { return }
            subviews.first?.subviews.first?.backgroundColor = tintColor
        }
    }

    @MainActor
    class Coordinator: NSObject {
        var isOn: Binding<Bool>

        init(isOn: Binding<Bool>) {
            self.isOn = isOn
        }

        @objc
        func valueChanged(_ sender: UISwitch) {
            let newValue = sender.isOn
            withAnimation {
                isOn.wrappedValue = newValue
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct Switch_Previews: PreviewProvider {

    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var isOn = false

        var body: some View {
            VStack {
                Switch(isOn: $isOn)

                Switch(isOn: !$isOn)

                Switch(isOn: $isOn)
                    .accentColor(.red)
                    .foregroundColor(.black)

                Switch(isOn: $isOn)
                    .accentColor(.red)

                if #available(iOS 15.0, *) {
                    Switch(isOn: $isOn)
                        .tint(.red)
                        .foregroundColor(.black)
                }

                Switch(isOn: !$isOn)
                    .accentColor(.red)
                    .foregroundColor(.black)
            }
        }
    }
}

#endif
