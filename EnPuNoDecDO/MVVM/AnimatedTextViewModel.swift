//
//  AnimatedTextViewModel.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import Foundation

/// View model of the animated text view
class AnimatedTextViewModel {
    
    //MARK:- Parameters
    
    /// Delay between adding each character.
    private var delay: TimeInterval
    
    /// Full text received so far.
    private var fullText: String
    
    /// Text still to output.
    private var pendingText: String = ""
    
    /// Forces to stop animation when the time comes to add next character.
    private var shouldStopAnimations = false
    
    /// True when text animation is in progress.
    private(set) var isAnimating: Bool = false
    
    /// This action performs when updating the view is necessary
    var updateAction: (() -> Void)?
    
    /// This action performs when text needs to be added
    var onTextAddAction: ((String) -> Void)?
    
    /// Used by VC
    var textViewText: String {
        return fullText
    }
    
    //MARK:- Methods
    
    /// Init for animated Text View Model
    /// - Parameter animationSpeed: Speed of text animation in characters per second
    init(animationSpeed: Double, text: String = "") {
        fullText = text
        delay = 1 / animationSpeed
    }
    
    /// Public call to animate some text
    func animate(newText: String, numberOfCharactersToSkip: Int = 0) {
        if newText.isEmpty {
            return
        }
        isAnimating = true
        fullText += newText
        if newText.count <= numberOfCharactersToSkip {
            onAnimationsEnd()
            return
        }
        let substringToSkip = newText.substring(to: numberOfCharactersToSkip)
        onTextAddAction?(substringToSkip)
        
        pendingText = newText.substring(from: numberOfCharactersToSkip)
        addNextCharacter()
    }
    
    /// Raise flag if animating
    func stopAnimations() {
        shouldStopAnimations = isAnimating
    }
    
    /// Runs action to add next character if should keep animating.
    private func addNextCharacter() {
        if shouldStopAnimations {
            onAnimationsEnd()
            updateAction?()
            return
        }
        if pendingText.isEmpty {
            onAnimationsEnd()
            return
        }
        let nextCharacter = pendingText.removeFirst()
        add(nextCharacter)
        let deadline: DispatchTime = .now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            self?.addNextCharacter()
        }
    }
    
    /// Adds character to the text view
    private func add(_ character: Character) {
        let string = String(character)
        onTextAddAction?(string)
        return
    }
    
    private func onAnimationsEnd() {
        pendingText = ""
        isAnimating = false
        shouldStopAnimations = false
        DispatchQueue.main.async {
            self.onTextAddAction?("")
        }
//        animationDelegate?.animatedTextViewDidFinishAnimating(self)
    }
}
