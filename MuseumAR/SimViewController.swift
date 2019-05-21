//
//  ViewController.swift
//  MuseumAR
//
//  Created by Andrew Hart on 13/05/2019.
//  Copyright © 2019 Dent Reality. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class SimViewController: UIViewController, ARSCNViewDelegate {
    let sceneView = ARSCNView()
	
	let artworkNode = SCNNode()
	
	let beacon1Node = BeaconNode()
	
	let titleView = UIView()
	var titleNode: ScalingInterfaceNode!
	
	private static let titleLabelInset: CGFloat = 8
	private static let titleLabelSubtitleDifference: CGFloat = 4
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
		view.addSubview(sceneView)
		
		let image = UIImage(named: "testStudio.jpg")
		sceneView.scene.lightingEnvironment.contents = image
		
		let paintingImage = UIImage(named: "image1")!
		
//		let simBackgroundImage = SimBackgroundImage(
//			image: UIImage(named: "image1")!,
//			horizontalSpan: Float(60).degreesToRadians)
//		let skyboxImage = simBackgroundImage.skyboxImage()
		
//		sceneView.scene.background.contents = skyboxImage
		
		//Rather than using SimBackgroundImage (for panoramas), we'll use a plane,
		//since our image is flat, rather than a panorama
		//This also allows us to interact with it in 6DOF
		sceneView.scene.background.contents = UIColor.black
		
		let plane = SCNPlane(width: 3.367, height: 2.509)
		plane.firstMaterial?.diffuse.contents = paintingImage
		
		let planeNode = SCNNode(geometry: plane)
		planeNode.position.z = -2
		sceneView.scene.rootNode.addChildNode(planeNode)
		
		let artworkPlane = SCNPlane(width: 2.15, height: 1.13)
		artworkPlane.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.35)
		artworkNode.geometry = artworkPlane
		artworkNode.position.z = 0.1
		planeNode.addChildNode(artworkNode)
		
		beacon1Node.position.z = 0.1
		artworkNode.addChildNode(beacon1Node)
		
		let label = UILabel()
		label.text = "French Fire Rafts Attacking the English Fleet off Quebec"
		label.font = UIFont.boldSystemFont(ofSize: 18)
		label.textAlignment = .center
		label.textColor = UIColor.black
		label.backgroundColor = UIColor.clear
		label.numberOfLines = 0
		label.frame.size = label.sizeThatFits(CGSize(width: 280, height: CGFloat.greatestFiniteMagnitude))
		
		let subheadingLabel = UILabel()
		subheadingLabel.text = "28 June 1759, Samuel Scott"
		subheadingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
		subheadingLabel.textAlignment = .center
		subheadingLabel.textColor = UIColor(white: 0.35, alpha: 1.0)
		subheadingLabel.backgroundColor = UIColor.clear
		subheadingLabel.numberOfLines = 1
		subheadingLabel.sizeToFit()
		
		titleView.addSubview(label)
		titleView.addSubview(subheadingLabel)
		titleView.frame.size = CGSize(
			width: label.frame.size.width + (SimViewController.titleLabelInset * 2),
			height: label.frame.size.height + SimViewController.titleLabelSubtitleDifference +
				subheadingLabel.frame.size.height + (SimViewController.titleLabelInset * 2))
		titleView.backgroundColor = UIColor.white
		titleView.layer.cornerRadius = 18
		label.center.x = titleView.frame.size.width / 2
		label.frame.origin.y = SimViewController.titleLabelInset
		subheadingLabel.center.x = titleView.frame.size.width / 2
		subheadingLabel.frame.origin.y = label.frame.origin.y + label.frame.size.height +
			SimViewController.titleLabelSubtitleDifference
		
		titleNode = ScalingInterfaceNode(view: titleView)
		titleNode.position.z = 0.1
		titleNode.position.y = Float(-(artworkPlane.height * 0.5))
		artworkNode.addChildNode(titleNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		sceneView.frame = view.bounds
	}

    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		guard let currentFrame = sceneView.session.currentFrame,
		let pov = sceneView.pointOfView else {
			return
		}
		
		let imageResolution = currentFrame.camera.imageResolution
		let intrinsics = currentFrame.camera.intrinsics
//		let xFOV = 2 * atan(Float(imageResolution.width)/(2 * intrinsics[0,0]))
		var yFOV = 2 * atan(Float(imageResolution.height)/(2 * intrinsics[1,1]))
		
		DispatchQueue.main.async {
			let visibleYFOVScale = min(
				1,
				(self.sceneView.frame.size.width / self.sceneView.frame.size.height) /
					(imageResolution.height / imageResolution.width))
			
			yFOV *= Float(visibleYFOVScale)
			
			let A = yFOV * 0.5
			let B = Float(180).degreesToRadians - A - Float(90).degreesToRadians
			let a = (sin(A) * 1) / sin(B)
			
			//Visible distance, at a distance from the camera of 1m
			let horizontalVisibleDistance = a * 2
			
			let horizontalDistancePerPoint = horizontalVisibleDistance / Float(self.sceneView.frame.size.width)
			
			let childNodes = self.sceneView.scene.rootNode.recursiveChildNodes()
			let scaleNodes = childNodes.filter({$0 is ScaleNode}) as! [ScaleNode]
			
			for scaleNode in scaleNodes {
				let relativeNodePosition = self.sceneView.scene.rootNode.convertPosition(pov.position, to: scaleNode)
				
				let distanceFromNode = SCNVector3Zero.distance(to: relativeNodePosition)
				
				let scale = horizontalDistancePerPoint * distanceFromNode
				
				scaleNode.contentNode.scale = SCNVector3(scale, scale, scale)
				
				
				
			}
		}
	}
}
