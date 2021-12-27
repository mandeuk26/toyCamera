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
    
    private var blackShutterView: UIView = {
        let shutterView = UIView()
        shutterView.backgroundColor = .black
        shutterView.alpha = 0
        shutterView.translatesAutoresizingMaskIntoConstraints = false
        return shutterView
    }()
    
    private var captureButton: UIButton = {
        let captureButton = UIButton()
        captureButton.setImage(UIImage(systemName: "camera.aperture"), for: .normal)
        captureButton.contentHorizontalAlignment = .fill
        captureButton.contentVerticalAlignment = .fill
        captureButton.tintColor = .white
        captureButton.backgroundColor = .black
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        return captureButton
    }()
    
    private var positionSwitchButton: UIButton = {
        let switchButton = UIButton()
        switchButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchButton.contentHorizontalAlignment = .fill
        switchButton.contentVerticalAlignment = .fill
        switchButton.tintColor = .white
        switchButton.backgroundColor = .black
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        return switchButton
    }()
    
    private var captureImageView: UIImageView = {
        let captureImageView = UIImageView()
        captureImageView.translatesAutoresizingMaskIntoConstraints = false
        captureImageView.alpha = 0
        return captureImageView
    }()
    
    private let session = AVCaptureSession()
    private var captureOutput: AVCapturePhotoOutput = {
        let captureOutput = AVCapturePhotoOutput()
        captureOutput.isHighResolutionCaptureEnabled = true
        return captureOutput
    }()
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        super.loadView()
        self.view = .init()
        self.view.backgroundColor = .black
        self.view.addSubview(self.previewView)
        self.view.addSubview(self.blackShutterView)
        self.view.addSubview(self.captureButton)
        self.view.addSubview(self.positionSwitchButton)
        self.view.addSubview(self.captureImageView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            
            self.blackShutterView.topAnchor.constraint(equalTo: self.previewView.topAnchor),
            self.blackShutterView.bottomAnchor.constraint(equalTo: self.previewView.bottomAnchor),
            self.blackShutterView.leftAnchor.constraint(equalTo: self.previewView.leftAnchor),
            self.blackShutterView.rightAnchor.constraint(equalTo: self.previewView.rightAnchor),
            
            self.captureButton.topAnchor.constraint(equalTo: self.previewView.bottomAnchor, constant: 40),
            self.captureButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.captureButton.widthAnchor.constraint(equalToConstant: 44),
            self.captureButton.heightAnchor.constraint(equalToConstant: 44),
            
            self.captureImageView.widthAnchor.constraint(equalToConstant: 44),
            self.captureImageView.heightAnchor.constraint(equalToConstant: 44),
            self.captureImageView.centerYAnchor.constraint(equalTo: self.captureButton.centerYAnchor),
            self.captureImageView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.positionSwitchButton.widthAnchor.constraint(equalToConstant: 30),
            self.positionSwitchButton.heightAnchor.constraint(equalToConstant: 24),
            self.positionSwitchButton.bottomAnchor.constraint(equalTo: self.previewView.topAnchor, constant: -40),
            self.positionSwitchButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20)
        ])
    }
    
    private func configureCancellables() {
        self.captureButton.publisher(for: .touchUpInside)
            .sink { [weak self] in
                guard let self = self else { return }
                
                let photoSettings: AVCapturePhotoSettings
                if self.captureOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    photoSettings = AVCapturePhotoSettings()
                }
                photoSettings.flashMode = .off
                self.captureOutput.capturePhoto(with: photoSettings, delegate: self)
            }
            .store(in: &self.cancellables)
        
        self.positionSwitchButton.publisher(for: .touchUpInside)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let currentInput = self?.session.inputs.first as? AVCaptureDeviceInput else { return }
                self?.session.beginConfiguration()
                self?.session.removeInput(currentInput)

                guard let camera = self?.camera(position: currentInput.device.position == .front ? .back : .front),
                      let nextInput = try? AVCaptureDeviceInput(device: camera),
                      let isAddPossible = self?.session.canAddInput(nextInput),
                      let previewView = self?.previewView,
                      isAddPossible
                else { return }
                self?.session.addInput(nextInput)
                UIView.transition(with: previewView, duration: 0.5, options: .transitionFlipFromLeft) {
                    self?.session.commitConfiguration()
                }
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
        let captureDevice = camera(position: .back)
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
              self.session.canAddInput(captureDeviceInput),
              self.session.canAddOutput(self.captureOutput)
        else { return }
        self.session.addInput(captureDeviceInput)
        self.session.sessionPreset = .photo
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
                .builtInDualCamera,
                .builtInWideAngleCamera,
                .builtInTrueDepthCamera
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
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async { [weak self] in
            UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                    self?.blackShutterView.alpha = 1
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self?.blackShutterView.alpha = 0
                }
            }
        }
    }
    
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
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
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
