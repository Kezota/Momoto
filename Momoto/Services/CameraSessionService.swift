//
//  CameraSessionService.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
final class CameraSessionService: NSObject, ObservableObject { //NSObject untuk pakai delegate
    override init() {
        super.init()
    }
    enum AccessState {
        case notDetermined
        case denied
        case allowed
    }
    @Published private(set) var accessState: AccessState = .notDetermined //UI can read but not write
    @Published private(set) var isRunning: Bool = false
    @Published var isTorchOn: Bool = false {  //flash camera
        didSet { applyTorch() } //runs everytime the value change
    }
    
    nonisolated let session = AVCaptureSession()
      nonisolated private let sessionQueue = DispatchQueue(label: "com.momoto.camera.session") //create a separate worker thread so no freeze
      nonisolated private let photoOutput = AVCapturePhotoOutput() //pHasil foto
    private var captureContinuation: CheckedContinuation<UIImage?, Never>? // a continuation that will eventually return a UIImage? and can never throw an error (Never)
    
    //The outer ? — it's NIL when no photo capture is in progress, non-nil while waiting
    
    func bootstrap() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {  //check if permission is good
        case .authorized:
            accessState = .allowed
            configureAndStart() //Functionnya ada dibawah
        case .notDetermined:
              AVCaptureDevice.requestAccess(for: .video) { allowed in
                  Task { @MainActor [weak self] in
                      guard let self else { return }
                      self.accessState = allowed ? .allowed : .denied
                      if allowed { self.configureAndStart() }
                  }
              }
        case .denied, .restricted:
            accessState = .denied
        @unknown default:
            accessState = .denied
        }
    }
    
    func stop() { //.onDisappear
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in self.isRunning = false }
        }
    }
    func capturePhoto() async -> UIImage? {   //takes a photo and waits for the result,
        guard accessState == .allowed else { return nil }
        return await withCheckedContinuation { continuation in
            self.captureContinuation = continuation
            sessionQueue.async { [weak self] in
                guard let self else { return }
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    private func configureAndStart() { //wires the camera input device into the session and starts streaming.  Bisa ganti ganti kamera default disini
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            if self.session.inputs.isEmpty,
               let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), //Atur pake kamera yg mana
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.outputs.isEmpty, self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            if !self.session.isRunning {
                self.session.startRunning()
            }
            Task { @MainActor in self.isRunning = self.session.isRunning }
            
        }
    }
    
    private func applyTorch() {   //For flash
        sessionQueue.async { [ isTorchOn] in
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = isTorchOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                //no need
            }
        }
    }
}

extension CameraSessionService: @preconcurrency AVCapturePhotoCaptureDelegate {  //AVFoundation calls when a photo finishes processing
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let image: UIImage? = {
            guard error == nil, let data = photo.fileDataRepresentation() else {
                return nil
            }
            return UIImage(data: data)
        }()
        Task{ @MainActor in
            self.captureContinuation?.resume(returning: image)
            self.captureContinuation = nil
        }
    }
}
