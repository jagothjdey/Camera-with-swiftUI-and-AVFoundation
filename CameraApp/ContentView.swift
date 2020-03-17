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
        }.edgesIgnoringSafeArea(.all)
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
    var takePhoto = false
    var prevImageButton : UIButton!
    let captureSession = AVCaptureSession()
    var previewLayer  : CALayer!
    var captureDevice : AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let innerButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width/2 - 27, y: UIScreen.main.bounds.height - 130, width: 50, height: 50))
        innerButton.backgroundColor = .orange
        innerButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        innerButton.layer.cornerRadius = 0.5 * innerButton.bounds.size.width
        innerButton.clipsToBounds = true
        prepareCamera()
        self.view.addSubview(innerButton)
        
        let outerButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width/2 - 34.5, y: UIScreen.main.bounds.height - 137, width: 65, height: 65))
        outerButton.backgroundColor = .clear
        outerButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        outerButton.layer.cornerRadius = 0.5 * outerButton.bounds.size.width
        outerButton.clipsToBounds = true
        outerButton.layer.borderWidth = 3
        outerButton.layer.borderColor = UIColor.white.cgColor
        self.view.addSubview(outerButton)
        
        prevImageButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 80, y: UIScreen.main.bounds.height - 135, width: 65, height: 65))
        prevImageButton.backgroundColor = .clear
        prevImageButton.layer.cornerRadius = 0.5 * prevImageButton.bounds.size.width
        prevImageButton.clipsToBounds = true
        self.view.addSubview(prevImageButton)
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
            self.previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.view.layer.addSublayer(self.previewLayer)
            captureSession.startRunning()
            
            /*previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            previewLayer.frame = view.frame**/
            
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
        if takePhoto {
            takePhoto = false
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer){
                let jpegData = image.jpegData(compressionQuality: 1.0)
                print(jpegData)
                DispatchQueue.main.async {
                    self.prevImageButton.setImage(image, for: .normal)
                }
                //  make api calls here to store in database or passing to backend
            }
        }
    }
    
    func getImageFromSampleBuffer(buffer : CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect){
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    @objc func captureButtonPressed(){
        takePhoto = true
    }
}
