//
//  EncryptionManager.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 03/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import Security
import CommonCrypto
import Foundation

/// Responsible for encrypting/signing/verifying/decrypting data
class EncryptionManager {
    
    //MARK: Private classes

    struct KeyPair {
        var publicKey: SecKey
        var privateKey: SecKey
    }
    
    /// Singleton
    static var shared = EncryptionManager()
    
    //MARK:- Properties
    
    /// Receives reports of encryption/decryption progress and decryption success callback
    weak var delegate: EncryptionManagerDelegate?
    
    /// Sender keys are used to sign and verify data
    lazy private var senderKeyPair: KeyPair? = {
        return getSenderKeys()//EncryptionManager.generateKeys()
    }()
    
    /// Receiver keys are used to encrypt and decrypt data
    lazy private var receiverKeyPair: KeyPair? = {
        return getReceiverKeys()//EncryptionManager.generateKeys()
    }()
    
    //MARK:- Methods
    
    /// Init is private to ensure only one shared singleton
    private init() {
    }
    
    /// Returns true if successfully encrypted data.
    func tryPrepareEncryptedData(of stringToEncrypt: String) -> Bool {
        guard let data = stringToEncrypt.data(using: .utf8) else { return false }
        guard let encryptedData = encrypt(data: data) else {
            return false
        }
        guard let signature = getSignature(with: encryptedData) else { return false }
        NotificationsManager.shared.prepareNotification(with: encryptedData, and: signature)
        return true
    }
    
    /// Called to process received data
    func process(encryptedMessage: EncryptedMessage) {
        let isVerified = verify(signature: encryptedMessage.signature, on: encryptedMessage.encryptedData)
        if !isVerified {
            return
        }
        guard let decryptedData = decrypt(encryptedData: encryptedMessage.encryptedData) else {
            return
        }
        guard let decryptedMessage = String(data: decryptedData, encoding: .utf8) else {
            report("Message corrupted, can't make a string.")
            return
        }
        delegate?.encryptionManager(self, didDecryptMessage: decryptedMessage)
    }
    
    //MARK: Private
    
    /// Creates CFData from encrypted data for signature. Same process is used during verification.
    private func getDataToSign(from encryptedData: Data) -> CFData? {
        let signedDataLength = Int(CC_SHA256_DIGEST_LENGTH)
        var bytes: [UInt8] = [UInt8](repeating: 0, count: signedDataLength)
        encryptedData.copyBytes(to: &bytes, count: signedDataLength)
        
        guard let dataToSign = CFDataCreate(kCFAllocatorDefault, bytes, signedDataLength) else {
            return nil
        }
        return dataToSign
    }
    
    /// Creates a signature of an enrypted data.
    private func getSignature(with encryptedData: Data) -> Data? {
        var debugString = "Signing successfull."
        defer {
            print(debugString)
            report(debugString)
        }
        guard let keyPair = senderKeyPair else {
            debugString = "Sender key pair is missing."
            return nil
        }
        
        // Prepare encryption variables
        let senderPrivateKey = keyPair.privateKey
        
        let algorithm: SecKeyAlgorithm = .rsaSignatureDigestPKCS1v15SHA256
        guard SecKeyIsAlgorithmSupported(senderPrivateKey, .sign, algorithm) else {
            debugString = "Signing algorythm is not supported"
            return nil
        }
        
        guard let dataToSign = getDataToSign(from: encryptedData) else {
            debugString = "Couldn't create CFData from encrypted data."
            return nil
        }
        
        var error: Unmanaged<CFError>?
        
        guard let signature = SecKeyCreateSignature(senderPrivateKey, algorithm, dataToSign, &error) as Data? else {
            debugString = "Couldn't create signature. Error: \(error.debugDescription)"
            return nil
        }
        return signature
    }
    
    /// Encrypts data.
    private func encrypt(data: Data) -> Data? {
        var debugString = "Encryption successfull."
        defer {
            print(debugString)
            report(debugString)
        }
        guard let keyPair = receiverKeyPair else {
            debugString = "Receiver key pair is missing."
            return nil
        }
        
        // Prepare mutual encryption variables
        let recieverPublicKey = keyPair.publicKey
        
        let keySize = SecKeyGetBlockSize(recieverPublicKey)
        let sizeOfChunk = keySize - 11

        // Prepare chunked data array
        let countOfDataArray = data.count / MemoryLayout<UInt8>.size
        var dataArray: [UInt8] = [UInt8](repeating: 0, count: countOfDataArray)
        data.copyBytes(to: &dataArray, count: data.count) //<--O(data.count)
        
        // Prepare to loop through and encrypt chunks of data
        var encryptedData: [UInt8] = []
        var startPoint = 0
        while startPoint < dataArray.count { //<--O(data.count + dataArray.count)
            var endPoint = startPoint + sizeOfChunk
            if ( endPoint > dataArray.count ) {
                endPoint = dataArray.count
            }
            
            // Prepare chunk of data
            var chunkOfData: [UInt8] = [UInt8](repeating: 0, count: sizeOfChunk)
            for i in startPoint..<endPoint { //<--O(data.count + (dataArray.count * (endPoint - startPoint - 1)))
                chunkOfData[i - startPoint] = dataArray[i]
            }
            let currentData: CFData = CFDataCreate(kCFAllocatorDefault, chunkOfData, sizeOfChunk)
            
            
            var error: Unmanaged<CFError>?
            guard let cipherText = SecKeyCreateEncryptedData(recieverPublicKey, .rsaEncryptionPKCS1, currentData as CFData, &error) else {
                debugString = "Encryption error: \(error.debugDescription)"
                return nil
            }
            encryptedData += cipherText as Data
            startPoint += sizeOfChunk
        }
        let result = Data(bytes: encryptedData, count: encryptedData.count)
        return result
    }
    
    /// Decrypts data.
    private func decrypt(encryptedData: Data) -> Data? {
        var debugString = "Decryption failed."
        defer {
            print(debugString)
            report(debugString)
        }
        
        // Prepare mutual decryption variables
        guard let receiverPrivateKey = receiverKeyPair?.privateKey else {
            return nil
        }
        
        let sizeOfChunk = 128

        // Prepare chunked data array
        let countOfDataArray = encryptedData.count / MemoryLayout<UInt8>.size
        var dataArray: [UInt8] = [UInt8](repeating: 0, count: countOfDataArray)
        encryptedData.copyBytes(to: &dataArray, count: encryptedData.count) //<--O(data.count)
        
        let algorythm: SecKeyAlgorithm = .rsaEncryptionPKCS1
        
        // Prepare to loop through and encrypt chunks of data
        var decryptedData: [UInt8] = []
        var startPoint = 0
        while startPoint < dataArray.count { //<--O(data.count + dataArray.count)
            var endPoint = startPoint + sizeOfChunk
            if ( endPoint > dataArray.count ) {
                endPoint = dataArray.count
            }
            
            // Prepare chunk of data
            var chunkOfData: [UInt8] = [UInt8](repeating: 0, count: sizeOfChunk)
            for i in startPoint..<endPoint { //<--O(data.count + (dataArray.count * (endPoint - startPoint - 1)))
                chunkOfData[i - startPoint] = dataArray[i]
            }
            let cipherText: CFData = CFDataCreate(kCFAllocatorDefault, chunkOfData, sizeOfChunk)
            
            
            var error: Unmanaged<CFError>?
            guard let clearText: CFData = SecKeyCreateDecryptedData(receiverPrivateKey, algorythm, cipherText, &error) else {
                debugString += " " + (error!.takeRetainedValue() as Error).localizedDescription
                return nil
            }
            decryptedData += clearText as Data
            startPoint += sizeOfChunk
        }
        let result = Data(bytes: decryptedData, count: decryptedData.count)
        debugString = "Decryption successful."
        return result
    }
    
    /// Verifies signature of the received encrypted data.
    private func verify(signature: Data, on encryptedData: Data) -> Bool {
        var debugString = "Signature verification failed."
        defer {
            print(debugString)
            report(debugString)
        }
        
        guard let key = senderKeyPair?.publicKey else {
            return false
        }
        
        let algorythm: SecKeyAlgorithm = .rsaSignatureDigestPKCS1v15SHA256
        
        guard let signedData = getDataToSign(from: encryptedData) else { return false }
        
        var error: Unmanaged<CFError>?
        guard SecKeyVerifySignature(key, algorythm, signedData, signature as CFData, &error) else {
            debugString += " " + (error!.takeRetainedValue() as Error).localizedDescription
            return false
        }
        debugString = "Signature verified successfully."
        return true
    }
    
    /// Sends report to the delegate
    private func report(_ report: String) {
        delegate?.encryptionManager(self, report: report)
    }
    
    private func getSenderKeys() -> KeyPair? {
        return getKeys(forSender: true)
    }
    
    private func getReceiverKeys() -> KeyPair? {
        return getKeys(forSender: false)
    }
    
    private func getKeys(forSender isSender: Bool) -> KeyPair? {
        let senderReceiverDebugString = isSender ? "sender" : "receiver"
        let tag = isSender ? Constants.senderKeys : Constants.receivedKeys
        var debugString = "Loaded \(senderReceiverDebugString) keys from keychain."
        defer {
            print(debugString)
            report(debugString)
        }
        if let keys = getKeysFromKeychain(for: tag) {
            return keys
        }
        guard let newKeys = EncryptionManager.generateKeys() else {
            debugString = "Couldn't create \(senderReceiverDebugString) keys."
            return nil
        }
        debugString = trySaveKeys(newKeys, with: tag) ? "Created and saved new \(senderReceiverDebugString) keys on keychain." : "Couldn't save \(senderReceiverDebugString) keys on keychain."
        return newKeys
    }
    
    private func trySaveKeys(_ keys: KeyPair, with tag: String) -> Bool {
        return trySave(key: keys.privateKey, with: "private" + tag)
            && trySave(key: keys.publicKey, with: "public" + tag)
    }
    
    private func trySave(key: SecKey, with tag: String) -> Bool {
        let tag = tag.data(using: .utf8)!
        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecValueRef as String: key]
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { return false }
        return true
    }
    
    private func getKeysFromKeychain(for tag: String) -> KeyPair? {
        guard let publicKey = getKeyFromKeychain(forTag: "public" + tag)
            , let privateKey = getKeyFromKeychain(forTag: "private" + tag) else {
                return nil
        }
        return KeyPair(
            publicKey: publicKey,
            privateKey: privateKey)
    }
    private func getKeyFromKeychain(forTag tag: String) -> SecKey? {
        let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as! SecKey
    }
    
    /// Generates a random RSA 1024b key pair.
    private static func generateKeys() -> KeyPair? {
        var debug = "Unknown error."
        defer {
            print(debug)
        }
        let publicAttrs: [CFString : Any] = [
            kSecAttrIsPermanent :       true,
            kSecAttrApplicationTag :    "tag1".data(using: .utf8)!
        ]
        
        let privateAttrs: [CFString : Any] = [
            kSecAttrIsPermanent :       true,
            kSecAttrApplicationTag :    "tag0".data(using: .utf8)!
        ]
        
        let params: CFDictionary = [
            kSecAttrKeyType :       kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits : 1024,
            kSecPublicKeyAttrs :    publicAttrs,
            kSecPrivateKeyAttrs :   privateAttrs
            ] as CFDictionary
        
        var privateKey: SecKey?
        var publicKey: SecKey?
        let status  = SecKeyGeneratePair(params, &publicKey, &privateKey)
        
        guard status == noErr, let goodPublicKey = publicKey, let goodPrivateKey = privateKey else {
            debug = "\(status.description)"
            return nil
        }
        debug = "Private: \(goodPrivateKey),\npublic: \(goodPublicKey)"
        return KeyPair(publicKey: goodPublicKey, privateKey: goodPrivateKey)
    }
}
