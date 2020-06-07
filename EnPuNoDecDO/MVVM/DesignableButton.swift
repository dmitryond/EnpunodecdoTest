//
//  DesignableButton.swift
//  EnPuNoDecDO
//
//  Created by Dmitry Ondrin on 07/06/2020.
//  Copyright © 2020 Dmitry Ondrin. All rights reserved.
//

import UIKit

@IBDesignable class DesignableButton: UIButton {
        /// Inspactable corner radius for any UIView
        @IBInspectable var cornerRadius: CGFloat {
            get {
                return layer.cornerRadius
            }
            set {
                layer.cornerRadius = newValue
                if newValue > 0 {
                    layer.masksToBounds = true
                }
            }
        }
        
        override func awakeFromNib() {
            super.awakeFromNib()
        }
        override func prepareForInterfaceBuilder() {
            super.prepareForInterfaceBuilder()
        }
        override func updateConstraints() {
            super.updateConstraints()
        }
}
