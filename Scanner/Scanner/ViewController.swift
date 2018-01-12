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
	
	fileprivate let documentButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Scan Document", for: .normal)
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
		view.addSubview(documentButton)
		
		qrButton.addTarget(self, action: #selector(qrAction(_:)), for: .touchUpInside)
		barcodeButton.addTarget(self, action: #selector(barcodeAction(_:)), for: .touchUpInside)
		bothButton.addTarget(self, action: #selector(bothAction(_:)), for: .touchUpInside)
		documentButton.addTarget(self, action: #selector(documentAction(_:)), for: .touchUpInside)
		
		let qrLeft = qrButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let qrRight = qrButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let qrHeight = qrButton.heightAnchor.constraint(equalToConstant: 48.0)
		let qrBottom = qrButton.bottomAnchor.constraint(equalTo: barcodeButton.topAnchor)
		
		let barcodeLeft = barcodeButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let barcodeRight = barcodeButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let barcodeHeight = barcodeButton.heightAnchor.constraint(equalToConstant: 48.0)
		let barcodeBottom = barcodeButton.bottomAnchor.constraint(equalTo: view.centerYAnchor)
		
		let bothTop = bothButton.topAnchor.constraint(equalTo: barcodeButton.bottomAnchor)
		let bothLeft = bothButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let bothRight = bothButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let bothHeight = bothButton.heightAnchor.constraint(equalToConstant: 48.0)

		let documentTop = documentButton.topAnchor.constraint(equalTo: bothButton.bottomAnchor)
		let documentLeft = documentButton.leftAnchor.constraint(equalTo: view.leftAnchor)
		let documentRight = documentButton.rightAnchor.constraint(equalTo: view.rightAnchor)
		let docuemtnHeight = documentButton.heightAnchor.constraint(equalToConstant: 48.0)
		
		NSLayoutConstraint.activate([qrLeft, qrRight, qrHeight, qrBottom,
		                             barcodeLeft, barcodeRight, barcodeHeight, barcodeBottom,
		                             bothTop, bothLeft, bothRight, bothHeight,
									 documentTop, documentLeft, documentRight, docuemtnHeight])
	}
	
	@objc fileprivate func qrAction(_ sender: UIButton) {
		Scanner.presentCodeScanner(in: self, type: .qr, delegateConformer: self)
	}
	
	@objc fileprivate func barcodeAction(_ sender: UIButton) {
		Scanner.presentCodeScanner(in: self, type: .barcode, delegateConformer: self)
	}
	
	@objc fileprivate func bothAction(_ sender: UIButton) {
		Scanner.presentCodeScanner(in: self, type: .both, delegateConformer: self)
	}
	
	@objc fileprivate func documentAction(_ sender: UIButton) {
		let scanner = DocuScanner()
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
		scanner.dismiss(animated: true) {
			let alert = UIAlertController(title: "\(type) Scanned", message: code, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func scanner(_ scanner: CodeScanner, handleError error: NSError) {
		print("an error occured with the scanner. error:", error.localizedDescription)
	}
	
	@nonobjc func willDismissScanner(_ scanner: CodeScanner) {
		print("will dismiss CodeScanner")
	}
	
	@nonobjc func didDismissScanner(_ scanner: CodeScanner) {
		print("did dismiss CodeScanner")
	}
}

extension ViewController: DocuScannerDelegate {
	func docuScanner(_ scanner: DocuScanner, captured image: UIImage) {
		print("captured image")
	}
	
	func docuScanner(_ scanner: DocuScanner, handleError error: Error?) {
		print("encountered an error:", error ?? nil)
	}
	
	@nonobjc func willDismissScanner(_ scanner: DocuScanner) {
		print("will dismiss DocuScanner")
	}
	
	@nonobjc func didDismissScanner(_ scanner: DocuScanner) {
		print("did dismiss DocuScanner")
	}
}
