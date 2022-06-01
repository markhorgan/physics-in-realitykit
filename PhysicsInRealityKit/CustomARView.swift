//
//  CustomARView.swift
//  PhysicsInRealityKit
//
//  Created by Mark Horgan on 30/05/2022.
//

import RealityKit
import ARKit

class CustomARView: ARView {
    private let colors: [UIColor] = [.green, .red, .blue, .magenta, .yellow]
    private let groundSize: Float = 0.5
    private var spheres: [ModelEntity]!
    private let containerCollisionGroup = CollisionGroup(rawValue: 1 << 0)
    private let sphereCollisionGroup = CollisionGroup(rawValue: 1 << 1)
    private let boxCollisionGroup = CollisionGroup(rawValue: 1 << 2)
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        let anchorEntity = try! Experience.loadScene()
        scene.anchors.append(anchorEntity)
        
        addContainerEntitiesToCollisionGroup(anchorEntity)
        
        spheres = buildSpheres(amount: 5, radius: 0.03)
        for sphere in spheres {
            anchorEntity.addChild(sphere)
        }
        
        let box = buildBox(size: [0.12, 0.06, 0.06], color: .green)
        anchorEntity.addChild(box)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        addCoaching()
    }
    
    @objc required dynamic init?(coder decorder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            let screenLocation = gestureRecognizer.location(in: self)
            var hits = hitTest(screenLocation, query: .nearest, mask: sphereCollisionGroup)
            if hits.count > 0 {
                if let modelEntity = hits[0].entity as? ModelEntity {
                    pushSphere(modelEntity)
                }
            } else {
                hits = hitTest(screenLocation, query: .nearest, mask: boxCollisionGroup)
                if hits.count > 0, let modelEntity = hits[0].entity as? ModelEntity {
                    spinBox(modelEntity)
                }
            }
        }
    }
    
    private func pushSphere(_ modelEntity: ModelEntity) {
        modelEntity.applyLinearImpulse([0, 0, 0.002], relativeTo: modelEntity.parent)
    }
    
    private func spinBox(_ modelEntity: ModelEntity) {
        modelEntity.applyAngularImpulse([0, 0.0002, 0], relativeTo: modelEntity)
    }
    
    private func buildSpheres(amount: Int, radius: Float) -> [ModelEntity] {
        var spheres: [ModelEntity] = []
        for i in 0..<amount {
            spheres.append(buildSphere(radius: radius, color: colors[i]))
        }
        return spheres
    }
    
    private func buildSphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, roughness: 0, isMetallic: false)])
        let minMax = (groundSize / 2) - (radius / 2)
        sphere.position = [.random(in: -minMax...minMax), radius / 2, .random(in: -minMax...minMax)]
        let shape = ShapeResource.generateSphere(radius: radius)
        let collisionFilter = CollisionFilter(group: sphereCollisionGroup, mask: .all)
        sphere.collision = CollisionComponent(shapes: [shape], mode: .default, filter: collisionFilter)
        let massProperties = PhysicsMassProperties(shape: shape, mass: 0.005)
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 0.8, restitution: 0.8)
        sphere.physicsBody = PhysicsBodyComponent(massProperties: massProperties, material: physicsMaterial, mode: .dynamic)
        return sphere
    }
    
    private func buildBox(size: simd_float3, color: UIColor) -> ModelEntity {
        let box = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, roughness: 0, isMetallic: false)])
        let minMax: simd_float2 = [(groundSize / 2) - (size.x / 2), (groundSize / 2) - (size.z / 2)]
        box.position = [.random(in: -minMax.x...minMax.x), size.y / 2, .random(in: -minMax.y...minMax.y)]
        let shape = ShapeResource.generateBox(size: size)
        let collisionFilter = CollisionFilter(group: boxCollisionGroup, mask: .all)
        box.collision = CollisionComponent(shapes: [shape], mode: .default, filter: collisionFilter)
        let massProperties = PhysicsMassProperties(shape: shape, mass: 0.005)
        let physicsMaterial = PhysicsMaterialResource.generate(friction: 0.8, restitution: 0.8)
        box.physicsBody = PhysicsBodyComponent(massProperties: massProperties, material: physicsMaterial, mode: .dynamic)
        return box
    }
    
    private func addContainerEntitiesToCollisionGroup(_ scene: Experience.Scene) {
        for entity in [scene.wallBack, scene.wallRight, scene.wallFront, scene.wallLeft, scene.ground] {
            if let collisionComponent: CollisionComponent = entity?.components[CollisionComponent.self] {
                entity?.components[CollisionComponent.self] = CollisionComponent(shapes: collisionComponent.shapes, mode: collisionComponent.mode, filter: CollisionFilter(group: containerCollisionGroup, mask: .all))
            }
        }
    }
    
    private func randomVector(length: Float) -> simd_float3 {
        let angle = Float.random(in: -.pi...(.pi))
        return [cos(angle), 0, sin(angle)] * length
    }
    
    private func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
}
