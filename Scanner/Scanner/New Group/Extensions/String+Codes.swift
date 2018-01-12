//
//  String+QR.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

public enum GeneratableCodeType {
	case barcode
	case qr
}

public extension String {
	public func generate(code codeType: GeneratableCodeType) -> UIImage? {
		guard let data = self.data(using: .ascii) else { return nil }
		
		var name = ""
		switch codeType {
		case .barcode:
			name = "CICode128BarcodeGenerator"
		case .qr:
			name = "CIQRCodeGenerator"
		}
		
		if let filter = CIFilter(name: name) {
			filter.setValue(data, forKey: "inputMessage")
			let transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
			
			if let image = filter.outputImage {
				return UIImage(ciImage: image.transformed(by: transform))
			}
		}
		
		return nil
	}
}
