import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @State var isPresented = false
    var body: some View {
        Button(action: {
            self.isPresented = true
        }, label: {
            Text("Camera")
        }).sheet(isPresented: $isPresented) {
            CameraRepresentableView()
        }
    }
}

struct CameraRepresentableView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraRepresentableView>) -> ViewController {
        let vc = ViewController()
        return vc
    }
    func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<CameraRepresentableView>) {
    }
}

class ViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    var cameraButtonPressed = false
    let captureSession = AVCaptureSession()
    var previewLayer  : CALayer!
    var captureDevice : AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width/2 - 24, y: UIScreen.main.bounds.height - 150, width: 60, height: 60))
        button.backgroundColor = .orange
        button.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        prepareCamera()
        self.view.addSubview(button)
    }
    
    func prepareCamera(){
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        if let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices as? [AVCaptureDevice]{
            captureDevice = availableDevices.first
            beginSession()
        }
    }
    
    func beginSession(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch{
            print(error.localizedDescription)
        }
        
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) as? AVCaptureVideoPreviewLayer{
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value: kCVPixelFormatType_32BGRA)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput){
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "My Camera")
            dataOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate,queue: queue)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if cameraButtonPressed {
            cameraButtonPressed = false
            print(sampleBuffer)
        }
    }
    
    @objc func captureButtonPressed(){
        cameraButtonPressed = true
        
    }
}
