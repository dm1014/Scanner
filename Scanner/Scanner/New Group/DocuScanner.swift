//
//  DocuScanner.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

@objc public protocol DocuScannerDelegate: class {
	func docuScanner(_ scanner: DocuScanner, captured image: UIImage)
	func docuScanner(_ scanner: DocuScanner, handleError error: Error?)
	@objc optional func willDismissScanner(_ scanner: DocuScanner)
	@objc optional func didDismissScanner(_ scanner: DocuScanner)
}

public final class DocuScanner: UIViewController {
    fileprivate struct Corners {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
        let size: CGSize
        
        init(from feature: CIRectangleFeature) {
            self.topLeft = feature.topLeft
            self.topRight = feature.topRight
            self.bottomLeft = feature.bottomLeft
            self.bottomRight = feature.bottomRight
            self.size = feature.bounds.size
        }
    }
    
    fileprivate enum Constants {
        static let buttonSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 96.0 : 72.0
        static let margin: CGFloat = 20.0
        static let smallLineWidth: CGFloat = 1.5
        static let normalLineWidth: CGFloat = 3.0
        static let alpha: CGFloat = 0.25
    }
    
    fileprivate let cameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    fileprivate let captureButton: CircleButton = {
        let button = CircleButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(Constants.alpha)
        button.layer.borderWidth = Constants.normalLineWidth
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    fileprivate let grayscaleButton: GrayscaleView = {
        let button = GrayscaleView()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Constants.buttonSize / 4.0
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = Constants.smallLineWidth
        return button
    }()
    
    fileprivate let torchButton: FlashButton = {
        let button = FlashButton(strokeColor: .white, fillColor: UIColor.white.withAlphaComponent(Constants.alpha), lineWidth: Constants.smallLineWidth, frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate let touchView: UIView = {
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: Constants.buttonSize / 2.0, height: Constants.buttonSize / 2.0))
        view.backgroundColor = UIColor.white.withAlphaComponent(Constants.alpha)
        view.layer.borderWidth = Constants.smallLineWidth
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.cornerRadius = Constants.buttonSize / 4.0
        view.layer.masksToBounds = true
        view.alpha = 0.0
        return view
    }()
    
    fileprivate var videoFilter: CIVideoFilter?
    
    fileprivate let rectDetector: CIDetector? = {
        let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0]
        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
    }()
    
    fileprivate let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
    
    fileprivate var overlayCorners: Corners?
    fileprivate var videoImage: CIImage?
    fileprivate var hasEnabledGrayscale = false
    fileprivate var currentAngle: CGFloat = 0.0
    
    public weak var delegate: DocuScannerDelegate?
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		
		view.backgroundColor = .black
		
		
		setupViews()
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		let cancelButton = UIBarButtonItem(image: #imageLiteral(resourceName: "X"), style: .plain, target: self, action: #selector(cancelAction(_:)))
		navigationItem.leftBarButtonItem = cancelButton

	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    fileprivate func setupViews() {
        view.addSubview(captureButton)
        view.addSubview(grayscaleButton)
        view.addSubview(touchView)

		captureButton.addTarget(self, action: #selector(captureImage(sender:)), for: .touchUpInside)
		grayscaleButton.addTarget(self, action: #selector(handleGrayscale(sender:)), for: .touchUpInside)
        
        let capWidth = captureButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize)
        let capHeight = captureButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize)
        let capCenterX = captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let capBottom = captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.margin)
        
        let grayWidth = grayscaleButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize / 2.0)
        let grayHeight = grayscaleButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize / 2.0)
        let grayCenterX = grayscaleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: (view.bounds.width / 4.0) + (Constants.buttonSize / 2.0) / 2.0)
        let grayCenterY = grayscaleButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor)
        
        NSLayoutConstraint.activate([capWidth, capHeight, capCenterX, capBottom,
                                     grayWidth, grayHeight, grayCenterX, grayCenterY])
        
        if let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch {
            torchButton.addTarget(self, action: #selector(toggleTorch(sender:)), for: .touchUpInside)
            
            view.addSubview(torchButton)
            
            let torchWidth = torchButton.widthAnchor.constraint(equalToConstant: Constants.buttonSize / 2.0)
            let torchHeight = torchButton.heightAnchor.constraint(equalToConstant: Constants.buttonSize / 2.0)
            let torchCenterX = torchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: (view.bounds.width / -4.0) - (Constants.buttonSize / 2.0) / 2.0)
            let torchCenterY = torchButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor)

            NSLayoutConstraint.activate([torchWidth, torchHeight, torchCenterX, torchCenterY])
        }
        
        videoFilter = CIVideoFilter(in: view, applyFilterCallback: nil)
        videoFilter?.applyFilter = { image in
            return self.performRectangleDetection(image: image)
        }
        
        do {
            try videoFilter?.startFiltering()
        } catch {
            delegate?.docuScanner(self, handleError: error)
        }
    }
    
    fileprivate func performRectangleDetection(image: CIImage) -> CIImage? {
        guard let detector = rectDetector, let features = detector.features(in: image) as? [CIRectangleFeature] else { return nil }
        
        var resultImage: CIImage?
        
        for feature in features {
            resultImage = drawHighlightOverlayForPoints(image: image, corners: Corners(from: feature))
        }
        
        return resultImage
    }
    
    fileprivate func drawHighlightOverlayForPoints(image: CIImage, corners: Corners) -> CIImage? {
        var overlay = CIImage(color: CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5))
        overlay = overlay.cropped(to: image.extent)
        overlay = overlay.applyingFilter("CIPerspectiveTransformWithExtent", parameters: [
            "inputExtent": CIVector(cgRect: image.extent),
            "inputTopLeft": CIVector(cgPoint: corners.topLeft),
            "inputTopRight": CIVector(cgPoint: corners.topRight),
            "inputBottomLeft": CIVector(cgPoint: corners.bottomLeft),
            "inputBottomRight": CIVector(cgPoint: corners.bottomRight)
        ])
        overlayCorners = corners
        videoImage = image

        return overlay.composited(over: image)
    }
    
    @objc fileprivate func captureImage(sender: UIButton) {
        guard let image = videoImage, let corners = overlayCorners else { return }
        
        let x = min(corners.topLeft.x, corners.bottomLeft.x)
        let y = min(corners.topLeft.y, corners.topRight.y)
        let width = max(corners.topRight.x, corners.bottomRight.x) - x
        let height = max(corners.bottomLeft.y, corners.bottomRight.y) - y
        
        let cropped = image.cropped(to: CGRect(x: x, y: y, width: width, height: height))
		
		guard let cgImage = videoFilter?.renderContext.createCGImage(cropped, from: cropped.extent) else { return }
		let capturedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        delegate?.docuScanner(self, captured: capturedImage)
    }
    
    @objc fileprivate func handleGrayscale(sender: UIButton) {
        hasEnabledGrayscale = !hasEnabledGrayscale
        videoFilter?.enableGrayscale = hasEnabledGrayscale
        
        let newAngle = hasEnabledGrayscale ? CGFloat(Double.pi) : -CGFloat(Double.pi)

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = currentAngle
        rotationAnimation.toValue = currentAngle + newAngle
        rotationAnimation.duration = 0.25
        rotationAnimation.fillMode = kCAFillModeForwards
        rotationAnimation.isRemovedOnCompletion = false
        currentAngle += newAngle
        
        self.grayscaleButton.layer.add(rotationAnimation, forKey: nil)
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
	
	@objc fileprivate func cancelAction(_ sender: UIBarButtonItem) {
		delegate?.willDismissScanner?(self)
		
		dismiss(animated: true) { [weak self] in
			guard let weakSelf = self else { return }
			weakSelf.delegate?.didDismissScanner?(weakSelf)
		}
	}
    
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let device = AVCaptureDevice.default(for: AVMediaType.video), let vf = videoFilter else { return }
        
        let videoView = vf.videoDisplayView
        let screenSize = videoView.bounds.size
        let x = touch.location(in: videoView).y / screenSize.height
        let y = 1.0 - touch.location(in: videoView).x / screenSize.width
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
