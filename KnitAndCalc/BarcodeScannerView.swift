//
//  BarcodeScannerView.swift
//  KnitAndCalc
//
//  Barcode and OCR scanner using iOS native capabilities
//

import SwiftUI
import AVFoundation
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scannedCode: String
    @Binding var scannedText: String
    let onBarcodeScanned: ((String) -> Void)?
    let onTextRecognized: ((String) -> Void)?
    let showOCR: Bool

    @State private var isShowingScanner = false

    init(scannedCode: Binding<String>, scannedText: Binding<String>, showOCR: Bool = false, onBarcodeScanned: ((String) -> Void)? = nil, onTextRecognized: ((String) -> Void)? = nil) {
        self._scannedCode = scannedCode
        self._scannedText = scannedText
        self.showOCR = showOCR
        self.onBarcodeScanned = onBarcodeScanned
        self.onTextRecognized = onTextRecognized
    }

    var body: some View {
        NavigationView {
            VStack {
                if #available(iOS 16.0, *), showOCR, DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    DataScannerRepresentable(
                        recognizedDataTypes: [.barcode(), .text()],
                        recognizesMultipleItems: false,
                        onBarcodeScanned: { code in
                            scannedCode = code
                            onBarcodeScanned?(code)
                            dismiss()
                        },
                        onTextRecognized: { text in
                            scannedText = text
                            onTextRecognized?(text)
                            dismiss()
                        }
                    )
                } else {
                    // Fallback to basic barcode scanner
                    CameraView(scannedCode: $scannedCode) { code in
                        onBarcodeScanned?(code)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - DataScanner (iOS 16+)
@available(iOS 16.0, *)
struct DataScannerRepresentable: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    let onBarcodeScanned: (String) -> Void
    let onTextRecognized: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned, onTextRecognized: onTextRecognized)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeScanned: (String) -> Void
        let onTextRecognized: (String) -> Void

        init(onBarcodeScanned: @escaping (String) -> Void, onTextRecognized: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
            self.onTextRecognized = onTextRecognized
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let payloadString = barcode.payloadStringValue {
                    onBarcodeScanned(payloadString)
                }
            case .text(let text):
                onTextRecognized(text.transcript)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Basic Camera View (Barcode Only)
struct CameraView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        @Binding var scannedCode: String
        let onCodeScanned: (String) -> Void

        init(scannedCode: Binding<String>, onCodeScanned: @escaping (String) -> Void) {
            self._scannedCode = scannedCode
            self.onCodeScanned = onCodeScanned
        }

        func didScanBarcode(_ code: String) {
            scannedCode = code
            onCodeScanned(code)
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func didScanBarcode(_ code: String)
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraViewControllerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128, .code39, .code93, .upce]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanBarcode(stringValue)
        }
    }
}
