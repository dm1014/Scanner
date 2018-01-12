//
//  XButton.swift
//  Scanner
//
//  Created by David Martin on 12/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

class XButton: UIButton {
	fileprivate enum Constants {
		enum Default {
			static let size: CGFloat = 44.0
			static let spacing: CGFloat = 8.0
			static let lineWidth: CGFloat = 3.0
		}
	}
	
	fileprivate let strokeColor: UIColor
	fileprivate let lineWidth: CGFloat
	
	init(color: UIColor = .white, lineWidth: CGFloat = Constants.Default.lineWidth, frame: CGRect) {
		self.strokeColor = color
		self.lineWidth = lineWidth
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ rect: CGRect) {
		let spacing = (rect.width / Constants.Default.size) * Constants.Default.spacing
		
		let point1 = CGPoint(x: spacing, y: spacing)
		let point2 = CGPoint(x: rect.width - (spacing * 2.0), y: rect.height - (spacing * 2.0))
		let point3 = CGPoint(x: rect.width - (spacing * 2.0), y: spacing)
		let point4 = CGPoint(x: spacing, y: rect.height - (spacing * 2.0))
		
		let path = UIBezierPath()
		path.lineWidth = lineWidth
		path.lineCapStyle = .round
		
		path.move(to: point1)
		path.addLine(to: point2)
		path.move(to: point3)
		path.addLine(to: point4)
		
		strokeColor.setStroke()
		path.stroke()
	}
}
