//
//  Scanner.swift
//  Scanner
//
//  Created by David Martin on 1/12/18.
//  Copyright © 2018 dm Apps. All rights reserved.
//

import Foundation
import UIKit

public final class Scanner {
	public static func presentCodeScanner(in viewController: UIViewController, type: ScannerType, delegateConformer: ScannerDelegate?) {
		let scanner = CodeScanner(scannerType: type)
		scanner.delegate = delegateConformer
		
		let navController = Scanner.setupNavigationController(for: scanner)
		
		viewController.present(navController, animated: true, completion: nil)
	}
	
	public static func presentDocuScanner(in viewController: UIViewController, delegateConformer: DocuScannerDelegate?) {
		let scanner = DocuScanner()
		scanner.delegate = delegateConformer
		
		let navController = Scanner.setupNavigationController(for: scanner)
		
		viewController.present(navController, animated: true, completion: nil)
	}
	
	fileprivate static func setupNavigationController(for viewController: UIViewController) -> UINavigationController {
		let navController = UINavigationController(rootViewController: viewController)
		navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
		navController.navigationBar.shadowImage = UIImage()
		navController.navigationBar.isTranslucent = true
		navController.navigationBar.barTintColor = .clear
		navController.navigationBar.tintColor = .white
		
		return navController
	}
}
