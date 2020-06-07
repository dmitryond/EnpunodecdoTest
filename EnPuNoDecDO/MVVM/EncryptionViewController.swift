//
//  EncryptionViewController.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 03/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import UIKit

/// Displays text field for input, button and the text view for debug reports
class EncryptionViewController: UIViewController {
    /// Input field
    @IBOutlet weak var mainTextField: UITextField!
    /// Debug text view
    @IBOutlet weak var debugTextView: AnimatedTextView!
    /// Button that sends input to Encryption Manager for encryption
    @IBOutlet weak var sendButton: UIButton!
    /// View model of the VC
    @IBOutlet weak var biometricsButton: UIBarButtonItem!
    var viewModel: EncryptionViewModel? {
        didSet {
            updateViews()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViews()
    }
    
    private func setup() {
        setupViewModel()
        setupDebugTextView()
    }
    
    /// View model set up happens here since this is the initial app VC
    private func setupViewModel() {
        viewModel = EncryptionViewModel(onDecryptAction: { [weak self] decryptionVM in
            self?.displayDecryptionVC(with: decryptionVM)
        })
    }
    
    /// Debug text view initial setup
    private func setupDebugTextView() {
        debugTextView.animationDelegate = self
    }
    
    /// Pushes the decryption result VC with an appropriate view model
    private func displayDecryptionVC(with decryptionVM: DecryptionViewModel) {
        guard let viewModel = viewModel else { return }
        if viewModel.shouldDisplayDecryptedMessage == false {
            return
        }
        let vc = DecryptionViewController.initialViewControllerFromStoryboard() as! DecryptionViewController
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
            vc.viewModel = decryptionVM
        }
    }
    
    /// Called when biometrics button taps
    @IBAction func biometricsButtonDidTap(_ sender: Any) {
        viewModel?.userDidToggleBiometrics()
        updateBiometricsButton()
    }
    
    /// Called when user inputs text
    @IBAction func mainTextViewDidChange() {
        guard let viewModel = viewModel
            , let text = mainTextField.text else {
                return
        }
        viewModel.userDidChangeInput(text)
        updateSendButton()
    }
    
    /// Called on button tap
    @IBAction func sendButtonDidTap(_ sender: UIButton) {
        viewModel?.userDidSend(mainTextField?.text ?? "")
        mainTextField.resignFirstResponder()
        updateMainTextField()
        updateSendButton()
    }
    
    /// Updates all subviews according to view model
    private func updateViews() {
        updateMainTextField()
        updateSendButton()
        updateDebugTextView()
        updateBiometricsButton()
    }
    
    private func updateMainTextField() {
        guard let viewModel = viewModel else { return }
        mainTextField.text = viewModel.userInputText
        mainTextField.isEnabled = viewModel.isUserInputEnabled
    }
    
    private func updateDebugTextView() {
        debugTextView.viewModel = viewModel?.debugTextViewModel
        viewModel?.sendMoreDebugs()
    }
    
    private func updateSendButton() {
        let enabled = viewModel?.isSendButtonEnabled ?? false
        sendButton.isEnabled = enabled
        sendButton.backgroundColor = enabled ? Constants.enabledButtonColor : Constants.disabledButtonColor
    }
    
    private func updateBiometricsButton() {
        biometricsButton.title = viewModel?.biometricsButtonTitle
    }
}

//MARK:- AnimatedTextViewDelegate

extension EncryptionViewController: AnimatedTextViewDelegate {
    func animatedTextViewDidFinishAnimating(_ animatexTextView: AnimatedTextView) {
        viewModel?.sendMoreDebugs()
    }
}
