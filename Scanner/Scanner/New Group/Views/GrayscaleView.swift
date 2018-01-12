//
//  GrayscaleView.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

class GrayscaleView : UIButton {
    
    override func draw(_ rect: CGRect) {
        
        drawSlice(rect: rect, startPercent: 35, endPercent: -15, color: UIColor.white.withAlphaComponent(0.5))
        drawSlice(rect: rect, startPercent: -15, endPercent: 35, color: UIColor.black.withAlphaComponent(0.5))
    }
    
    private func drawSlice(rect: CGRect, startPercent: CGFloat, endPercent: CGFloat, color: UIColor) {
        let center = CGPoint(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
        let radius = min(rect.width, rect.height) / 2
        let startAngle = startPercent / 100 * CGFloat(Double.pi) * 2 - CGFloat(Double.pi)
        let endAngle = endPercent / 100 * CGFloat(Double.pi) * 2 - CGFloat(Double.pi)
        let path = UIBezierPath()
        path.move(to: center)
        path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        path.close()
        color.setFill()
        path.fill()
    }
}
