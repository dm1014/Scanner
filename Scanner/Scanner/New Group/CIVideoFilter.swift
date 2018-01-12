//
//  CIVideoFilter.swift
//  Scanner
//
//  Created by David Martin on 11/7/17.
//  Copyright © 2017 dm Apps. All rights reserved.
//

import Foundation
import UIKit
import GLKit
import AVFoundation
import CoreMedia
import CoreImage
import OpenGLES
import QuartzCore

class CIVideoFilter: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    typealias AppliedFilter = ((CIImage) -> CIImage?)
    var applyFilter: AppliedFilter?
    var videoDisplayView: GLKView
    var videoDisplayViewBounds: CGRect
    var renderContext: CIContext
    var stillImageOutput: AVCapturePhotoOutput?
    var filter: CIFilter?
    
    public var enableGrayscale: Bool = false {
        didSet {
            filter = enableGrayscale ? CIFilter(name: "CIColorMonochrome", withInputParameters: ["inputColor": CIColor(red: 0.5, green: 0.5, blue: 0.5), "inputIntensity": 1.0]) : nil
        }
    }
    
    fileprivate let captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        return session
    }()
    
    fileprivate var hasSetupSession = false
    
    fileprivate let sessionQueue = DispatchQueue(label: "AVSessionQueue")
    
    init(in superview: UIView, applyFilterCallback: AppliedFilter?) {
        self.applyFilter = applyFilterCallback
        
        videoDisplayView = GLKView(frame: UIScreen.main.bounds, context: EAGLContext(api: .openGLES2)!)
        videoDisplayView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2.0))
        videoDisplayView.frame = UIScreen.main.bounds
        
        superview.addSubview(videoDisplayView)
        superview.sendSubview(toBack: videoDisplayView)
        
        renderContext = CIContext(eaglContext: videoDisplayView.context)
        
        videoDisplayView.bindDrawable()
        videoDisplayViewBounds = CGRect(x: 0, y: 0, width: videoDisplayView.drawableWidth, height: videoDisplayView.drawableHeight)
    }
    
    deinit {
        stopFiltering()
        hasSetupSession = false
    }
    
    func startFiltering() throws {
        if !hasSetupSession {
            do {
                try createSession()
                hasSetupSession = true
            } catch {
                throw "Failed to setup session. Make sure you have allowed camera access"
            }
        }
        
        captureSession.startRunning()
    }
    
    func stopFiltering() {
        captureSession.stopRunning()
    }
    
    fileprivate func createSession() throws {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            throw "Failed to get camera. Make sure you have allowed camera access."
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        if captureSession.canAddOutput(stillImageOutput!) {
            captureSession.addOutput(stillImageOutput!)
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        
        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer, options: [kCIImageColorSpace: NSNull()])
        
        filter?.setValue(sourceImage, forKey: kCIInputImageKey)
    
        var outputImage = filter?.outputImage ?? sourceImage
        
        let detectionResult = applyFilter?(outputImage)
        
        if let result = detectionResult {
            outputImage = result
        }
        
        var drawFrame = outputImage.extent
        let imageAR = drawFrame.width / drawFrame.height
        let viewAR = videoDisplayViewBounds.width / videoDisplayViewBounds.height
        
        if imageAR > viewAR {
            drawFrame.origin.x += (drawFrame.width - drawFrame.height * viewAR) / 2.0
            drawFrame.size.width = drawFrame.height / viewAR
        } else {
            drawFrame.origin.y += (drawFrame.height - drawFrame.width / viewAR) / 2.0
            drawFrame.size.height = drawFrame.width / viewAR
        }
        
        videoDisplayView.bindDrawable()
        
        if videoDisplayView.context != EAGLContext.current() {
            EAGLContext.setCurrent(videoDisplayView.context)
        }
        
        glClearColor(0.5, 0.5, 0.5, 1.0)
        glClear(0x000040000)
        glEnable(0x0BE2)
        glBlendFunc(1, 0x0303)
        
        renderContext.draw(outputImage, in: videoDisplayViewBounds, from: drawFrame)
        
        videoDisplayView.display()
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
