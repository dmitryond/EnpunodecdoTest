//
//  AnimatedTextViewDelegate.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 06/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

/// Receives callback when animation of text is complete
protocol AnimatedTextViewDelegate: class {
    func animatedTextViewDidFinishAnimating(_ animatexTextView: AnimatedTextView)
}
