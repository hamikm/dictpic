//
//  ExpandedHitAreaButton.swift
//  Tapdefine
//
//  Created by Hamik on 8/24/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class ExpandedHitAreaButton: UIButton {
    var leftAmount = CGFloat(-30)
    var rightAmount = CGFloat(-30)

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsetsMake(0, leftAmount, 0, rightAmount)
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
