//
//  ProtocolsAndExtensions.swift
//  What's It
//
//  Created by Prabhunes on 8/3/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import UIKit

enum AppError: Error {
    case csvError(message: String), runtimeError(message: String)
}

// Reference: https://stackoverflow.com/questions/26913799/remove-println-for-release-version-ios-swift
func print(items: Any..., separator: String = " ", terminator: String = "\n") {

    #if DEBUG

    var idx = items.startIndex
    let endIdx = items.endIndex

    repeat {
        Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
        idx += 1
    }
        while idx < endIdx

    #endif
}

protocol UIViewControllerWithGradientLayer: class, CAAnimationDelegate {
    var gradientLayer: CAGradientLayer! {get set}
    var colorChangeAnimation: CABasicAnimation! {get set}
    var gradientTargetColors: [CGColor] {get set}
}

protocol SupportingScoreDisplay: class {
    var scoreLabel: UILabel! {get set}
}

protocol SupportingScoreUpdate: class {
    func updateCurrentScoreForTakingAGuess()
    func updateCurrentScoreForGettingAClue()
    func updateCurrentScoreForJustTellMeOption()
    func stopCurrentScoreUpdate()
}

extension UIViewControllerWithGradientLayer where Self: UIViewController {

    func createGradientLayer() {
        gradientLayer = CAGradientLayer()

        gradientLayer.frame = self.view.bounds

        // gradientLayer.colors = [UIColor.lightRandom.cgColor, UIColor.darkRandom.cgColor] // If 2nd color is dark
        gradientLayer.colors = [UIColor.lightRandom.cgColor, UIColor.random.cgColor]
        gradientLayer.startPoint = .randomTopQuarter
        gradientLayer.endPoint = .randomBottomQuarter

        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func animateGradientLayer() {
        gradientTargetColors = [UIColor.lightRandom.cgColor, UIColor.darkRandom.cgColor]

        colorChangeAnimation = CABasicAnimation(keyPath: colorChangeAnimationKeyPath)
        colorChangeAnimation.duration = colorChangeAnimationDuration
        colorChangeAnimation.toValue = gradientTargetColors
        colorChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        colorChangeAnimation.isRemovedOnCompletion = false
        colorChangeAnimation.delegate = self
        gradientLayer.add(colorChangeAnimation, forKey: colorChangeAnimationKey)
    }

    func onAnimationEnd(_ anim: CAAnimation, finished flag: Bool) {
        guard anim == gradientLayer.animation(forKey: colorChangeAnimationKey) else {
            return
        }

        gradientLayer.colors = gradientTargetColors
        animateGradientLayer()
    }

    private var colorChangeAnimationKeyPath: String { return "colors" }
    private var colorChangeAnimationKey: String { return "colorChangeAnimation" }
    private var colorChangeAnimationDuration: CFTimeInterval { return 5.0 }
}

extension CGPoint {

    static var randomTopQuarter: CGPoint { return CGPoint(x: CGFloat.random(0.0, 1.0), y: CGFloat.random(0.0, 0.25)) }
    static var randomBottomQuarter: CGPoint { return CGPoint(x: CGFloat.random(0.0, 1.0), y: CGFloat.random(0.75, 1.0)) }
}

extension UIColor {
    /**
     * Returns random color
     * ## Examples:
     * self.backgroundColor = UIColor.random
     */
    static var random: UIColor {
        return random(low: 0, high: 1)
    }

    static var darkRandom: UIColor {
        return random(low: 0.1, high: 0.4)
    }

    static var midRandom: UIColor {
        return random(low: 0.3, high: 0.6)
    }

    static var lightRandom: UIColor {
        return random(low: 0.6, high: 1.0)
    }

    private static func random(low: CGFloat, high: CGFloat) -> UIColor
    {
        let r:CGFloat  = .random(in: low...high)
        let g:CGFloat  = .random(in: low...high)
        let b:CGFloat  = .random(in: low...high)
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

/*
 Copyright (c) 2017-2019 M.I. Hollemans
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to
 deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 IN THE SOFTWARE.
 */
extension UIImage {
    /**
     Resizes the image to width x height and converts it to an RGB CVPixelBuffer.
     */
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_32ARGB,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst)
    }

    /**
     Resizes the image to width x height and converts it to a grayscale CVPixelBuffer.
     */
    public func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_OneComponent8,
                           colorSpace: CGColorSpaceCreateDeviceGray(),
                           alphaInfo: .none)
    }

    func pixelBuffer(width: Int, height: Int, pixelFormatType: OSType,
                     colorSpace: CGColorSpace, alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
            else {
                return nil
        }

        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        return pixelBuffer
    }
}

enum UIImageType: String {
    case PNG = "png"
    case JPG = "jpg"
    case JPEG = "jpeg"
}

extension UIImage {

    convenience init?(contentsOfFile name: String, ofType: UIImageType) {
        guard let bundlePath = Bundle.main.path(forResource: name, ofType: ofType.rawValue) else {
            return nil
        }
        self.init(contentsOfFile: bundlePath)!
    }
}

// Reference: https://www.hackingwithswift.com/example-code/uikit/how-to-find-an-aspect-fit-images-size-inside-an-image-view
extension UIImageView {

    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0
        let y = (bounds.height - size.height) / 2.0

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

extension CGRect {

    func scaled(at scale: CGFloat) -> CGRect {
        // Reference: https://www.hackingwithswift.com/articles/103/seven-useful-methods-from-cgrect
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return self.applying(transform)
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

// Reference: https://stackoverflow.com/questions/27624331/unique-values-of-array-in-swift
extension Array where Element : Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}

extension UIViewController {

    internal func displayMessage(_ message: String, title: String = "") {

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    internal func displayYesNoMessage(_ message: String, title: String = "", yesButton: String = "Yes", noButton: String = "No") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: yesButton, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: noButton, style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    internal func displayOkayCancelMessage(_ message: String, title: String = "") {

        displayYesNoMessage(message, title: title, yesButton: "Okay", noButton: "Cancel")
    }
}

extension UIView {
    func fadeIn(duration: TimeInterval = 0.35, delay: TimeInterval = 0.0, targetAlpha: CGFloat = 1.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = targetAlpha
        }, completion: completion)
    }

    func fadeOut(duration: TimeInterval = 0.35, delay: TimeInterval = 0.2, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: completion)
    }

    func fadeInAndOut(fadeInTime: TimeInterval = 0.35, stayTime: TimeInterval = 0.35, fadeOutTime: TimeInterval = 0.35) {
        fadeIn(duration: fadeInTime, completion: {
            (finished: Bool) -> Void in

            self.fadeOut(duration: fadeOutTime, delay: stayTime)
        })
    }

    func fadeInAndOut(duration: TimeInterval = 0.35, stayTimeFraction: Double = 0.3) {
        let stayTime = duration * stayTimeFraction
        let fadeInOutTime = duration * (1 - stayTimeFraction)/2
        self.fadeInAndOut(fadeInTime: fadeInOutTime, stayTime: stayTime, fadeOutTime: fadeInOutTime)
    }
}

extension UIView {

    func rotateAndScale(duration: TimeInterval = 5.0) {

        let rotate180 = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        let rotate360 = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        let initialScaleDown = CGAffineTransform(scaleX: 0.1, y: 0.1)

        // initial transform
        self.alpha = 0
        self.transform = initialScaleDown.concatenating(rotate180)

        UIView.animate(withDuration: duration/2.0, animations: {
            self.transform = self.transform.scaledBy(x: 10, y: 10).concatenating(rotate360)
            self.alpha = 1
        }) { (true) in
            UIView.animate(withDuration: duration/2.0, animations: {
                self.transform = self.transform.scaledBy(x: 0.1, y: 0.1).concatenating(rotate180)
                self.alpha = 0
            })
        }
    }
}

extension UIView {
    func shake() {
        self.transform = CGAffineTransform(translationX: 15, y: 0)
        UIView.animate(withDuration: 3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}

extension String {
    var nsRange : NSRange {
        return NSRange(self.startIndex..., in: self)
    }
}
