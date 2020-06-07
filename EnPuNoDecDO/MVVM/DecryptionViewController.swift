//
//  DecryptionViewController.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 05/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import UIKit
import LocalAuthentication

/// Responsible for displaying decrypted message.
class DecryptionViewController: UIViewController {
    /// Displays the decrypted message
    @IBOutlet weak var mainTextView: UITextView!
    /// Debug text view
    @IBOutlet weak var debugTextView: AnimatedTextView!
    
    /// View model of the VC
    var viewModel: DecryptionViewModel? {
        didSet {
            if isViewLoaded {
                updateViews()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = Constants.decryptionVCTitle
        
        setupDebugTextView()
        
        updateViews()
        
        decideAuthentication()
    }
    
    /// Will display biometrics authentication request if it's enabled, otherwise will continue straight to decryption.
    private func decideAuthentication() {
        guard let viewModel = viewModel else { return }
        if viewModel.shouldUseBiometrics {
            authenticationWithTouchID()
        } else {
            onAuthenticationSuccess()
        }
    }
    
    /// Updates all views
    func updateViews() {
        updateMainTextField()
        updateDebugTextView()
    }
    
    private func updateMainTextField() {
        guard let viewModel = viewModel else { return }
        mainTextView.text = viewModel.decryptedMessage
    }
    
    private func updateDebugTextView() {
        debugTextView.viewModel = viewModel?.debugTextViewModel
        viewModel?.sendMoreDebugs()
    }
    
    /// Debug text view initial setup
    private func setupDebugTextView() {
        debugTextView.animationDelegate = self
    }
    
    /// Process authentication success
    private func onAuthenticationSuccess() {
        viewModel?.userDidAuthenticate()
        updateMainTextField()
    }
    
    /// Process authentication failure
    private func onAuthenticationFailure(error: Error?) {
        // Failed to authenticate
        guard let error = error else {
            return
        }
        let alert = UIAlertController(
            title: Constants.authenticateFailureTitle,
            message: "\(error.localizedDescription) \(Constants.authenticateFailureMessage)",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: Constants.badNewsOkButtonTitles.randomElement(),
            style: .default,
            handler: { [weak self] action in
                self?.authenticationWithTouchID()
        }))
        alert.addAction(UIAlertAction(title: Constants.cancel, style: .cancel, handler: { [weak self] action in
            self?.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Display authentication request
    private func authenticationWithTouchID() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = Constants.authenticateTitle

        var authorizationError: NSError?
        let reason = Constants.authenticateMessage

        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authorizationError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: Constants.delayBeforeDecrypting, execute: { [weak self] in
                        self?.onAuthenticationSuccess()
                    })
                } else {
                    DispatchQueue.main.async() { [weak self] in
                        self?.onAuthenticationFailure(error: error)
                    }
                }
            }
        } else {
            guard let error = authorizationError else {
                return
            }
            print(error)
        }
    }
}

//MARK:- AnimatedTextViewDelegate

extension DecryptionViewController: AnimatedTextViewDelegate {
    func animatedTextViewDidFinishAnimating(_ animatexTextView: AnimatedTextView) {
        viewModel?.sendMoreDebugs()
    }
}
