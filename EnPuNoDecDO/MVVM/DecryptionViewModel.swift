//
//  DecryptionViewModel.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 05/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import Foundation

/// View model of the decryption VC
class DecryptionViewModel {
    private var encryptedMessage: EncryptedMessage
    private(set) var decryptedMessage: String?
    private var debugOutput: String = ""
    private(set) var isLocked = true
    private(set) var shouldUseBiometrics = true
    
    /// Reports pool
    private var pendingReports = [EncryptionManagerReport]()
    /// True when report is being processed (animated or such). Set to false to send nex report for processing.
    private var isProcessingReport: Bool = false {
        didSet {
            if isProcessingReport == false {
                sendNextReport()
            }
        }
    }
    
    /// Animated text view model for displaying reports
    private(set) lazy var debugTextViewModel: AnimatedTextViewModel = AnimatedTextViewModel(animationSpeed: Constants.typewriterSpeed, text: debugOutput)
    
    
    init(encryptedMessage: EncryptedMessage, shouldUseBiometrics: Bool) {
        self.encryptedMessage = encryptedMessage
        self.shouldUseBiometrics = shouldUseBiometrics
    }
    
    func userDidAuthenticate() {
        isLocked = false
        let manager = EncryptionManager.shared
        manager.delegate = self
        let encryptedMessage = self.encryptedMessage
        manager.process(encryptedMessage: encryptedMessage)
        
    }
    
    private func onMessageDecrypted(decryptedMessage: String) {
        self.decryptedMessage = decryptedMessage
    }
    
    /// Request by VC for more debug reports.
    func sendMoreDebugs() {
        guard pendingReports.count > 0 else { return }
        pendingReports.remove(at: 0)
        isProcessingReport = false
    }
    
    /// Adds report from Encryption Manager callback
    private func add(report: String) {
        let processedReport = EncryptionManagerReport(content: report)
        pendingReports.append(processedReport)
        if isProcessingReport == false {
            sendNextReport()
        }
    }
    
    /// Sends next report to animated text view.
    private func sendNextReport() {
        guard pendingReports.count > 0 else { return }
        isProcessingReport = true
        let activeReport = pendingReports[0]
        var debugLine = "\(activeReport.timestamp): \(activeReport.content)"
        debugLine = debugOutput.isEmpty ? debugLine : "\n\(debugLine)"
        debugOutput += debugLine
        //debugUpdateAction?(debugLine)
        debugTextViewModel.animate(newText: debugLine, numberOfCharactersToSkip: Constants.timestampFormat.count)
    }
}

extension DecryptionViewModel: EncryptionManagerDelegate {
    func encryptionManager(_ encryptionManager: EncryptionManager, report: String) {
        add(report: report)
    }
    
    func encryptionManager(_ encryptionManager: EncryptionManager, didDecryptMessage decryptedMessage: String) {
        onMessageDecrypted(decryptedMessage: decryptedMessage)
    }
    
    
}
