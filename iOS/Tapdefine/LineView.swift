//
//  LineView.swift
//  Tapdefine
//
//  Created by Hamik on 8/23/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class LineView: UIView {
    
    var viewWidth = Constants.SeparatorViewWidth
    var vertical = true
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            drawHairline(in: context, scale: UIScreen.main.scale, color: Constants.NavbarBorderGray.cgColor)
        }
    }
    
    // pass in the scale of your UIScreen
    func drawHairline(in context: CGContext, scale: CGFloat, color: CGColor) {

        let offset = 0.5 - (Int(scale) % 2 == 0 ? 1 / (scale * 2) : 0)
        var p1 = vertical ? CGPoint(x: viewWidth / 2, y: 0) : CGPoint(x: 0, y: viewWidth / 2)
        var p2 = vertical ? CGPoint(x: viewWidth / 2, y: 9999) : CGPoint(x: 9999, y: viewWidth / 2)
        p1.x += offset
        p1.y += offset
        p2.x += offset
        p2.y += offset

        let width = 1 / scale
        context.setLineWidth(width)
        context.setStrokeColor(color)
        context.beginPath()
        context.move(to: p1)
        context.addLine(to: p2)
        context.strokePath()
    }
    
    static func MakeLine(in parentView: UIView, under: UIView?, space: CGFloat, leftMargin: CGFloat? = nil, rightMargin: CGFloat? = nil) -> LineView {
        let lineView = LineView()
        lineView.vertical = false
        lineView.backgroundColor = UIColor.clear
        parentView.addSubview(lineView)
        let lvtc = NSLayoutConstraint(item: lineView, attribute: .top, relatedBy: .equal, toItem: (under == nil ? parentView : under), attribute: (under == nil ? .top : .bottom), multiplier: 1, constant: space)
        let lvhc = NSLayoutConstraint(item: lineView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.SeparatorViewWidth)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addConstraints([lvtc, lvhc])
        
        if let leftMargin = leftMargin, let rightMargin = rightMargin {
            let lvlm = NSLayoutConstraint(item: lineView, attribute: .left, relatedBy: .equal, toItem: parentView, attribute: .left, multiplier: 1, constant: leftMargin)
            let lvrm = NSLayoutConstraint(item: lineView, attribute: .right, relatedBy: .equal, toItem: parentView, attribute: .right, multiplier: 1, constant: rightMargin)
            lineView.translatesAutoresizingMaskIntoConstraints = false
            parentView.addConstraints([lvlm, lvrm])
        } else {
            (_, _) = lineView.snuglyConstrain(to: parentView, leftAmount: 0, rightAmount: 0)
        }

        return lineView
    }
}
