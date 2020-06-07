//
//  Constants.swift
//  NewsArticleClientByDO
//
//  Created by  Dmitry Ondrin on 25/04/2020.
//  Copyright © 2020  Dmitry Ondrin. All rights reserved.
//

import UIKit

/// Constants, configs and calculations
struct Constants {
    //MARK:- Config
    
    // Notifications
    
    static let appWillEnterForegroundNotification = Notification.Name("app-will-enter-forground")
    static let appWillEnterBackgroundNotification = Notification.Name("app-will-enter-background")
    
    // Keys
    static let encryptedDataKey = "encryptedData"
    static let signatureKey = "signature"
    static let senderKeys = "senderKeys"
    static let receivedKeys = "receivedKeys"
    static let timestampFormat = "HH:mm:ss.SSS"//"yyyy-MM-dd HH:mm:ss.SSS"
    
    // Strings
    static let biometricsOn = "Biometrics ON"
    static let biometricsOff = "Biometrics OFF"
    static let cancel = "Cancel."
    static let authenticateFailureTitle = "Could not authenticate."
    static let authenticateFailureMessage = "Please try again."
    static let authenticateMessage = "Authentication is required to read the message."
    static let authenticateTitle = "Please Authenticate."
    static let decryptionVCTitle = "Decrypted Message"
    static let dataNotificationIdentifier = "OpenIncomingMessegeNotification"
    static let reportEncryptionFailure: String = "Encryption failed. Please, try again."
    static let reportEncryptionComplete: String = "Encryption complete. Please background the app."
    static let notificationTitle: String = "Title of notification"
    static let notificationBody: String = "Notification body"
    static let badNewsOkButtonTitles: [String] =
        ["Just perfect!!! #$%^& >:/",
         "Great, thanks... :/",
         "WTF is this app??!",
         "You deserve negative score.",
         "Rage quit!",
         "Y u no work??!"]
    
    // Numbers
    static let timeBeforeNotification: Double = 1.5
//    static let typewriterDelay: Double = 0.05
    static let typewriterSpeed: Double = 50
    
    // Colors
    static let enabledButtonColor: UIColor = .systemBlue
    static let disabledButtonColor: UIColor = .systemGray
    
    //MARK:- Calculated
    
    static var delayBeforeDecrypting: DispatchTime {
        return .now() + 0.5
    }
}
