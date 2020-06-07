//
//  EncryptionManagerDelegate.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

/// Receives reports of encryption/decryption progress and decryption success callback
protocol EncryptionManagerDelegate: class {
    func encryptionManager(_ encryptionManager: EncryptionManager, report: String)
    func encryptionManager(_ encryptionManager: EncryptionManager, didDecryptMessage decryptedMessage: String)
}
