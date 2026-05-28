//
//  GlobeView.swift
//  Travel Buddy
//
//  Created by Agustinus Juan Kurniawan on 28/05/26.
//


import SceneKit
import CoreLocation

class GlobeView: SCNView {
    
    private var earthNode: SCNNode!
    private var pinNode: SCNNode?
    private var rotationAnimation: CAAnimation?
    
    override init(frame: CGRect, options: [String: Any]? = nil) {
        super.init(frame: frame, options: options)
        setupScene()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }
    
    private func setupScene() {
        let scene = SCNScene()
        self.scene = scene
        self.backgroundColor = .clear
        self.antialiasingMode = .multisampling4X
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)
        
        // Directional light
        let sunLight = SCNNode()
        sunLight.light = SCNLight()
        sunLight.light?.type = .directional
        sunLight.light?.color = UIColor(white: 0.9, alpha: 1)
        sunLight.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(sunLight)
        
        // Earth sphere
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 72 // Smooth globe
        
        let material = SCNMaterial()
        material.diffuse.contents = tintedEarthTexture()
        material.specular.contents = UIColor(white: 0.1, alpha: 1)
        material.shininess = 0.1
        sphere.materials = [material]
        
        earthNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(earthNode)
        
        startIdleRotation()
    }
    
    // MARK: - Idle slow rotation
    func startIdleRotation() {
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        rotation.duration = 20
        rotation.repeatCount = .infinity
        earthNode.addAnimation(rotation, forKey: "idleRotation")
        rotationAnimation = rotation
    }
    
    func stopIdleRotation() {
        earthNode.removeAnimation(forKey: "idleRotation", blendOutDuration: 0.5)
    }
    
    // MARK: - Rotate to location and pin
    func rotateToLocation(_ location: CLLocation, completion: (() -> Void)? = nil) {
        stopIdleRotation()
        
        let lat = Float(location.coordinate.latitude)
        let lon = Float(location.coordinate.longitude)
        
        let targetYaw = -lon * (.pi / 180)
        let targetPitch = lat * (.pi / 180)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.completionBlock = {
            self.dropPin(latitude: lat, longitude: lon)
            completion?()
        }
        
        earthNode.eulerAngles = SCNVector3(targetPitch * 0.3, targetYaw, 0)
        SCNTransaction.commit()
    }
    
    // MARK: - Drop Pin at coordinates
    private func dropPin(latitude: Float, longitude: Float) {
        let latRad = latitude * (.pi / 180)
        let lonRad = longitude * (.pi / 180)
        let radius: Float = 1.05
        
        let x = radius * cos(latRad) * cos(lonRad)
        let y = radius * sin(latRad)
        let z = radius * cos(latRad) * sin(lonRad)
        
        let pinGeometry = SCNSphere(radius: 0.04)
        let pinMaterial = SCNMaterial()
        pinMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
        pinMaterial.emission.contents = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.5)
        pinGeometry.materials = [pinMaterial]
        
        pinNode?.removeFromParentNode()
        pinNode = SCNNode(geometry: pinGeometry)
        pinNode?.position = SCNVector3(x, y, z)
        
        // Animate pin drop
        pinNode?.scale = SCNVector3(0, 0, 0)
        earthNode.addChildNode(pinNode!)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        pinNode?.scale = SCNVector3(1, 1, 1)
        SCNTransaction.commit()
        
        // Add pulsing glow ring
        addPulseRing(at: SCNVector3(x, y, z))
    }
    
    private func addPulseRing(at position: SCNVector3) {
        let ring = SCNTorus(ringRadius: 0.06, pipeRadius: 0.008)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.6)
        ring.materials = [mat]
        
        let ringNode = SCNNode(geometry: ring)
        ringNode.position = position
        ringNode.look(at: SCNVector3(0, 0, 0))
        earthNode.addChildNode(ringNode)
        
        // Pulse animation
        let pulse = CABasicAnimation(keyPath: "scale")
        pulse.fromValue = NSValue(scnVector3: SCNVector3(1, 1, 1))
        pulse.toValue = NSValue(scnVector3: SCNVector3(2, 2, 2))
        pulse.duration = 1.2
        pulse.repeatCount = .infinity
        pulse.autoreverses = true
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ringNode.addAnimation(pulse, forKey: "pulse")
    }
    
    private func tintedEarthTexture() -> UIImage? {
        guard let base = UIImage(named: "bluemarble-2048") else { return nil }
        
        let ciImage = CIImage(image: base)!
        
        // Desaturate
        let desaturate = CIFilter(name: "CIColorControls")!
        desaturate.setValue(ciImage, forKey: kCIInputImageKey)
        desaturate.setValue(0.15, forKey: kCIInputSaturationKey)
        desaturate.setValue(0.05, forKey: kCIInputBrightnessKey)
        
        // Tint teal
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(desaturate.outputImage, forKey: kCIInputImageKey)
        colorMatrix.setValue(CIVector(x: 0.7, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0.9, z: 0, w: 0), forKey: "inputGVector")
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1.0, w: 0), forKey: "inputBVector")
        
        let context = CIContext()
        guard let output = colorMatrix.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
