@preconcurrency import AVFoundation
import Observation

/// A minimal front-camera session, used only to keep the camera capture accessory active.
@Observable
@MainActor
final class CameraSessionModel {
  enum Status {
    case starting, running, denied, unavailable
  }

  @ObservationIgnored let session = AVCaptureSession()
  @ObservationIgnored private let captureQueue = DispatchQueue(label: "Basis.camera")

  private(set) var status = Status.starting

  func start() async {
    let authorized: Bool
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: authorized = true
    case .notDetermined: authorized = await AVCaptureDevice.requestAccess(for: .video)
    default: authorized = false
    }
    guard authorized else {
      status = .denied
      return
    }

    status = .starting
    let session = session
    let started = await withCheckedContinuation { continuation in
      captureQueue.async {
        let configured = Self.configure(session)
        if configured && !session.isRunning {
          session.startRunning()
        }
        continuation.resume(returning: configured && session.isRunning)
      }
    }
    status = started ? .running : .unavailable
  }

  func stop() {
    let session = session
    captureQueue.async {
      if session.isRunning { session.stopRunning() }
    }
  }

  nonisolated private static func configure(_ session: AVCaptureSession) -> Bool {
    session.beginConfiguration()
    session.sessionPreset = .high
    defer { session.commitConfiguration() }

    if session.inputs.isEmpty {
      guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        ?? AVCaptureDevice.default(for: .video),
        let input = try? AVCaptureDeviceInput(device: device),
        session.canAddInput(input)
      else { return false }
      session.addInput(input)
    }

    if session.outputs.isEmpty {
      let output = AVCapturePhotoOutput()
      guard session.canAddOutput(output) else { return false }
      session.addOutput(output)
    }
    return true
  }
}
