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
	}
	
	fileprivate var captureSession: AVCaptureSession?
	fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
	fileprivate var codeView: UIView?
	fileprivate let scannerType: ScannerType
	
	override public var prefersStatusBarHidden: Bool { return true }
	override public var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
	
	public enum ScannerType {
		case qr
		case barcode
		case both
	}
	
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
		}
	}
}
