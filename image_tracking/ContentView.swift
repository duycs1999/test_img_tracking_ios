import SwiftUI
import RealityKit
import ARKit
import AVKit

extension ARView
{
    func setupImageDetectionConfigs()
    {
        // image to track
        guard let imagesToDetect = ARReferenceImage.referenceImages(inGroupNamed: "Pics", bundle: Bundle.main)
        else
        {
            fatalError("Missing expected asset catalog resources.")
        }
    
        //configure image detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = imagesToDetect
        configuration.maximumNumberOfTrackedImages = 1
        self.session.run(configuration)
    }
}


struct ContentView : View
{
    var body: some View
    {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable
{
   
    let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(parent: self)
    }
    
    // implement this method and use it to create your view object -- called initially once
    func makeUIView(context: Context) -> ARView
    {
        arView.setupImageDetectionConfigs()
        //Assigns coordinator to delegate the ARViewContainer
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    
    // delegate for AR view representable
    class Coordinator: NSObject, ARSessionDelegate
    {
        var parent: ARViewContainer
        var videoPlayer: AVPlayer!
       

        init(parent: ARViewContainer)
        {
            self.parent = parent
        }
        
        // this method is called when an anchor has been added to the AR session
        func session(_ session: ARSession, didAdd anchors: [ARAnchor])
        {
            //print("image detected!")
            
            // if an ARImageAnchor exists, store it in a variable
            guard let imageAnchor = anchors[0] as? ARImageAnchor
            // print an error code if the app cannot load the image anchor
            else
            {
                print("Problems loading anchor")
                return
            }
            
            //Assigns video to be overlaid
            guard let path = Bundle.main.path(forResource: "video", ofType: "MP4")
            else
            {
                print("Unable to find video file")
                return
            }
            
            let videoURL = URL(fileURLWithPath: path)
            let playerItem = AVPlayerItem(url: videoURL)
            videoPlayer=AVPlayer(playerItem: playerItem)
            let videoMaterial = VideoMaterial(avPlayer: videoPlayer)
            var height = Float(imageAnchor.referenceImage.physicalSize.height)
            let width = height*3/4

//            height.negate()
            
            //Sets the aspect ratio of the video to be played, and the corner radius of the video
            let videoPlane = ModelEntity(mesh: .generatePlane(width: width, depth: height, cornerRadius: 0.2), materials: [videoMaterial])
            
            //Assigns reference image that will be detected
            if let imageName = imageAnchor.name, imageName  == "vds_img"
            {
                let anchor = AnchorEntity(world: imageAnchor.transform)
                anchor.addChild(videoPlane)
                videoPlane.setPosition(SIMD3(x: 0 ,y: 0 ,z: 0), relativeTo: anchor)
                parent.arView.scene.addAnchor(anchor)
                videoPlayer.play()
            }
        }
    }
    
    // SwiftUI calls this method for any changes affecting the corresponding SwiftUI view
    func updateUIView(_ uiView: ARView, context: Context)
    {}
}
