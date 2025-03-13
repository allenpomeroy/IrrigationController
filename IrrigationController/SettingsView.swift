//
//  SettingsView.swift
//  IrrigationController
//
//  Created by Allen Pomeroy on 2/27/25.
//


import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SwitchViewModel
    @Binding var isPresented: Bool
    @AppStorage("hasConfigured") private var hasConfigured: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server Settings")) {
                    TextField("Web Host", text: $viewModel.webHost)
                        .autocorrectionDisabled(true)
                    TextField("Username", text: $viewModel.username)
                        .autocorrectionDisabled(true)
                    SecureField("Password", text: $viewModel.password)
                }
                
                Section(header: Text("Switch Names")) {
                    ForEach(0..<viewModel.switches.count, id: \.self) { index in
                        TextField("Switch Name", text: $viewModel.switches[index].name)
                            .autocorrectionDisabled(true)
                    }
                }
            }
            .navigationTitle("Configuration")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Save all switch names at once.
                        for index in 0..<viewModel.switches.count {
                            let key = "switchName\(index)"
                            UserDefaults.standard.set(viewModel.switches[index].name, forKey: key)
                        }
                        if !viewModel.webHost.isEmpty && !viewModel.username.isEmpty && !viewModel.password.isEmpty {
                            hasConfigured = true
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
