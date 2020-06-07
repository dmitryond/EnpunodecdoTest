//
//  NotificationsManager.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 05/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import NotificationCenter

/// Responsible for managing local notifications
class NotificationsManager: NSObject {
    
    static var shared = NotificationsManager()
    
    //MARK:- Parameters
    
    weak var delegate: NotificationsManagerDelegate?
    
    // Notification-specific properties
    private lazy var notificationCenter =   UNUserNotificationCenter.current()
    private lazy var trigger =              UNTimeIntervalNotificationTrigger(timeInterval: Constants.timeBeforeNotification, repeats: false)
    
    /// Request to send as local notification when the app will go to background
    private var pendingRequest: UNNotificationRequest?
    
    /// True when pendingRequest has already been sent
    private var isSendingRequest: Bool = false
    
    /// Can be used to check whether the request is ready
    var isRequestReady: Bool {
        return pendingRequest != nil || isSendingRequest
    }
    
    //MARK:- Methods
    
    /// Init is private to ensure only one shared singleton
    private override init() {
        super.init()
        registerForEnterBackgroundNotification()
//        registerForEnterForegroundNotification()
    }
    
    deinit {
        unregisterFromNotifications()
    }
    
    /// Called publicly to prepare a notification for the next time app is backgrounded
    func prepareNotification(with encryptedData: Data, and signature: Data) {
        let content = getNotificationContent(with: encryptedData, and: signature)
        let request = UNNotificationRequest(identifier: Constants.dataNotificationIdentifier, content: content, trigger: trigger)
        pendingRequest = request
    }
    
    //MARK: Private
    
    /// Creates content for notification.
    private func getNotificationContent(with encryptedData: Data, and signature: Data) -> UNMutableNotificationContent {
        let result = UNMutableNotificationContent()
        result.title = Constants.notificationTitle
        result.body = Constants.notificationBody
        result.sound = .default
        result.userInfo = [Constants.encryptedDataKey: encryptedData,
                           Constants.signatureKey: signature]
        return result
    }
    
    /// Sends notification. Called when backgrounding.
    private func sendNotification() {
        guard !isSendingRequest
            , let pendingRequest = pendingRequest else { return }
        isSendingRequest = true
        notificationCenter.add(pendingRequest) { error in
            if error != nil {
                print("Error: \(error?.localizedDescription ?? "" )")
            }
        }
    }
    
//    private func registerForEnterForegroundNotification() {
//        NotificationCenter.default.addObserver(forName: Constants.appWillEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
//            self?.onActive()
//        }
//        print("Notification center added \(type(of: self)) as observer for enter foreground.")
//    }
    
    private func registerForEnterBackgroundNotification() {
        NotificationCenter.default.addObserver(forName: Constants.appWillEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.onInactive()
        }
        print("Notification center added \(type(of: self)) as observer for enter background.")
    }
    
//    private func unregisterFromEnterForegroundNotification() {
//        NotificationCenter.default.removeObserver(self, name: Constants.appWillEnterForegroundNotification, object: nil)
//        print("Notification center removed \(type(of: self)) as observer for enter foreground.")
//    }
    
    private func unregisterFromEnterBackgroundNotification() {
        NotificationCenter.default.removeObserver(self, name: Constants.appWillEnterBackgroundNotification, object: nil)
        print("Notification center removed \(type(of: self)) as observer for enter background.")
    }
    
    private func unregisterFromNotifications() {
//        unregisterFromEnterForegroundNotification()
        unregisterFromEnterBackgroundNotification()
    }
    
//    private func onActive() {
//        print("Entered foreground")
//    }
    
    /// Called when backgrounded
    private func onInactive() {
        print("Entered background")
        sendNotification()
    }
    
    /// Called when notification tapped and app opens.
    func processIncomingMessage(with info: [AnyHashable : Any]) {
        guard let encryptedDataAny = info[Constants.encryptedDataKey],
            let signatureAny = info[Constants.signatureKey],
            let encryptedData = encryptedDataAny as? Data,
            let signature = signatureAny as? Data
            else {
                return
        }
        pendingRequest = nil
        isSendingRequest = false
        delegate?.notificationsManagerDidRecieveMessage(EncryptedMessage(encryptedData: encryptedData, signature: signature))
//        EncryptionManager.shared.process(encryptedMessage: EncryptedMessage(encryptedData: encryptedData, signature: signature))
    }
}

//MARK:- UNUserNotificationCenterDelegate

extension NotificationsManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == Constants.dataNotificationIdentifier {
            processIncomingMessage(with: response.notification.request.content.userInfo)
        }
        completionHandler()
    }
}

protocol NotificationsManagerDelegate: class {
    func notificationsManagerDidRecieveMessage(_ message: EncryptedMessage)
}
