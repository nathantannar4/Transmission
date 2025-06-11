//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Transmission

enum StatusBarStyle: CaseIterable, Hashable {
    case `default`
    case lightContent
    case darkContent

    func toUIKit() -> UIStatusBarStyle {
        switch self {
        case .default:
            return .default
        case .lightContent:
            return .lightContent
        case .darkContent:
            return .darkContent
        }
    }
}

struct StatusBarAppearanceExamples: View {

    @State var isStatusBarHidden = false
    @State var statusBarStyle: StatusBarStyle = .default

    var body: some View {
        Toggle(isOn: $isStatusBarHidden) {
            Text("Prefers Status Bar Hidden")
        }
        .prefersStatusBarHidden(isStatusBarHidden)

        HStack {
            Text("Status Bar Style")
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker(selection: $statusBarStyle) {
                ForEach(StatusBarStyle.allCases, id: \.self) { style in
                    Text(verbatim: "\(style)")
                }
            } label: {
                Text("Status Bar Style")
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .preferredStatusBarStyle(statusBarStyle.toUIKit())
    }
}

#Preview {
    StatusBarAppearanceExamples()
}
