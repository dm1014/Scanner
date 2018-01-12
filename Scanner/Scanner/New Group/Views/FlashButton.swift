//
//  FlashButton.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

class FlashButton: UIButton {
    
    fileprivate let strokeColor: UIColor
    fileprivate let fillColor: UIColor
    fileprivate let lineWidth: CGFloat
    
    init(strokeColor: UIColor = .white, fillColor: UIColor = UIColor.white.withAlphaComponent(0.5), lineWidth: CGFloat = 3.0, frame: CGRect) {
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Warning: failed to init from coder")
    }
    
    override func draw(_ rect: CGRect) {
        let flashWidth: CGFloat = rect.width
        let flashHeight: CGFloat = rect.height
        let xCenter: CGFloat = rect.origin.x + (rect.width / 2.0)
        
        let fortyRatio = (flashWidth / 300.0) * 40.0
        let twentyRatio = (flashWidth / 300.0) * 20.0
        
        let point1 = CGPoint(x: xCenter + fortyRatio, y: 0.0)
        let point2 = CGPoint(x: xCenter + twentyRatio, y: (flashHeight / 2.0) - twentyRatio)
        let point3 = CGPoint(x: xCenter + (flashWidth / 2.0), y: (flashHeight / 2.0) - twentyRatio)
        let point4 = CGPoint(x: xCenter - fortyRatio, y: flashHeight)
        let point5 = CGPoint(x: xCenter - twentyRatio, y: (flashHeight / 2.0) + twentyRatio)
        let point6 = CGPoint(x: xCenter - (flashWidth / 2.0), y: (flashHeight / 2.0) + twentyRatio)
        
        let flashPath = UIBezierPath()
        flashPath.lineWidth = lineWidth
        
        flashPath.move(to: point1)
        flashPath.addLine(to: point2)
        flashPath.addLine(to: point3)
        flashPath.addLine(to: point4)
        flashPath.addLine(to: point5)
        flashPath.addLine(to: point6)
        
        flashPath.close()
        
        strokeColor.setStroke()
        flashPath.stroke()
        
        fillColor.setFill()
        flashPath.fill()
    }
}
