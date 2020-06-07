//
//  EncryptionViewModel.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 03/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

enum EncryptionViewState {
    case pending
    case processing
    case doneDecrypting
}

/// Responsible for feeding data to VC and displaying debug reports from Encryption Manager
class EncryptionViewModel {
    
    //MARK:- Properties
    
    // Data properties
    private var debugOutput: String = ""
    private var userInput: String = ""
    private var state: EncryptionViewState = .pending
    private(set) var isBiometricsOn: Bool = true
    
    /// Action that VC will perform once decryption of incoming message has been completed
    private var onDecryptAction: ((DecryptionViewModel) -> Void)?
    
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
    
    //MARK: Used by VC
    
    var userInputText: String {
        return userInput
    }
    
    var debugOutputText: String {
        return debugOutput
    }
    
    var isUserInputEnabled: Bool {
        return state == .pending
    }
    
    var isSendButtonEnabled: Bool {
        return isUserInputEnabled && !userInput.isEmpty
    }
    
    var shouldDisplayDecryptedMessage: Bool {
        return state == .doneDecrypting
    }
    
    var biometricsButtonTitle: String {
        return isBiometricsOn ? Constants.biometricsOn : Constants.biometricsOff
    }
    
    //MARK:- Methods
    
    init(onDecryptAction: ((DecryptionViewModel) -> Void)?) {
        self.onDecryptAction = onDecryptAction
        EncryptionManager.shared.delegate = self
        NotificationsManager.shared.delegate = self
    }
    
    /// Called by VC when input text changed
    func userDidChangeInput(_ newInput: String) {
        userInput = newInput
    }
    
    func userDidToggleBiometrics() {
        isBiometricsOn = !isBiometricsOn
    }
    
    /// Called by VC when user taps The Button
    func userDidSend(_ userInput: String) {
        EncryptionManager.shared.delegate = self
        self.userInput = userInput
        guard state == .pending
            , userInput.count > 0 else { return }
        state = .processing
        let encrypter = EncryptionManager.shared
//        encrypter.delegate = self
        // Encryption manager is taking over the flow at this point.
        // View Model is just listenning to reports
        if !encrypter.tryPrepareEncryptedData(of: userInput) {
            // What to do when fail to encrypt
            state = .pending
            return
        }
        add(report: Constants.reportEncryptionComplete)
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
    
    /// Display decrypted message
    private func onMessageArrived(encryptedMessage: EncryptedMessage) {
        state = .doneDecrypting
        let decryptionViewModel = DecryptionViewModel(encryptedMessage: encryptedMessage, shouldUseBiometrics: isBiometricsOn)
        onDecryptAction?(decryptionViewModel)
        userInput = ""
        state = .pending
    }
}

//MARK:- EncryptionManagerDelegate

extension EncryptionViewModel: EncryptionManagerDelegate {
    func encryptionManager(_ encryptionManager: EncryptionManager, report: String) {
        add(report: report)
    }
    
    func encryptionManager(_ encryptionManager: EncryptionManager, didDecryptMessage decryptedMessage: String) {
//        onMessageDecrypted(decryptedMessage: decryptedMessage)
    }
}

//MARK:- NotificationsManagerDelegate

extension EncryptionViewModel: NotificationsManagerDelegate {
    func notificationsManagerDidRecieveMessage(_ message: EncryptedMessage) {
        onMessageArrived(encryptedMessage: message)
    }
}
