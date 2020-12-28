//
//  NotificationHub.swift
//  Cheapiez
//
//  Created by Tianran Ding on 24/12/20.
//

import UIKit

class NotificationHub: ObservableObject {
    
    static let shared = NotificationHub()
    
    @Published private(set) var enableNotify: Bool?
    
    private init() {
        getCurrentNotifyStatus()
    }
    
    func toggleNotification() {
        if enableNotify == true {
            enableNotify = false
        } else {
            // Not set notification toggle yet or denied
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .notDetermined {
                    // not determined, start authorize process
                    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert]) { (granted, error) in
                        DispatchQueue.main.async {
                            if granted != true {
                                self.enableNotify = true
                            }
                        }
                    }
                } else if settings.authorizationStatus == .denied {
                    // already denied
                    // TODO: pop up
                } else {
                    // probably authorized
                    self.enableNotify = true
                }
            }
        }
    }
    
    private func getCurrentNotifyStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                // not determined...
            } else if settings.authorizationStatus == .denied {
                // already denied
                self.enableNotify = false
            } else {
                // probably authorized
                self.enableNotify = true
            }
        }
    }
}
