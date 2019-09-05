//
//  PaddingLabel.swift
//  What's It
//
//  Created by Prabhunes on 8/17/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import UIKit

// Reference: https://stackoverflow.com/questions/27459746/adding-space-padding-to-a-uilabel
class PaddingLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 3.0
    @IBInspectable var leftInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}
