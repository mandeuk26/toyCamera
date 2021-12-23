//
//  ViewController.swift
//  toyCamera
//
//  Created by 강현준 on 2021/12/23.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    private var previewView: UIView = {
        let previewView = UIView()
        previewView.backgroundColor = .black
        previewView.translatesAutoresizingMaskIntoConstraints = false
        return previewView
    }()
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func loadView() {
        self.view = .init()
        self.view.backgroundColor = .yellow
        self.view.addSubview(self.previewView)
    }
    
    override func viewDidLoad() {
        self.configureLayouts()
        self.checkCameraPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer?.frame = self.previewView.bounds
        self.view.layoutIfNeeded()
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
        session.beginConfiguration()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              session.canAddInput(captureDeviceInput)
        else { return }
        session.addInput(captureDeviceInput)
    
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else { return }
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        session.commitConfiguration()
        
        self.setupPreview()
    }
    
    private func setupPreview() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async {
            self.previewView.layer.insertSublayer(self.previewLayer, at: 0)
            self.previewLayer?.frame = self.previewView.bounds
            self.previewView.layoutIfNeeded()
            self.session.startRunning()
        }
    }
}
