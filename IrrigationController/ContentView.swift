//
//  ContentView.swift
//  IrrigationController
//
//  Created by Allen Pomeroy on 2/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = SwitchViewModel()
    @State private var showingSettings = false
    @AppStorage("hasConfigured") private var hasConfigured: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    // Timer that fires every 15 seconds
    private let refreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    // Dynamically grab the app version from Info.plist. This should match the "CFBundleShortVersionString"
    // you have set in Xcode’s target settings (e.g. "1.0").
    private let appVersion: String = {
        let infoDict = Bundle.main.infoDictionary
        let shortVersion = infoDict?["CFBundleShortVersionString"] as? String ?? "N/A"
        let buildNumber = infoDict?["CFBundleVersion"] as? String ?? "N/A"
        return "\(shortVersion) (\(buildNumber))"
    }()

    var body: some View {
        NavigationStack {
            VStack {
                // The list of switches
                ForEach($viewModel.switches) { $device in
                    Toggle(isOn: $device.isOn) {
                        HStack {
                            Circle()
                                .fill(device.isOn ? Color.green : Color.gray.opacity(0.4))
                                .frame(width: 12, height: 12)
                            Text(device.name)
                                .font(.headline)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding()
                    .background(device.isOn ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onChange(of: device.isOn) { newValue in
                        let action = newValue ? "on" : "off"
                        viewModel.sendCommand(for: device, action: action)
                    }
                }
                
                // Single connection status for the entire group
                Text(viewModel.connectionStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // Display app version below the status
                Text("Version \(appVersion)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer()
            }
            .navigationTitle("Water Controller")
            .toolbar {
                Button("Settings") {
                    showingSettings = true
                }
            }
            .onAppear {
                if !hasConfigured {
                    showingSettings = true
                }
                viewModel.refreshAllStatuses()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.refreshAllStatuses()
                }
            }
            .onReceive(refreshTimer) { _ in
                viewModel.refreshAllStatuses()
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel, isPresented: $showingSettings)
            }
            #else
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel, isPresented: $showingSettings)
            }
            #endif
        }
    }
}
