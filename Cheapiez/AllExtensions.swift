//
//  AllExtensions.swift
//  ListenUp
//
//  Created by Tianran Ding on 5/07/21.
//

import UIKit

public let supportsMacIdiom = !(UIDevice.current.userInterfaceIdiom == .pad)

@inlinable func UIFloat(_ value: CGFloat) -> CGFloat
{
    return round((value == 0.5) ? 0.5 : value * (supportsMacIdiom ? 0.77 : 1.0))
}

extension UIImage {
    public func colored(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        let rect = CGRect(origin: CGPoint.zero, size: size)
        color.setFill()
        self.draw(in: rect)
        context.setBlendMode(.sourceIn)
        context.fill(rect)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resultImage
    }
}

extension UserDefaults {
    func colorForKey(key: String) -> UIColor? {
        if let colorData = data(forKey: key),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        {
            return color
        } else {
            return nil
        }
    }

    func setColor(color: UIColor?, forKey key: String) {
        if let color = color,
            let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
        {
            set(colorData, forKey: key)
        }
    }
}

extension String {
    func textToImage() -> UIImage? {
        let nsString = (self as NSString)
        let font = UIFont.systemFont(ofSize: 128) // you can change your font size here
        let stringAttributes = [NSAttributedString.Key.font: font]
        let imageSize = nsString.size(withAttributes: stringAttributes)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0) //  begin image context
        UIColor.clear.set() // clear background
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize)) // set rect size
        nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes) // draw text within rect
        let image = UIGraphicsGetImageFromCurrentImageContext() // create image from context
        UIGraphicsEndImageContext() //  end image context

        return image ?? UIImage()
    }
}
