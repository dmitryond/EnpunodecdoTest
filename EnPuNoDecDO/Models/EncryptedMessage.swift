//
//  EncryptedMessage.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import Foundation

/// Message structure to send in a notification.
struct EncryptedMessage {
    var encryptedData: Data
    var signature: Data
}
