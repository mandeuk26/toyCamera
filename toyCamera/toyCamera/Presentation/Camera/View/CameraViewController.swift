//
//  ViewController.swift
//  toyCamera
//
//  Created by 강현준 on 2021/12/23.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    private var previewView: PreviewView = {
        let previewView = PreviewView()
        previewView.backgroundColor = .black
        previewView.translatesAutoresizingMaskIntoConstraints = false
        return previewView
    }()
    
    private let session = AVCaptureSession()

    override func loadView() {
        self.view = .init()
        self.view.addSubview(self.previewView)
    }
    
    override func viewDidLoad() {
        self.configureLayouts()
        self.checkCameraPermission()
    }

    private func configureLayouts() {
        NSLayoutConstraint.activate([
            self.previewView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { isPossible in
                if isPossible { self.setupCaptureSession() }
            }
        case .denied:
            break
        case .restricted:
            break
        @unknown default:
            fatalError()
        }
    }

    private func setupCaptureSession() {
        self.session.beginConfiguration()
        let captureDevice = camera(position: .back)
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              self.session.canAddInput(captureDeviceInput)
        else { return }
        self.session.addInput(captureDeviceInput)
    
        let photoOutput = AVCapturePhotoOutput()
        guard self.session.canAddOutput(photoOutput) else { return }
        self.session.sessionPreset = .photo
        self.session.addOutput(photoOutput)
        self.session.commitConfiguration()
        
        self.setupPreview()
        self.session.startRunning()
    }
    
    private func setupPreview() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        DispatchQueue.main.async { [weak self] in
            self?.previewView.bind(previewLayer: previewLayer)
        }
    }
    
    private func camera(position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        
        guard let device = discoverySession.devices.first(where: { $0.position == position })
        else { fatalError("Missing Capture Device") }
        return device
    }
}
