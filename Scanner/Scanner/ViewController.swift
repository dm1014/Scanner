//
//  ViewController.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController {
	fileprivate let qrButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Scan QR Code", for: .normal)
		button.setTitleColor(.black, for: .normal)
		button.setTitleColor(UIColor.black.withAlphaComponent(0.1), for: .highlighted)
		return button
	}()
	
	fileprivate let barcodeButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Scan Barcode", for: .normal)
		button.setTitleColor(.black, for: .normal)
		button.setTitleColor(UIColor.black.withAlphaComponent(0.1), for: .highlighted)
		return button
	}()
	
	fileprivate let bothButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Scan Code", for: .normal)
		button.setTitleColor(.black, for: .normal)
		button.setTitleColor(UIColor.black.withAlphaComponent(0.1), for: .highlighted)
		return button
	}()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		view.backgroundColor = .white
		
		setupViews()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate func setupViews() {
		view.addSubview(qrButton)
		view.addSubview(barcodeButton)
		view.addSubview(bothButton)
		
		qrButton.addTarget(self, action: #selector(qrAction(_:)), for: .touchUpInside)
		barcodeButton.addTarget(self, action: #selector(barcodeAction(_:)), for: .touchUpInside)
		bothButton.addTarget(self, action: #selector(bothAction(_:)), for: .touchUpInside)
		
		let qrLeft = qrButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let qrRight = qrButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let qrHeight = qrButton.heightAnchor.constraint(equalToConstant: 48.0)
		let qrCenterX = qrButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		let qrCenterY = qrButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		
		let barcodeLeft = barcodeButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let barcodeRight = barcodeButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let barcodeHeight = barcodeButton.heightAnchor.constraint(equalToConstant: 48.0)
		let barcodeBottom = barcodeButton.bottomAnchor.constraint(equalTo: qrButton.topAnchor)
		let barcodeCenterX = barcodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
		
		let bothTop = bothButton.topAnchor.constraint(equalTo: qrButton.bottomAnchor)
		let bothLeft = bothButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let bothRight = bothButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let bothHeight = bothButton.heightAnchor.constraint(equalToConstant: 48.0)
		let bothCenterX = bothButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)

		NSLayoutConstraint.activate([qrLeft, qrRight, qrHeight, qrCenterX, qrCenterY,
		                             barcodeLeft, barcodeRight, barcodeHeight, barcodeBottom, barcodeCenterX,
		                             bothTop, bothLeft, bothRight, bothHeight, bothCenterX])
	}
	
	@objc fileprivate func qrAction(_ sender: UIButton) {
		let scanner = CodeScanner(scannerType: .qr)
		scanner.delegate = self
		present(scanner, animated: true, completion: nil)
	}
	
	@objc fileprivate func barcodeAction(_ sender: UIButton) {
		let scanner = CodeScanner(scannerType: .barcode)
		scanner.delegate = self
		present(scanner, animated: true, completion: nil)
	}
	
	@objc fileprivate func bothAction(_ sender: UIButton) {
		let scanner = CodeScanner(scannerType: .both)
		scanner.delegate = self
		present(scanner, animated: true, completion: nil)
	}
}

extension ViewController: ScannerDelegate {
	func scanner(_ scanner: CodeScanner, didScanCode code: String, codeType: CodeType) {
		var type = ""
		switch codeType {
		case .barcode:
			type = "Barcode"
		case .qr:
			type = "QR"
		}
		print("scanned code \(code) with type:", type)
	}
	
	func scanner(_ scanner: CodeScanner, handleError error: NSError) {
		print("an error occured with the scanner. error:", error.localizedDescription)
	}
	
	func scanner(_ scanner: CodeScanner, willDismissScanner: Bool) {
		print("will dismiss scanner")
	}
	
	func scanner(_ scanner: CodeScanner, didDismissScanner: Bool) {
		print("did dismiss scanner")
	}
}
