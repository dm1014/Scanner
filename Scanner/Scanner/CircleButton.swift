//
//  CircleButton.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

class CircleButton: UIButton {
    override func layoutSubviews() {
        layer.cornerRadius = bounds.height / 2.0
        layer.masksToBounds = true
    }
}
