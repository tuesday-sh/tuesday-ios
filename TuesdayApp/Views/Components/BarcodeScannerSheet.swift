import SwiftUI
import AVFoundation

/// Live hardware barcode / QR code scanner powered by `AVCaptureSession` + `AVCaptureMetadataOutput`
/// and normalized by `BarcodeIdentifierParser`. Includes a Simulator / camera-unavailable fallback.
public struct BarcodeScannerSheet: View {
    public let palette: BrandPalette
    public let onScanned: (ParsedBarcodeResult) -> Void
    public let onDismiss: () -> Void

    @State private var manualFallbackCode: String = ""
    @State private var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    public init(
        palette: BrandPalette,
        onScanned: @escaping (ParsedBarcodeResult) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.palette = palette
        self.onScanned = onScanned
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if Self.isCameraAvailable && (authorizationStatus == .authorized || authorizationStatus == .notDetermined) {
                    ZStack {
                        LiveBarcodeCaptureView(onCodeScanned: { result in
                            onScanned(result)
                        })
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))

                        RoundedRectangle(cornerRadius: 10)
                            .stroke(palette.accent, lineWidth: 2)
                            .frame(width: 240, height: 150)
                    }
                    .padding(.horizontal, 16)

                    Text("Align your hardware box UPC, FCC QR code, or serial barcode inside the frame.")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 42))
                            .foregroundColor(palette.accentText)

                        Text(Self.isCameraAvailable ? "Camera Access Needed" : "Camera Unavailable in Simulator")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.textPrimary)

                        Text(Self.isCameraAvailable
                             ? "Enable Camera permission in Settings, or type a UPC / QR string below to test lookup."
                             : "Type or paste a UPC retail barcode, serial, or QR payload below to simulate a scan.")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textMuted)
                            .multilineTextAlignment(.center)

                        TuesdayTextField(
                            text: $manualFallbackCode,
                            label: "Barcode / UPC / QR Value",
                            placeholder: "e.g. 817882027373",
                            palette: palette
                        )

                        Button(action: {
                            if let parsed = BarcodeIdentifierParser.parse(rawValue: manualFallbackCode, is2DMatrix: false) {
                                onScanned(parsed)
                            }
                        }) {
                            Text("Apply Scanned Code")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        }
                        .buttonStyle(.plain)
                        .disabled(manualFallbackCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                }

                Spacer()
            }
            .padding(.top, 16)
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Scan Barcode or QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(palette.accentText)
                }
            }
            .onAppear {
                if authorizationStatus == .notDetermined && Self.isCameraAvailable {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            authorizationStatus = granted ? .authorized : .denied
                        }
                    }
                }
            }
        }
    }

    private static var isCameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}

private struct LiveBarcodeCaptureView: UIViewControllerRepresentable {
    let onCodeScanned: (ParsedBarcodeResult) -> Void

    func makeUIViewController(context: Context) -> BarcodeCameraViewController {
        let vc = BarcodeCameraViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeCameraViewController, context: Context) {}
}

private final class BarcodeCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((ParsedBarcodeResult) -> Void)?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didEmit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        let supported: [AVMetadataObject.ObjectType] = [
            .ean13, .ean8, .upce, .code128, .code39, .code93, .qr, .dataMatrix, .aztec, .pdf417
        ].filter { output.availableMetadataObjectTypes.contains($0) }
        output.metadataObjectTypes = supported

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmit,
              let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let raw = readable.stringValue,
              let parsed = BarcodeIdentifierParser.parse(rawValue: raw, metadataType: readable.type) else {
            return
        }
        didEmit = true
        session.stopRunning()
        onCodeScanned?(parsed)
    }
}
