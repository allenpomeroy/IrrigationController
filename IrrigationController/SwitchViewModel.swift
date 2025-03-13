//
//  Untitled.swift
//  IrrigationController
//
//  Created by Allen Pomeroy on 2/27/25.
//

import Foundation
import SwiftUI
import Combine

class SwitchViewModel: ObservableObject {
    @Published var switches: [DeviceSwitch] = []

    @AppStorage("webHost") var webHost: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("password") var password: String = ""

    // Single status string for the entire group
    @Published var connectionStatus: String = "Not connected"

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        let delegate = SelfSignedURLSessionDelegate()
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        // Load switch names from UserDefaults or use defaults.
        let defaultNames = ["Switch 1", "Switch 2", "Switch 3", "Switch 4"]
        for i in 0..<defaultNames.count {
            let key = "switchName\(i)"
            let name = UserDefaults.standard.string(forKey: key) ?? defaultNames[i]
            switches.append(DeviceSwitch(name: name))
        }
    }

    // Build the URL for a given switch and action.
    private func buildURL(for device: DeviceSwitch, action: String) -> URL? {
        // The device.name and "relay" on the server must match for statuses to line up
        let urlString = "https://\(webHost)/powercontroller.py?switch=\(device.name)&action=\(action)"
        return URL(string: urlString)
    }

    // Basic Auth header
    private func basicAuthHeader() -> String? {
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else { return nil }
        return "Basic \(loginData.base64EncodedString())"
    }

    // Send a command ("on" or "off") to the webserver
    func sendCommand(for device: DeviceSwitch, action: String) {
        guard let url = buildURL(for: device, action: action) else { return }

        var request = URLRequest(url: url)
        if let authHeader = basicAuthHeader() {
            request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    device.errorMessage = error.localizedDescription
                    
                    // Distinguish between a timeout vs. other errors
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        self.connectionStatus = "Not connected"
                    } else {
                        self.connectionStatus = "Error"
                    }
                    
                    print("Error sending command for \(device.name): \(error.localizedDescription)")
                } else {
                    // If we got data back, parse it and assume success => "Connected"
                    if let data = data {
                        self.parseResponse(data: data, for: device)
                        self.connectionStatus = "Connected"
                    }
                }
            }
        }
        task.resume()
    }

    // Fetch the current status for a given switch
    func fetchStatus(for device: DeviceSwitch) {
        guard let url = buildURL(for: device, action: "status") else { return }

        var request = URLRequest(url: url)
        if let authHeader = basicAuthHeader() {
            request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    device.errorMessage = error.localizedDescription
                    
                    // Check for timeout vs. other errors
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        self.connectionStatus = "Not connected"
                    } else {
                        self.connectionStatus = "Error"
                    }
                    
                    print("Error fetching status for \(device.name): \(error.localizedDescription)")
                } else {
                    // If no error, assume "Connected"
                    if let data = data {
                        self.parseResponse(data: data, for: device)
                        self.connectionStatus = "Connected"
                    }
                }
            }
        }
        task.resume()
    }

    // Parse JSON and update device.isOn
    private func parseResponse(data: Data, for device: DeviceSwitch) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
               let relay  = json["relay"],
               let status = json["status"] {

                let normalizedRelay  = relay.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let normalizedStatus = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                // If the server's "relay" name matches device name, update toggle
                if normalizedRelay == device.name.lowercased() {
                    device.isOn = (normalizedStatus == "on")
                    print("Updated \(device.name) to \(device.isOn) (status: \(normalizedStatus))")
                } else {
                    print("Warning: Relay '\(relay)' does not match device name '\(device.name)'")
                }
            } else {
                print("Unexpected JSON structure: \(String(data: data, encoding: .utf8) ?? "nil")")
            }
        } catch {
            print("Error parsing JSON for \(device.name): \(error)")
        }
    }

    // Refresh all statuses
    func refreshAllStatuses() {
        // On each fetch, the "last" fetch result will set connectionStatus
        for device in switches {
            fetchStatus(for: device)
        }
    }
}
