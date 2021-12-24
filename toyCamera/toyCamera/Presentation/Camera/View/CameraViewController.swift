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
    
    private var captureButton: UIButton = {
        let captureButton = UIButton()
        captureButton.setImage(UIImage(named: "CaptureIcon"), for: .normal)
        captureButton.backgroundColor = .white
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        return captureButton
    }()
    
    private let session = AVCaptureSession()

    override func loadView() {
        self.view = .init()
        self.view.backgroundColor = .white
        self.view.addSubview(self.previewView)
        self.view.addSubview(self.captureButton)
    }
    
    override func viewDidLoad() {
        self.configureLayouts()
        self.checkCameraPermission()
    }

    private func configureLayouts() {
        NSLayoutConstraint.activate([
            self.previewView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.previewView.heightAnchor.constraint(equalTo: self.previewView.widthAnchor, multiplier: 4/3),
            self.previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            
            self.captureButton.topAnchor.constraint(equalTo: self.previewView.bottomAnchor, constant: 40),
            self.captureButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.captureButton.widthAnchor.constraint(equalToConstant: 44),
            self.captureButton.heightAnchor.constraint(equalToConstant: 44)
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
