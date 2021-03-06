//
//  Extensions.swift
//  FibWordClock
//
//  Created by Jesse Levine on 8/22/14.
//  Copyright (c) 2014 jesselevine. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    class func autolayoutView() -> UIView {
        let view = UIView()
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        return view
    }
    
    func autolayoutSetAspectRatio(widthToHeight: CGFloat) {
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: widthToHeight, constant: 0))
    }
    
    func autolayoutCenterSubview(subview: UIView, attribute: NSLayoutAttribute) {
        if attribute != .CenterX && attribute != .CenterY {
            return
        }
        if !(self.subviews as NSArray).containsObject(subview) {
            self.addSubview(subview)
        }
        self.addConstraint(NSLayoutConstraint(item: subview, attribute: attribute, relatedBy: .Equal, toItem: self, attribute: attribute, multiplier: 1, constant: 0))
    }
    
    func autolayoutInsetSubview(subview: UIView, insets: UIEdgeInsets) {
        if !(self.subviews as NSArray).containsObject(subview) {
            self.addSubview(subview)
        }
        let subviewString = "subview"
        let viewsDict = [ subviewString : subview ]
        
        let vFormatString = "V:|-\(insets.top)-[\(subviewString)]-\(insets.bottom)-|"
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(vFormatString, options: nil, metrics: nil, views: viewsDict))
        let hFormatString = "|-\(insets.left)-[\(subviewString)]-\(insets.right)-|"
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(hFormatString, options: nil, metrics: nil, views: viewsDict))
    }
    
    /**
     * Builds constraints so that subview takes up as much room as possible without crossing self's edges (plus any extra padding specified)
     */
    func autolayoutFillContainerWithSubview(subview: UIView, var padding: CGFloat) {
        if !(self.subviews as NSArray).containsObject(subview) {
            self.addSubview(subview)
        }
        padding = max(0, padding)
        
        let subviewString = "subview"
        let viewsDict = [ subviewString : subview ]
        
        let spacingString = "(>=\(padding),==\(padding)@900)"
        let hFormatString = "|-\(spacingString)-[\(subviewString)]-\(spacingString)-|"
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(hFormatString, options: nil, metrics: nil, views: viewsDict))
        let vFormatString = "V:" + hFormatString
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(vFormatString, options: nil, metrics: nil, views: viewsDict))
    }
    
    func autoLayoutSpaceSubviewsEvenly(subviews: [UIView], vertically: Bool) {
        for sub in subviews {
        if !(self.subviews as NSArray).containsObject(sub) {
                self.addSubview(sub)
            }
        }
    }
}

extension NSCalendarUnit {
    
    func timeInterval() -> NSTimeInterval {
        var interval: Double = 0
        switch (self) {
        case NSCalendarUnit.CalendarUnitSecond:
            interval = 1
        case NSCalendarUnit.CalendarUnitMinute:
            interval = 60
        case NSCalendarUnit.CalendarUnitHour:
            interval = 60 * 60
        default:
            interval = 0
        }
        return interval
    }
}

extension UIColor {
    class func randomColor() -> UIColor {
        let r = CGFloat(arc4random() % 255) / 255.0
        let g = CGFloat(arc4random() % 255) / 255.0
        let b = CGFloat(arc4random() % 255) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
