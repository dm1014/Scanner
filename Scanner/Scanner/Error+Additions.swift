//
//  Error+Additions.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

public enum ErrorType {
	public static let errorType = "\(Bundle.main.bundleIdentifier).errorType"
	
	case noCamera
	case noInputDevice
	case unableToAddInput
	case unableToAddOutput
	case custom(String)
}

public extension NSError {
	public static func scanner_error(_ type: ErrorType) -> NSError {
		var errorReason = ""
		
		switch type {
		case .noCamera:
			errorReason = "No camera found"
		case .noInputDevice:
			errorReason = "Unable to get input device"
		case .unableToAddInput:
			errorReason = "Unable to add input"
		case .unableToAddOutput:
			errorReason = "Uable to add output"
		case .custom(let text):
			errorReason = text
		}
		
		return NSError(domain: Bundle.main.bundleIdentifier!, code: -100, userInfo: [NSLocalizedDescriptionKey: errorReason, ErrorType.errorType: type])
	}
}
