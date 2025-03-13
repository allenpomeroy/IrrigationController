//
//  DeviceSwitch.swift
//  IrrigationController
//
//  Created by Allen Pomeroy on 2/27/25.
//

import Foundation

class DeviceSwitch: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var isOn: Bool = false
    @Published var errorMessage: String? // To display network or SSL errors
    
    init(name: String, isOn: Bool = false) {
        self.name = name
        self.isOn = isOn
    }
}
