//
//  ViewController.swift
//  toyCamera
//
//  Created by 강현준 on 2021/12/23.
//

import AVFoundation
import Combine
import UIKit

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
    
    private var captureImageView: UIImageView = {
        let captureImageView = UIImageView()
        captureImageView.translatesAutoresizingMaskIntoConstraints = false
        captureImageView.alpha = 0
        return captureImageView
    }()
    
    private let session = AVCaptureSession()
    private var captureOutput = AVCapturePhotoOutput()
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        self.view = .init()
        self.view.backgroundColor = .white
        self.view.addSubview(self.previewView)
        self.view.addSubview(self.captureButton)
        self.view.addSubview(self.captureImageView)
    }
    
    override func viewDidLoad() {
        self.configureLayouts()
        self.configureCancellables()
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
            self.captureButton.heightAnchor.constraint(equalToConstant: 44),
            
            self.captureImageView.widthAnchor.constraint(equalToConstant: 44),
            self.captureImageView.heightAnchor.constraint(equalToConstant: 44),
            self.captureImageView.centerYAnchor.constraint(equalTo: self.captureButton.centerYAnchor),
            self.captureImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30)
        ])
    }
    
    private func configureCancellables() {
        self.captureButton.publisher(for: .touchUpInside)
            .sink { [weak self] in
                guard let self = self else { return }
                let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                photoSettings.flashMode = .off
                self.captureOutput.capturePhoto(with: photoSettings, delegate: self)
            }
            .store(in: &self.cancellables)
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
        self.session.sessionPreset = .photo
        
        let captureDevice = camera(position: .back)
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              self.session.canAddInput(captureDeviceInput)
        else { return }
        self.session.addInput(captureDeviceInput)
        
        guard self.session.canAddOutput(self.captureOutput) else { return }
        self.session.addOutput(self.captureOutput)
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

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let uiImage = UIImage(data: imageData, scale: 1.0) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        
        DispatchQueue.main.async { [weak self] in
            guard let initialFrame = self?.previewView.frame,
                  let finalFrame = self?.captureImageView.frame
            else { return }
            
            let imageView = UIImageView(frame: initialFrame)
            imageView.image = uiImage
            self?.view.addSubview(imageView)
            
            UIView.animateKeyframes(withDuration: 5.0, delay: 0) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/80) {
                    imageView.frame = finalFrame
                }
                UIView.addKeyframe(withRelativeStartTime: 9/10, relativeDuration: 1/10) {
                    imageView.alpha = 0
                }
            } completion: { isSuccess in
                if isSuccess { imageView.removeFromSuperview() }
            }
        }
    }
}
