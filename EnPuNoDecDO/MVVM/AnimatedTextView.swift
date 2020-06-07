//
//  AnimatedTextView.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import UIKit

/// Text View that animates output.
class AnimatedTextView: UITextView {
    /// Receives callback when animation ended
    weak var animationDelegate: AnimatedTextViewDelegate?
    /// View model of the view
    var viewModel: AnimatedTextViewModel? {
        didSet {
            viewModel?.updateAction = { [weak self] in
                self?.updateView()
            }
            viewModel?.onTextAddAction = { [weak self] textToAdd in
                self?.addText(textToAdd)
            }
            viewModel?.stopAnimations()
            updateView()
        }
    }
    
    func setup(with viewModel: AnimatedTextViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateView() {
        text = viewModel?.textViewText
    }
    
    private func addText(_ textToAdd: String) {
        if window == nil {
            viewModel?.stopAnimations()
            return
        }
        text += textToAdd
        guard let viewModel = viewModel else { return }
        if !viewModel.isAnimating {
            animationDelegate?.animatedTextViewDidFinishAnimating(self)
        }
    }
}
