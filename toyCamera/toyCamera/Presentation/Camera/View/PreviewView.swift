//
//  PreviewView.swift
//  toyCamera
//
//  Created by 강현준 on 2021/12/24.
//

import AVFoundation
import UIKit

class PreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        self.previewLayer?.frame = self.bounds
    }

    func bind(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        self.layer.insertSublayer(previewLayer, at: 0)
    }
}
