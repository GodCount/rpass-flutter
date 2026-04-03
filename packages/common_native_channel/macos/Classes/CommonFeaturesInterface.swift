//
//  CommonFeaturesInterface.swift
//  common_native_channel
//
//  Created by admin on 2026/4/3.
//

import Foundation
import FlutterMacOS

protocol CommonFeaturesInterface: NSObject {
    var methods: [String] { get }

    var channel: FlutterMethodChannel { get }
    
    init(channel:FlutterMethodChannel)
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
    
}

