//
//  Scanner.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol ScannerDelegate: class {
	func scanner(_ scanner: Scanner, didScanCode code: String, codeType: Scanner.CodeType)
	func scanner(_ scanner: Scanner, handleError error: NSError)
	@objc optional func scanner(_ scanner: Scanner, willDismissScanner: Bool)
	@objc optional func scanner(_ scanner: Scanner, didDismissScanner: Bool)
}

@objc public class Scanner: UIViewController {
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
	
	@objc public enum CodeType: Int {
		case barcode
		case qr
	}
	
	public enum ScannerType {
		case barcode
		case both
		case qr
	}
	
	fileprivate let scannerType: ScannerType
	
	public weak var delegate: ScannerDelegate?
	
	public init(scannerType: ScannerType) {
		self.scannerType = scannerType
		
		super.init(nibName: nil, bundle: nil)
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
	
		setupViews()
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let session = captureSession, !session.isRunning {
			captureSession?.startRunning()
		}
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
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
		delegate?.scanner(self, handleError: error)
		captureSession = nil
	}
	
	fileprivate func foundCode(_ code: String, codeType: CodeType) {
		guard !isShowingPopup else { return }
		recentCode = code
		delegate?.scanner(self, didScanCode: code, codeType: codeType)
		
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
		delegate?.scanner?(self, willDismissScanner: true)
		
		dismiss(animated: true, completion: { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.delegate?.scanner?(weakSelf, didDismissScanner: true)
		})
	}
}

extension Scanner: AVCaptureMetadataOutputObjectsDelegate {
	public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		if let object = metadataObjects.first {
			let codeType: CodeType
			switch scannerType {
			case .barcode:
				guard Constants.Codes.barcodes.contains(object.type) else { return }
				codeType = .barcode
			case .both:
				guard Constants.Codes.allCodes.contains(object.type) else { return }
				codeType = object.type == .qr ? .qr : .barcode
			case .qr:
				guard object.type == .qr else { return }
				codeType = .qr
			}
			
			guard let readableObject = object as? AVMetadataMachineReadableCodeObject, let value = readableObject.stringValue, let transformedObject = previewLayer?.transformedMetadataObject(for: readableObject) else { return }
			codeView?.isHidden = false
			codeView?.frame = transformedObject.bounds

			
			foundCode(value, codeType: codeType)
		} else {
			codeView?.isHidden = true
			hidePopup()
		}
	}
}
