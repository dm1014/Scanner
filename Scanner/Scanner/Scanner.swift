//
//  Scanner.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import UIKit
import AVFoundation

public class Scanner: UIViewController {
	fileprivate enum Constants {
		enum Codes {
			static let allCodes: [AVMetadataObject.ObjectType] = [
				.aztec,
				.code39,
				.code39Mod43,
				.code93,
				.code128,
				.ean8,
				.ean13,
				.pdf417,
				.qr,
				.upce
			]
			static let barcodes: [AVMetadataObject.ObjectType] = [
				.aztec,
				.code39,
				.code39Mod43,
				.code93,
				.code128,
				.ean8,
				.ean13,
				.pdf417,
				.upce
			]
		}
		
		enum Durations {
			static let popup: TimeInterval = 0.4
		}
		
		enum Sizes {
			static let popup: CGFloat = 50.0
		}
	}
	
	fileprivate var captureSession: AVCaptureSession?
	fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
	fileprivate var codeView: UIView?
	fileprivate var popupBottom = NSLayoutConstraint()
	fileprivate var recentCode: String?
	fileprivate var isShowingPopup = false
	
	fileprivate lazy var popupLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.text = popupText
		label.textAlignment = textAlignment
		label.textColor = textColor
		label.backgroundColor = textBackgroundColor
		label.font = textFont
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		return label
	}()
	
	public var popupText: String = "Tap to dismiss scanner" {
		didSet {
			popupLabel.text = popupText
		}
	}
	
	public var textAlignment: NSTextAlignment = .center {
		didSet {
			popupLabel.textAlignment = textAlignment
		}
	}
	
	public var textColor: UIColor = .white {
		didSet {
			popupLabel.textColor = textColor
		}
	}
	
	public var textFont: UIFont = UIFont.systemFont(ofSize: 20.0, weight: .semibold) {
		didSet {
			popupLabel.font = textFont
		}
	}
	
	public var textBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.8) {
		didSet {
			popupLabel.backgroundColor = textBackgroundColor
		}
	}
	
	public var squareBorderColor: UIColor = .green {
		didSet {
			codeView?.layer.borderColor = squareBorderColor.cgColor
		}
	}
	
	public var squareBackgroundColor: UIColor = .clear {
		didSet {
			codeView?.backgroundColor = squareBorderColor
		}
	}
	
	override public var prefersStatusBarHidden: Bool { return true }
	override public var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
	
	public enum ScannerType {
		case qr
		case barcode
		case both
	}
	
	fileprivate let scannerType: ScannerType
	
	public init(scannerType: ScannerType) {
		self.scannerType = scannerType
		
		super.init(nibName: nil, bundle: nil)
		
		setupViews()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let session = captureSession, !session.isRunning {
			captureSession?.startRunning()
		}
	}
	
	override public func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if let session = captureSession, session.isRunning {
			captureSession?.stopRunning()
		}
	}
	
	fileprivate func setupViews() {
		guard let captureDevice = AVCaptureDevice.default(for: .video) else {
			handleError(errorType: .noCamera)
			return
		}
		
		do {
			let input = try AVCaptureDeviceInput(device: captureDevice)
			let session = AVCaptureSession()
			
			if session.canAddInput(input) {
				session.addInput(input)
			} else {
				// unable to add input
				handleError(errorType: .unableToAddInput)
				return
			}
			
			let metaOutput = AVCaptureMetadataOutput()
			if session.canAddOutput(metaOutput) {
				session.addOutput(metaOutput)
				
				metaOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
				
				switch scannerType {
				case .barcode:
					metaOutput.metadataObjectTypes = Constants.Codes.barcodes
				case .both:
					metaOutput.metadataObjectTypes = Constants.Codes.allCodes
				case .qr:
					metaOutput.metadataObjectTypes = [.qr]
				}
			} else {
				// unable to add output
				handleError(errorType: .unableToAddOutput)
				return
			}
			
			let videoLayer = AVCaptureVideoPreviewLayer(session: session)
			videoLayer.frame = view.layer.bounds
			videoLayer.videoGravity = .resizeAspectFill
			view.layer.addSublayer(videoLayer)
			
			previewLayer = videoLayer
			captureSession = session
			captureSession?.startRunning()
			
			codeView = UIView()
			if let codeView = codeView {
				codeView.layer.borderColor = UIColor.green.cgColor
				codeView.layer.borderWidth = 2.0
				view.addSubview(codeView)
				view.bringSubview(toFront: codeView)
			}
			
			view.addSubview(popupLabel)
			
			let intrinsicHeight = popupLabel.intrinsicContentSize.height
			let popupLeft = popupLabel.leftAnchor.constraint(equalTo: view.leftAnchor)
			let popupRight = popupLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
			let popupHeight = popupLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.Sizes.popup)
			popupBottom = popupLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: intrinsicHeight > Constants.Sizes.popup ? intrinsicHeight : Constants.Sizes.popup)
			
			NSLayoutConstraint.activate([popupLeft, popupRight, popupHeight, popupBottom])
			
			let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
			tap.numberOfTapsRequired = 1
			view.addGestureRecognizer(tap)
		} catch {
			handleError(errorType: .custom(error.localizedDescription))
			return
		}
	}
	
	fileprivate func handleError(errorType: ErrorType) {
		let error = NSError.scanner_error(errorType)
		let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
		captureSession = nil
	}
	
	fileprivate func foundCode(_ code: String) {
		print("found code:", code)
		guard !isShowingPopup else { return }
		recentCode = code
		
		view.layoutIfNeeded()
		UIView.animate(withDuration: Constants.Durations.popup, animations: {
			self.popupBottom.constant = 0.0
			self.view.layoutIfNeeded()
		}) { _ in
			self.isShowingPopup = true
		}
	}
	
	fileprivate func hidePopup() {
		guard isShowingPopup else { return }
		recentCode = nil
		
		let intrinsicHeight = popupLabel.intrinsicContentSize.height
		view.layoutIfNeeded()
		UIView.animate(withDuration: Constants.Durations.popup, animations: {
			self.popupBottom.constant = intrinsicHeight > Constants.Sizes.popup ? intrinsicHeight : Constants.Sizes.popup
			self.view.layoutIfNeeded()
		}) { _ in
			self.isShowingPopup = false
		}
	}
	
	@objc fileprivate func tapAction(_ sender: UITapGestureRecognizer) {
		guard isShowingPopup else { return }
		dismiss(animated: true, completion: nil)
	}
}

extension Scanner: AVCaptureMetadataOutputObjectsDelegate {
	public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		if let object = metadataObjects.first {
			switch scannerType {
			case .barcode:
				guard Constants.Codes.barcodes.contains(object.type) else { return }
			case .both:
				guard Constants.Codes.allCodes.contains(object.type) else { return }
			case .qr:
				guard object.type == .qr else { return }
			}
			
			guard let readableObject = object as? AVMetadataMachineReadableCodeObject, let value = readableObject.stringValue, let transformedObject = previewLayer?.transformedMetadataObject(for: readableObject) else { return }
			codeView?.isHidden = false
			codeView?.frame = transformedObject.bounds

			foundCode(value)
		} else {
			codeView?.isHidden = true
			hidePopup()
		}
	}
}
