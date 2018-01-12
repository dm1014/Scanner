//
//  CodeScanner.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

@objc public protocol ScannerDelegate: class {
	func scanner(_ scanner: CodeScanner, didScanCode code: String, codeType: CodeType)
	func scanner(_ scanner: CodeScanner, handleError error: NSError)
	@objc optional func scanner(_ scanner: CodeScanner, willDismissScanner: Bool)
	@objc optional func scanner(_ scanner: CodeScanner, didDismissScanner: Bool)
}

@objc public enum CodeType: Int {
	case barcode
	case qr
}

public enum ScannerType {
	case barcode
	case both
	case qr
}

@objc public class CodeScanner: UIViewController {
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
		
		enum Defaults {
			static let alpha: CGFloat = 0.25
		}
		
		enum Durations {
			static let popup: TimeInterval = 0.4
		}
		
		enum Edges {
			static let button = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
			static let cancel = UIEdgeInsets(top: 20.0, left: 16.0, bottom: 0.0, right: 0.0)
		}
		
		enum Sizes {
			static let popup: CGFloat = 50.0
			static let bar: CGFloat = 64.0
			static let cancel: CGFloat = 44.0
			static let smallLineWidth: CGFloat = 1.5
			static let normalLineWidth: CGFloat = 3.0
			static let buttonSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 96.0 : 72.0
		}
	}
	
	fileprivate var captureSession: AVCaptureSession?
	fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
	fileprivate var codeView: UIView?
	fileprivate var recentCode: String?
	fileprivate var recentType: CodeType?
	
	fileprivate let grayscaleButton: GrayscaleView = {
		let button = GrayscaleView()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.layer.cornerRadius = Constants.Sizes.buttonSize / 4.0
		button.layer.masksToBounds = true
		button.layer.borderColor = UIColor.white.cgColor
		button.layer.borderWidth = Constants.Sizes.smallLineWidth
		return button
	}()
	
	fileprivate let cancelButton: UIButton = {
		let button = XButton(color: .white, frame: .zero)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()
	
	fileprivate let torchButton: FlashButton = {
		let button = FlashButton(strokeColor: .white, fillColor: UIColor.white.withAlphaComponent(Constants.Defaults.alpha), lineWidth: Constants.Sizes.smallLineWidth, frame: .zero)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()
	
	fileprivate let touchView: UIView = {
		let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: Constants.Sizes.buttonSize / 2.0, height: Constants.Sizes.buttonSize / 2.0))
		view.backgroundColor = UIColor.white.withAlphaComponent(Constants.Defaults.alpha)
		view.layer.borderWidth = Constants.Sizes.smallLineWidth
		view.layer.borderColor = UIColor.white.cgColor
		view.layer.cornerRadius = Constants.Sizes.buttonSize / 4.0
		view.layer.masksToBounds = true
		view.alpha = 0.0
		return view
	}()
	
	public override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
	override public var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
	
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
			
			view.backgroundColor = .black
			
			cancelButton.addTarget(self, action: #selector(cancelAction(_:)), for: .touchUpInside)
			
			view.addSubview(cancelButton)
			view.addSubview(touchView)
			
			if #available(iOS 11.0, *) {
				cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.Edges.cancel.top).isActive = true
			} else {
				cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Edges.cancel.top).isActive = true
			}
			
			let cancelLeft = cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.Edges.cancel.left)
			let cancelWidth = cancelButton.widthAnchor.constraint(equalToConstant: Constants.Sizes.cancel)
			let cancelHeight = cancelButton.heightAnchor.constraint(equalToConstant: Constants.Sizes.cancel)
			
			NSLayoutConstraint.activate([cancelLeft, cancelWidth, cancelHeight])
			
			if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
				torchButton.addTarget(self, action: #selector(toggleTorch(sender:)), for: .touchUpInside)
				
				view.addSubview(torchButton)
				
				let torchWidth = torchButton.widthAnchor.constraint(equalToConstant: Constants.Sizes.buttonSize / 2.0)
				let torchHeight = torchButton.heightAnchor.constraint(equalToConstant: Constants.Sizes.buttonSize / 2.0)
				let torchCenterX = torchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: (view.bounds.width / -4.0) - (Constants.Sizes.buttonSize / 2.0) / 2.0)
				
				if #available(iOS 11, *) {
					torchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.Edges.button.bottom).isActive = true
				} else {
					torchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.Edges.button.bottom).isActive = true
				}
				
				NSLayoutConstraint.activate([torchWidth, torchHeight, torchCenterX])
			}

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
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
		delegate?.scanner(self, didScanCode: code, codeType: codeType)
	}
	
	fileprivate func handleNoCode() {
		recentCode = nil
		recentType = nil
	}
	
	@objc fileprivate func cancelAction(_ sender: UIButton) {
		delegate?.scanner?(self, willDismissScanner: true)
		
		dismiss(animated: true) { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.delegate?.scanner?(weakSelf, didDismissScanner: true)
		}
	}
	
	@objc fileprivate func toggleTorch(sender: UIButton) {
		guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
		
		do {
			try device.lockForConfiguration()
			device.torchMode = device.isTorchActive ? .off : .on
			device.unlockForConfiguration()
		} catch {
			print("Torch could not be used")
		}
	}
	
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first, let device = AVCaptureDevice.default(for: AVMediaType.video), let vf = previewLayer else { return }
		
		let screenSize = vf.bounds.size
		let x = touch.location(in: view).y / screenSize.height
		let y = 1.0 - touch.location(in: view).x / screenSize.width
		let focusPoint = CGPoint(x: x, y: y)
		
		do {
			try device.lockForConfiguration()
			
			device.focusPointOfInterest = focusPoint
			device.focusMode = .autoFocus
			device.exposurePointOfInterest = focusPoint
			device.exposureMode = .continuousAutoExposure
			device.unlockForConfiguration()
		} catch { }
	}
	
	override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		
		touchView.center = touch.location(in: view)
		touchView.alpha = 1.0
		
		UIView.animate(withDuration: 0.5, animations: {
			self.touchView.alpha = 0.0
		})
	}
}

extension CodeScanner: AVCaptureMetadataOutputObjectsDelegate {
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
			handleNoCode()
		}
	}
}
