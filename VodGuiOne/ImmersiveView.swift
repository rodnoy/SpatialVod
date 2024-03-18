//
//  ImmersiveView.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 20/02/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog

struct ImmersiveView: View {
    //    static let wallKey = "Wall_Empties"
    static let wallKey = "MyWall"
    static let posterKey = "poster"
    @State private var vm = ViewModel()
    @State private var sortDrawingGroup = ModelSortGroup()
    //Vertex_Empty_
    var tap: some Gesture {
        SpatialTapGesture().targetedToAnyEntity().onEnded{ value in
            if value.entity == vm.currentPoster || vm.currentPoster == nil{
                // если нажимает на уже открытый постер или на новый
                handleTap(on: value.entity)
            }
            if value.entity == vm.planeEntity {
                //handle flip card
                flipPlane(parentEntity: value.entity)
            }
        }
    }
    
//    var body: some View {
//        RealityView { content, attachments  in
//
//            // Add the initial RealityKit content
//            if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle), let movieDetail = attachments.entity(for: "z") {
//                if let wall = scene.findEntity(named: Self.wallKey){
//                    vm.wallEntity = wall
//                    for index in 0..<80 {
//                        let anchorName = "Vertex_Empty_\(index)"
//                        if let vertexAnchor = wall.findEntity(named: anchorName) {
//                            vertexAnchor.addChild(generateCardV2(for: scene))
//                        }
//                    }
////                    content.add(wall)
//                    vm.globalEntity.addChild(wall)
//                    movieDetail.position = [0, 1, -1]
//                    
//                    vm.movieDetailEntity = movieDetail
//                    movieDetail.setVisibility(isVisible: false)
////                    content.add(movieDetail)
//                    vm.globalEntity.addChild(movieDetail)
//                }
////                let plane = createDoubleSidedPlane()
////                plane.position = [0 , 1 , -1.5]
////                vm.planeEntity = plane
////                content.add(plane)
//                content.add(vm.globalEntity)
//            }
//        } attachments: {
//            Attachment(id: "z") {
//                MovieDetailView(onButtonTap: hidePosterInfo)
//            }
//        }
//        .gesture(tap)
//    }
   
    var body: some View {
        RealityView { content, attachments  in
            if let scene = try? await loadScene(), let movieDetail = attachments.entity(for: "z") {
                addWallAndCards(to: vm.globalEntity, from: scene)
                configureMovieDetail(movieDetail, in: vm.globalEntity)
                addPlane(to: vm.globalEntity)
            }
            content.add(vm.globalEntity)
        } attachments: {
            addAttachments()
        }
        .gesture(tap)
    }
     
    func createDoubleSidedPlane() -> Entity {
        let w: Float = 0.1
        let h: Float = 0.3
        let greenPlaneMesh = MeshResource.generatePlane(width: w , height: h, cornerRadius: 0.2)
        let redPlaneMesh = MeshResource.generatePlane(width: w, height: h, cornerRadius: 0.2)
        
        let greenMaterial = UnlitMaterial(color: .green)
        let redMaterial = UnlitMaterial(color: .red)
        
        let greenPlaneEntity = ModelEntity(mesh: greenPlaneMesh, materials: [greenMaterial])
        let redPlaneEntity = ModelEntity(mesh: redPlaneMesh, materials: [redMaterial])
        
        redPlaneEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0]) // Повернуть на 180 градусов вокруг оси Y
        
        // Родительская сущность для группировки
        let parentEntity = ModelEntity()
        parentEntity.addChild(greenPlaneEntity)
        parentEntity.addChild(redPlaneEntity)
        
        var input = InputTargetComponent(allowedInputTypes: .all)
        input.isEnabled = true
        parentEntity.components.set(input)
        let collision = CollisionComponent(shapes: [.generateBox(size: [w, h, 0.1])],
                                           mode: .trigger, filter: CollisionFilter(group: .default, mask: .all))
        parentEntity.components.set(collision)
        parentEntity.components.set(HoverEffectComponent())
        return parentEntity
    }
    
    private func generatePlane() -> ModelEntity {
        let planeMesh = MeshResource.generatePlane(width: 0.1, height: 0.5, cornerRadius: 0.2)
        let mat = UnlitMaterial(color: .green)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [mat])
        return planeEntity
    }
    private func generateCard() -> Entity {
        let cubeMesh = MeshResource.generateBox(size: [1, 5, 0.25], cornerRadius: 0.2)
        let cubeMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
        let cubeModel = ModelEntity(mesh: cubeMesh, materials: [cubeMaterial])
        return cubeModel
    }
    private func generateCardV2(for scene: Entity) -> Entity {
        if let poster = scene.findEntity(named: Self.posterKey){
            let cloned = poster.clone(recursive: true)
            if let uiImage = rotateByPiAroundY(UIImage(named: "cover")!){
                if let childEntity = cloned.findEntity(named: "Cube_018"){
                    //                let image = try! TextureResource.load(named: "cover")
                    let material = createUnlitMaterial(from: uiImage)
                    
                    if let modelComponent = childEntity.components[ModelComponent.self] {
                        childEntity.components[ModelComponent.self] = ModelComponent(mesh: modelComponent.mesh, materials: [modelComponent.materials[0], material])
                    }
                }
            }
            // add components
            do{
                var input = InputTargetComponent(allowedInputTypes: .all)
                input.isEnabled = true
                cloned.components.set(input)
                let collisionSize = cloned.visualSize
                let collision = CollisionComponent(shapes: [.generateBox(size: collisionSize)],
                                                   mode: .trigger, filter: CollisionFilter(group: .default, mask: .all))
                cloned.components.set(collision)
                cloned.components.set(HoverEffectComponent())
                let posterComponent = PosterComponent()
                cloned.components[PosterComponent.self] = posterComponent
            }
            cloned.scale = [1, 1, 1] * 15
            return cloned
        }
        return generateCard()
    }
    
    private func rotateByPiAroundY(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Vertical reflection (around the Y axis)
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        image.draw(at: CGPoint(x: 0, y: 0))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
    
    private func createUnlitMaterial(from image: UIImage) -> UnlitMaterial{
        let image = try! TextureResource.generate(from: (image.cgImage)!, options: .init(semantic: nil))
        var material = UnlitMaterial()
        material.color = .init(texture: .init(image))
        return material
    }

}
// animation management
extension ImmersiveView{
    //    private func handleTap(on poster: Entity) {
    //        guard let posterComponent = poster.components[PosterComponent.self] else { return }
    //
    //        if posterComponent.isEnlarged {
    //            // Animation of returning to original position and size
    //            let originalTransform = posterComponent.originalTransform
    //            poster.move(to: originalTransform, relativeTo: poster.parent, duration: 0.5, timingFunction: .easeInOut)
    //        } else {
    //            // Retain the original position and size
    //            posterComponent.originalTransform = poster.transform
    //
    //            let targetPosition: SIMD3<Float> = [ 0, 1, -1]
    //            let targetScale = poster.scale * 0.3 // 30%
    //
    //            // Create a new transformation for animation
    //            var newTransform = poster.transform
    //            newTransform.translation = targetPosition
    //            newTransform.scale = targetScale
    //
    //            // Animation of moving and scaling
    //            poster.move(to: newTransform,
    //                        relativeTo: nil,
    //                        duration: 0.5,
    //                        timingFunction: .easeInOut)
    //
    //        }
    //
    //        // Toggling the state
    //        posterComponent.isEnlarged.toggle()
    //    }
    private func handleTap(on poster: Entity) {
        guard let posterComponent = poster.components[PosterComponent.self] else { return }
        if posterComponent.isEnlarged {
            showPosterInfo(poster: poster)
        } else {
            if !vm.posterIsDisplayed{
                vm.currentPoster = poster
//                moveIn(poster: poster, with: posterComponent)
                changeOpacity(for: poster)
                createPlane(for: poster, in: vm.globalEntity)
                vm.posterIsDisplayed = true
                posterComponent.isEnlarged.toggle()
            }
        }
    }
    private func changeOpacity(for poster: Entity) {
        poster.opacity = 0.3
    }
    private func createPlane(for poster: Entity, in worldEntity: Entity) {
        let planeSize = poster.visualSize
        let planeInitialPosition = poster.position(relativeTo: nil)
        
        let faceUpPlaneMesh = MeshResource.generatePlane(width: calculateHypotenuse(planeSize.x, planeSize.z) , height: planeSize.y)
        let faceDownPlaneMesh = MeshResource.generatePlane(width: calculateHypotenuse(planeSize.x, planeSize.z) , height: planeSize.y)
        
//        var posterMaterial = createUnlitMaterial(from: rotateByPiAroundY(UIImage(named: "cover")!)!)
        let posterMaterial = UnlitMaterial(color: .green)
        let redMaterial = UnlitMaterial(color: .red)
        
        let faceUpPlaneEntity = ModelEntity(mesh: faceUpPlaneMesh, materials: [posterMaterial])
        let faceDownPlaneEntity = ModelEntity(mesh: faceDownPlaneMesh, materials: [redMaterial])
        // Rotate 180 degrees around the Y-axis
        faceDownPlaneEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        
        // Parent entity for grouping
        let parentEntity = ModelEntity()
        parentEntity.addChild(faceUpPlaneEntity)
        parentEntity.addChild(faceDownPlaneEntity)
        
//        var input = InputTargetComponent(allowedInputTypes: .all)
//        input.isEnabled = true
//        parentEntity.components.set(input)
//        
//        let collision = CollisionComponent(shapes: [.generateBox(size: planeSize)],
//                                           mode: .trigger, filter: CollisionFilter(group: .default, mask: .all))
//        parentEntity.components.set(collision)
//        parentEntity.components.set(HoverEffectComponent())
        
        parentEntity.position = planeInitialPosition
        Logger.xr.debug("plane rotation before adding poster's one : \(parentEntity.transform.rotation.axis) | \(parentEntity.transform.rotation.angle)")
        let transform = poster.convert(transform: poster.transform, to: worldEntity)
        Logger.ui.debug("*********> \(transform.rotation.axis) | \(transform.rotation.angle)")
        parentEntity.transform.rotation = transform.rotation
        Logger.xr.debug("plane rotation after : \(parentEntity.transform.rotation.axis) | \(parentEntity.transform.rotation.angle)")
        // test 2
        // Создаем кватернион вращения на 180 градусов вокруг оси Y
        let piRadians = Float.pi // 180 градусов в радианах
        let yAxis = SIMD3<Float>(0, 1, 0) // Ось Y
        let rotation180Y = simd_quatf(angle: piRadians, axis: yAxis)
        // Получаем текущее вращение сущности в виде кватерниона
        let currentRotation = parentEntity.transform.rotation
        // Умножаем кватернионы для получения итогового вращения
        let newRotation = rotation180Y * currentRotation

        // Применяем новое вращение к сущности
        parentEntity.transform.rotation = newRotation
//        let posterWorldTransform = poster.transformMatrix(relativeTo: nil)
//        let newPosition = posterWorldTransform.transform
        worldEntity.addChild(parentEntity)
 
    }
    func sumOfSquares<T: FloatingPoint>(_ elements: T...) -> T{
        elements.reduce(0) { partialResult, element in
            return partialResult + element * element
        }
    }
    func calculateHypotenuse<T: FloatingPoint>(_ a: T, _ b: T) -> T {
//        return (a * a + b * b).squareRoot()
        sumOfSquares(a, b).squareRoot()
    }
    
    private func moveBack(poster: Entity, with posterComponent: PosterComponent) {
        let originalTransform = posterComponent.originalTransform
        poster.move(to: originalTransform, relativeTo: poster.parent, duration: 0.5, timingFunction: .easeInOut)
    }
    private func moveIn(poster: Entity, with posterComponent: PosterComponent) {
        // Retain the original position and size
        posterComponent.originalTransform = poster.transform
        
        let targetPosition: SIMD3<Float> = [ 0, 1, -1]
        let targetScale = poster.scale * 0.1 // 10%
        
        // Create a new transformation for animation
        var newTransform = poster.transform
        newTransform.translation = targetPosition
        newTransform.scale = targetScale
        
        // Animation of moving and scaling
        poster.move(to: newTransform,
                    relativeTo: nil,
                    duration: 0.5,
                    timingFunction: .easeInOut)
    }
    private func moveBack(poster: Entity) {
        guard let posterComponent = poster.components[PosterComponent.self] else { return }
        let originalTransform = posterComponent.originalTransform
        poster.move(to: originalTransform, relativeTo: poster.parent, duration: 0.5, timingFunction: .easeInOut)
        posterComponent.isEnlarged.toggle()
    }
    private func showPosterInfo(poster: Entity){
        //        poster.setVisibility(isVisible: false)
        vm.currentPoster?.setVisibility(isVisible: false)
        vm.movieDetailEntity?.setVisibility(isVisible: true)
    }
    private func hidePosterInfo(){
        vm.movieDetailEntity?.setVisibility(isVisible: false)
        vm.currentPoster?.setVisibility(isVisible: true)
        
        moveBack(poster: vm.currentPoster!)
        vm.currentPoster = nil
        vm.posterIsDisplayed = false
    }
    // Этот метод вызывается при нажатии на плоскость.
    func flipPlane(parentEntity: Entity) {
        // Текущий угол поворота вокруг оси Y.
        
        let currentAngle = parentEntity.transform.rotation.angle
        let currentRotation: Float = switch currentAngle{
        case 0: .pi
        case .pi: 0
        default: 0
        }
        
        
        // Вектор оси Y для поворота.
        let yAxis = SIMD3<Float>(0, 1, 0)
        // Рассчитываем новый угол поворота как текущий плюс 180 градусов (в радианах).
        //        let newRotation = simd_quatf(angle: currentRotation + .pi, axis: yAxis)
        let newRotation = simd_quatf(angle: currentRotation, axis: yAxis)
        // Создаем анимацию с использованием move(to:).
        let animation = Transform(scale: parentEntity.transform.scale,
                                  rotation: newRotation,
                                  translation: parentEntity.transform.translation)
        
        // Применяем анимацию к родительской сущности.
        parentEntity.move(to: animation, relativeTo: parentEntity.parent, duration: 0.5, timingFunction: .easeInOut)
    }
}

// Prepare view and show it in body
extension ImmersiveView{
    private func loadScene() async throws -> Entity? {
        return try? await Entity(named: "Immersive", in: realityKitContentBundle)
    }
    
    private func addWallAndCards(to content: Entity, from scene: Entity) {
        if let wall = scene.findEntity(named: Self.wallKey) {
            vm.wallEntity = wall
            for index in 0..<80 {
                addCard(to: wall, at: index, from: scene)
            }
            content.addChild(wall)
        }
    }
    
    private func addCard(to wall: Entity, at index: Int, from scene: Entity) {
        let anchorName = "Vertex_Empty_\(index)"
        if let vertexAnchor = wall.findEntity(named: anchorName) {
            vertexAnchor.addChild(generateCardV2(for: scene))
        }
    }
    
    private func configureMovieDetail(_ movieDetail: Entity, in content: Entity) {
        movieDetail.position = [0, 1, -1]
        vm.movieDetailEntity = movieDetail
        movieDetail.setVisibility(isVisible: false)
        content.addChild(movieDetail)
    }
    
    private func addPlane(to content: Entity) {
        let plane = createDoubleSidedPlane()
        plane.position = [0 , 1 , -1.5]
        vm.planeEntity = plane
        content.addChild(plane)
    }
    private func addAttachments() -> some AttachmentContent {
        Attachment(id: "z") {
            MovieDetailView(onButtonTap: hidePosterInfo)
        }
    }
}

//extension ImmersiveView{
//    //using RealityViewContent as an anchor
//    // refactor body code:
//    // code for body
//    var body: some View {
//        RealityView { content, attachments  in
//            if let scene = try? await loadScene(), let movieDetail = attachments.entity(for: "z") {
//                addWallAndCards(to: &content, from: scene)
//                configureMovieDetail(movieDetail, in: &content)
////                addPlane(to: &content)
//            }
//        } attachments: {
//            addAttachments()
//        }
//        .gesture(tap)
//    }
//    // Similar functions as before, with slight adjustments for the new context
//    private func loadScene() async throws -> Entity? {
//        return try? await Entity(named: "Immersive", in: realityKitContentBundle)
//    }
//    
//    private func addWallAndCards(to content: inout RealityViewContent, from scene: Entity) {
//        if let wall = scene.findEntity(named: Self.wallKey) {
//            vm.wallEntity = wall
//            for index in 0..<80 {
//                addCard(to: wall, at: index, from: scene)
//            }
//            content.add(wall)
//        }
//    }
//    
//    private func addCard(to wall: Entity, at index: Int, from scene: Entity) {
//        let anchorName = "Vertex_Empty_\(index)"
//        if let vertexAnchor = wall.findEntity(named: anchorName) {
//            vertexAnchor.addChild(generateCardV2(for: scene))
//        }
//    }
//    
//    private func configureMovieDetail(_ movieDetail: Entity, in content: inout RealityViewContent) {
//        movieDetail.position = [0, 1, -1]
//        vm.movieDetailEntity = movieDetail
//        movieDetail.setVisibility(isVisible: false)
//        content.add(movieDetail)
//    }
//    
//    private func addPlane(to content: inout RealityViewContent) {
//        let plane = createDoubleSidedPlane()
//        plane.position = [0, 1, -1.5]
//        vm.planeEntity = plane
//        content.add(plane)
//    }
//    
//    private func addAttachments() -> some AttachmentContent {
//        Attachment(id: "z") {
//            MovieDetailView(onButtonTap: hidePosterInfo)
//        }
//    }
//
//// end of refactoring
//    
//}

extension ImmersiveView {
    @Observable
    class ViewModel{
        var posterIsDisplayed: Bool = false
        var globalEntity: Entity = Entity()
        var currentPoster: Entity? = nil
        var wallEntity: Entity?
        var movieDetailEntity: Entity?
        var planeEntity: Entity?
    }
}


#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}

extension Sequence {
    public func subtreeFlatten<Node, S: Sequence>(nodeKeyPath: KeyPath<Node, S>) -> some Sequence<Node> where Element == Node, S.Element == Node {
        subtreeFlatten { $0[keyPath: nodeKeyPath] }
    }
    
    public func subtreeFlatten<Node, S: Sequence>(nodes: @escaping (Node) -> S) -> some Sequence<Node> where Element == Node, S.Element == Node {
        AnySequence<Node> {
            var iterator = self.makeIterator()
            var nodeIterator: (any IteratorProtocol<Node>)?
            
            return AnyIterator {
                if var nodeIterator, let nextChild = nodeIterator.next() {
                    return nextChild
                }
                
                if let next = iterator.next() {
                    nodeIterator = nodes(next).subtreeFlatten(nodes: nodes).makeIterator()
                    return next
                }
                
                return nil
            }
        }
    }
}

