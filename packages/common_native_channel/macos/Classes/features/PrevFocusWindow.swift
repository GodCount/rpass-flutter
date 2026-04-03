//
//  PrevFocusWindow.swift
//  common_native_channel
//
//  Created by admin on 2026/4/3.
//

import Foundation
import FlutterMacOS

extension NSRunningApplication {
    var isCurrentApplication: Bool {
        return self.processIdentifier == ProcessInfo.processInfo.processIdentifier
    }
}

class PrevFocusWindow: NSObject, CommonFeaturesInterface {
    var methods: [String] = ["activate_prev_window"]
    
    var channel: FlutterMethodChannel
    
    private var prevActivedApplication: NSRunningApplication? = nil
    
    required init(channel: FlutterMethodChannel) {
        
        self.channel = channel;
        super.init()
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(notification:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    @objc func applicationDidActivate(notification: Notification) {
        if let userInfo = notification.userInfo,
           let application = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        {
            if !application.isCurrentApplication {
                self.prevActivedApplication = application
                let args = [
                    "name": application.localizedName
                ]
                self.channel.invokeMethod("prev_actived_window", arguments: args)
            }
        } else {
            self.prevActivedApplication = nil
            self.channel.invokeMethod("prev_actived_window", arguments: ["name": nil])
        }
    }
    
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methodName: String = call.method
        switch methodName {
        case "activate_prev_window":
            if let application = self.prevActivedApplication {
                if application.isActive {
                    return result(true)
                } else if !application.isTerminated {
                    return result(application.activate(options: .activateAllWindows))
                }
            }
            self.prevActivedApplication = nil
            result(false)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
}

