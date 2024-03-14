//
//  MeshResource+Ext.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 22/02/2024.
//

import Foundation
import RealityKit

public extension MeshResource {
    static func generateCylinderArc(radius: CGFloat, length: CGFloat, height: CGFloat) throws -> MeshResource {
        let buffers =
        MeshResource.bakingArcCylinderBuffers(radius: radius, length: length, height: height)
        return try MeshResource.generateMeshResource(buffers: buffers)
    }
    // swiftlint:disable line_length
    static func generateCylinderArcAsync(radius: CGFloat, length: CGFloat, height: CGFloat) async throws -> MeshResource {
        return try await MeshResource.generateMeshResource(
            buffers: await Task {
                MeshResource.bakingArcCylinderBuffers(radius: radius, length: length, height: height)
            }.value)
    }

    static func generateTube(radius: CGFloat, height: CGFloat) throws -> MeshResource {
        let buffers =
        MeshResource.bakingTubeBuffers(radius: radius, height: height)
        return try MeshResource.generateMeshResource(buffers: buffers)
    }

//    static func generateEllipticCylinderArc(semiMajorAxis: CGFloat, semiMinorAxis: CGFloat, startAngle: CGFloat, endAngle: CGFloat, height: CGFloat) throws -> MeshResource {
//        let buffers = MeshResource.bakingEllipticCylinderArcBuffers(semiMajorAxis: semiMajorAxis, semiMinorAxis: semiMinorAxis, startAngle: startAngle, endAngle: endAngle, height: height)
//        return try MeshResource.generateMeshResource(buffers: buffers)
//    }
//
//    static func generateEllipticCylinderArcAsync(semiMajorAxis: CGFloat, semiMinorAxis: CGFloat, clockwiseStartAngle: CGFloat, clockwiseEndAngle: CGFloat, height: CGFloat) async throws -> MeshResource {
//        return try await MeshResource.generateMeshResource(
//            buffers: await Task {
//                MeshResource.bakingEllipticCylinderArcBuffers(semiMajorAxis: semiMajorAxis, semiMinorAxis: semiMinorAxis, startAngle: clockwiseStartAngle, endAngle: clockwiseEndAngle, height: height)
//            }.value)
//    }
}

fileprivate extension ContiguousArray {
    init(unsafeInitializedCapacity: Int) {
        self.init(unsafeUninitializedCapacity: unsafeInitializedCapacity) { _, initializedCount in
            initializedCount = unsafeInitializedCapacity
        }
    }
}

internal class Buffers {
    var positions: ContiguousArray<SIMD3<Float>>
    var textureCoordinates: ContiguousArray<SIMD2<Float>>
    var triangleIndices: ContiguousArray<UInt32>

    init(vertexCount: Int, triangleCount: Int) {
        self.positions = .init(unsafeInitializedCapacity: vertexCount)
        self.textureCoordinates = .init(unsafeInitializedCapacity: vertexCount)
        self.triangleIndices = .init(unsafeInitializedCapacity: 3*triangleCount)
    }
}

extension MeshResource {
    fileprivate static func generateMeshResource(buffers: Buffers) throws -> MeshResource {
        var meshDesc = MeshDescriptor()
        meshDesc.positions = MeshBuffer(buffers.positions)
        meshDesc.textureCoordinates = MeshBuffer(buffers.textureCoordinates)
        meshDesc.primitives = .triangles([UInt32].init(buffers.triangleIndices))
        return try .generate(from: [meshDesc])
    }

    fileprivate static func generateMeshResource(buffers: Buffers) async throws -> MeshResource {
        var meshDesc = MeshDescriptor()
        meshDesc.positions = MeshBuffer(buffers.positions)
        meshDesc.textureCoordinates = MeshBuffer(buffers.textureCoordinates)
        meshDesc.primitives = .triangles([UInt32].init(buffers.triangleIndices))
        return try await MeshResource(from: [meshDesc])
    }

    @inline(__always) internal static func setQuad(in buffers: Buffers, topRightPositionRow: UInt32, topRightPositionColumn: UInt32, columnSize: UInt32) {
        let bottomLeftRow: UInt32 = topRightPositionRow-1
        let bottomLeftColumn: UInt32 = topRightPositionColumn-1

        // let bottomLeftIndex = bottomLeftRow+bottomLeftColumn*columnSize //0
        // let bottomRightIndex = bottomLeftRow+topRightPositionColumn*columnSize //1
        // let topLeftIndex = topRightPositionRow+bottomLeftColumn*columnSize //2
        // let topRightIndex = topRightPositionRow+topRightPositionColumn*columnSize //3
        let quad = SIMD4<UInt32>(bottomLeftRow, bottomLeftRow, topRightPositionRow, topRightPositionRow)
        &+ columnSize&*SIMD4<UInt32>(bottomLeftColumn, topRightPositionColumn, bottomLeftColumn, topRightPositionColumn)

        // 3*x = x<<2 - x
        let thirdBottomLeftTrianglePosition: Int = Int(quad[0]<<1 - bottomLeftColumn<<1) // Int(bottomLeftIndex<<1 - bottomLeftColumn<<1)
        let bottomLeftTrianglePosition: Int = thirdBottomLeftTrianglePosition<<2 - thirdBottomLeftTrianglePosition
        let topRightTrianglePosition: Int = bottomLeftTrianglePosition+3

        // skip copy-on-write checks
        buffers.triangleIndices.withContiguousMutableStorageIfAvailable { buffer in
            buffer[bottomLeftTrianglePosition  ] = quad[0] // bottomLeftIndex
            buffer[bottomLeftTrianglePosition+1] = quad[1] // bottomRightIndex
            buffer[bottomLeftTrianglePosition+2] = quad[2] // topLeftIndex

            buffer[topRightTrianglePosition  ] = quad[2] // topLeftIndex
            buffer[topRightTrianglePosition+1] = quad[1] // bottomRightIndex
            buffer[topRightTrianglePosition+2] = quad[3] // topRightIndex
        }
    }

    @inline(__always) internal static func setQuad_simd(in buffers: Buffers, topRightPositionRow: UInt32, topRightPositionColumn: UInt32, columnSize: UInt32) {
        let bottomLeftRow: UInt32 = topRightPositionRow-1
        let bottomLeftColumn: UInt32 = topRightPositionColumn-1

        // let bottomLeftIndex = bottomLeftRow+bottomLeftColumn*columnSize //0
        // let bottomRightIndex = bottomLeftRow+topRightPositionColumn*columnSize //1
        // let topLeftIndex = topRightPositionRow+bottomLeftColumn*columnSize //2
        // let topRightIndex = topRightPositionRow+topRightPositionColumn*columnSize //3
        // let quad = SIMD4<UInt32>(bottomLeftRow, bottomLeftRow, topRightPositionRow, topRightPositionRow)
        // &+ columnSize&*SIMD4<UInt32>(bottomLeftColumn, topRightPositionColumn, bottomLeftColumn, topRightPositionColumn)
        let quad = SIMD8<UInt32>(
            bottomLeftRow, bottomLeftRow, topRightPositionRow, 0,
            topRightPositionRow, bottomLeftRow, topRightPositionRow, 0
        ) &+ columnSize&*SIMD8<UInt32>(
            bottomLeftColumn, topRightPositionColumn, bottomLeftColumn, 0,
            bottomLeftColumn, topRightPositionColumn, topRightPositionColumn, 0
        )

        // 3*x = x<<2 - x
        let thirdBottomLeftTrianglePosition: Int = Int(quad[0]<<1 - bottomLeftColumn<<1) // Int(bottomLeftIndex<<1 - bottomLeftColumn<<1)
        let bottomLeftTrianglePosition: Int = thirdBottomLeftTrianglePosition<<2 - thirdBottomLeftTrianglePosition
        let topRightTrianglePosition: Int = bottomLeftTrianglePosition+3

        buffers.triangleIndices.withContiguousMutableStorageIfAvailable { buffer in
            buffer[bottomLeftTrianglePosition  ] = quad[0] // bottomLeftIndex
            buffer[bottomLeftTrianglePosition+1] = quad[1] // bottomRightIndex
            buffer[bottomLeftTrianglePosition+2] = quad[2] // topLeftIndex

            buffer[topRightTrianglePosition  ] = quad[4] // topLeftIndex
            buffer[topRightTrianglePosition+1] = quad[5] // bottomRightIndex
            buffer[topRightTrianglePosition+2] = quad[6] // topRightIndex
        }
    }

    @inline(__always) internal static func setClosingQuads_simd(in buffers: Buffers, columnSize: UInt32, lastColumnIndex: UInt32, rowSize: UInt32) {
        let firstClosingTrianglePosition = (columnSize * rowSize) * 2 + 1 // because there are two triangles in one quad
        for positionIndex in 1..<columnSize {
            let bottomLeftTrianglePosition: Int = Int(firstClosingTrianglePosition + positionIndex - 2)*3
            let topRightTrianglePosition: Int = bottomLeftTrianglePosition + 3

            let bottomLeftQuadPosition: UInt32 = lastColumnIndex * columnSize + positionIndex - 1
            let bottomRightQuadPosition: UInt32 = positionIndex - 1
            let topLeftQuadPosition: UInt32 = bottomLeftQuadPosition + 1
            let topRightQuadPosition: UInt32 = positionIndex

//            let quad = SIMD8<UInt32>(
//                bottomLeftRow, bottomLeftRow, topRightPositionRow, 0,
//                topRightPositionRow, bottomLeftRow, topRightPositionRow, 0
//            ) &+ columnSize&*SIMD8<UInt32>(
//                bottomLeftColumn, topRightPositionColumn, bottomLeftColumn, 0,
//                bottomLeftColumn, topRightPositionColumn, topRightPositionColumn, 0
//            )

            buffers.triangleIndices.withContiguousMutableStorageIfAvailable { buffer in
                buffer[bottomLeftTrianglePosition  ] = bottomLeftQuadPosition // bottomLeftIndex
                buffer[bottomLeftTrianglePosition+1] = bottomRightQuadPosition // bottomRightIndex
                buffer[bottomLeftTrianglePosition+2] = topLeftQuadPosition // topLeftIndex

                buffer[topRightTrianglePosition  ] = topLeftQuadPosition // topLeftIndex
                buffer[topRightTrianglePosition+1] = bottomRightQuadPosition // bottomRightIndex
                buffer[topRightTrianglePosition+2] = topRightQuadPosition // topRightIndex
            }
        }
    }
}

extension MeshResource {
    internal static func bakingArcCylinderBuffers(radius: CGFloat, length: CGFloat, height: CGFloat) -> Buffers {
        let lengthSubDivision: UInt32 = 127
        let heightSubDivision: UInt32 = 1

        let lengthIndices = 0 ... Int32(lengthSubDivision)
        let heightIndices = 0 ... Int32(heightSubDivision)
        let columnSize: UInt32 = UInt32(heightIndices.count)

        let buffers = Buffers(vertexCount: lengthIndices.count*Int(columnSize), triangleCount: Int(2*lengthSubDivision*heightSubDivision))

        let arcAngle: Double = -length/radius
        let centeringAngleOffset: Double = (-.pi-arcAngle)/2

        // Start from left column
        for l in lengthIndices {
            let lengthRatio: Double = Double(l)/Double(lengthSubDivision)
            let angle: Double = arcAngle*lengthRatio
            let x = -Float(radius*cos(angle+centeringAngleOffset))
            let z = Float(radius*sin(angle+centeringAngleOffset))

            // Start from bottom row
            for h in heightIndices {
                let heightRatio: Double = Double(h)/Double(heightSubDivision)
                let y = Float(height*heightRatio)

                let position = SIMD3<Float>(x: x, y: y, z: z)
                let textureCoordinate = SIMD2<Float>(x: Float(lengthRatio), y: Float(heightRatio))

                let positionIndex=Int(h + l*Int32(columnSize))

                buffers.positions[positionIndex] = position
                buffers.textureCoordinates[positionIndex] = textureCoordinate

                guard h > 0 && l > 0 else {
                    // skip computing triangles if current position is not the top right corner of a quad
                    continue
                }

                setQuad_simd(in: buffers, topRightPositionRow: UInt32(h), topRightPositionColumn: UInt32(l), columnSize: columnSize)
            }
        }

        return buffers
    }
}

extension MeshResource {
    internal static func bakingHemisphereBuffers(radius: CGFloat, verticalSegments: UInt32, horizontalSegments: UInt32) -> Buffers {
        let vertexCount = Int((verticalSegments + 1) * (horizontalSegments + 1) / 2)
        let triangleCount = Int(verticalSegments * horizontalSegments * 2 - 2 * horizontalSegments)

        let buffers = Buffers(vertexCount: vertexCount, triangleCount: triangleCount)

        for v in 0...verticalSegments/2 {
            for h in 0...horizontalSegments {
                let vRatio = Double(v) / Double(verticalSegments)
                let hRatio = Double(h) / Double(horizontalSegments)

                let theta = vRatio * .pi // от 0 до π/2
                let phi = hRatio * 2.0 * .pi // от 0 до 2π

                let x = Float(radius * sin(theta) * cos(phi))
                let y = Float(radius * sin(theta) * sin(phi))
                let z = Float(radius * cos(theta))

                let position = SIMD3<Float>(x: x, y: y, z: z)
                let textureCoordinate = SIMD2<Float>(x: Float(hRatio), y: Float(vRatio))

                let positionIndex = Int(v * (horizontalSegments + 1) + h)

                buffers.positions[positionIndex] = position
                buffers.textureCoordinates[positionIndex] = textureCoordinate

                // Формирование треугольников
                if v < verticalSegments / 2 && h < horizontalSegments {
                    let nextRow = v + 1
                    let nextColumn = h + 1

                    let topLeft = UInt32(v * (horizontalSegments + 1) + h)
                    let topRight = topLeft + 1
                    let bottomLeft = UInt32(nextRow * (horizontalSegments + 1) + h)
                    let bottomRight = bottomLeft + 1

                    // Добавление двух треугольников для каждого квада
                    buffers.triangleIndices.append(contentsOf: [topLeft, bottomLeft, topRight])
                    buffers.triangleIndices.append(contentsOf: [topRight, bottomLeft, bottomRight])
                }
            }
        }

        return buffers
    }
}

extension MeshResource {
    internal static func bakingTubeBuffers(radius: CGFloat, height: CGFloat) -> Buffers {
        let radialSubdivision: UInt32 = 127 // Количество сегментов по радиусу
        let heightSubdivision: UInt32 = 1   // Количество сегментов по высоте

        let radialIndices = 0 ... Int32(radialSubdivision)
        let heightIndices = 0 ... Int32(heightSubdivision)
        let columnSize: UInt32 = UInt32(heightIndices.count)

        let buffers = Buffers(vertexCount: radialIndices.count * Int(columnSize), triangleCount: Int(2 * radialSubdivision * heightSubdivision))

        for r in radialIndices {
            let radialRatio: Double = Double(r) / Double(radialSubdivision)
            let angle: Double = 2.0 * .pi * radialRatio
            let x = Float(radius * cos(angle))
            let z = Float(radius * sin(angle))

            for h in heightIndices {
                let heightRatio: Double = Double(h) / Double(heightSubdivision)
                let y = Float(height * heightRatio)

                let position = SIMD3<Float>(x: x, y: y, z: z)
                let textureCoordinate = SIMD2<Float>(x: Float(radialRatio), y: Float(heightRatio))

                let positionIndex = Int(h + r * Int32(columnSize))

                buffers.positions[positionIndex] = position
                buffers.textureCoordinates[positionIndex] = textureCoordinate

                if r > 0 && h > 0 {
                    setQuad_simd(in: buffers, topRightPositionRow: UInt32(h), topRightPositionColumn: UInt32(r), columnSize: columnSize)
                }
            }
        }

        return buffers
    }
}


// extension MeshResource {
//    internal static func bakingTubeBuffers(radius: CGFloat, height: CGFloat) -> Buffers {
//        let lengthSubDivision: UInt32 = 16
//        let heightSubDivision: UInt32 = 1
//
//        let lengthIndices = 0 ... Int32(lengthSubDivision)
//        let heightIndices = 0 ... Int32(heightSubDivision)
//        let columnSize: UInt32 = UInt32(heightIndices.count)
//
//        let buffers = Buffers(vertexCount: lengthIndices.count*Int(columnSize), triangleCount: Int(2*lengthSubDivision*heightSubDivision))
//
//        let arcAngle: Double = .pi*2*4/Double(lengthSubDivision)
//        let centeringAngleOffset: Double = 0// (-.pi-arcAngle)/2
//
//        for l in lengthIndices {
//            let lengthRatio: Double = Double(l)/Double(lengthSubDivision)
//            let angle: Double = arcAngle*lengthRatio
//            let x = -Float(radius*cos(angle+centeringAngleOffset))
//            let z = Float(radius*sin(angle+centeringAngleOffset))
//
//            // Start from bottom row
//            for h in heightIndices {
//                let heightRatio: Double = Double(h)/Double(heightSubDivision)
//                let y = Float(height*heightRatio)
//
//                let position = SIMD3<Float>(x: x, y: y, z: z)
//                let textureCoordinate = SIMD2<Float>(x: Float(lengthRatio), y: Float(heightRatio))
//
//                let positionIndex=Int(h + l*Int32(columnSize))
//
//                buffers.textureCoordinates[positionIndex] = textureCoordinate
////                guard l < lengthSubDivision else {
////                    continue
////                }
//
//                buffers.positions[positionIndex] = position
//
//                guard h > 0 && l > 0 else {
//                    // skip computing triangles if current position is not the top right corner of a quad
//                    continue
//                }
//
//                setQuad_simd(in: buffers, topRightPositionRow: UInt32(h), topRightPositionColumn: UInt32(l), columnSize: columnSize)
//            }
//        }
//
//        setClosingQuads_simd(in: buffers, columnSize: columnSize, lastColumnIndex: lengthSubDivision, rowSize: heightSubDivision+1)
//
//        return buffers
//    }
// }

// public extension MeshResource {
//    fileprivate static func bakingEllipticCylinderArcBuffers(semiMajorAxis: CGFloat, semiMinorAxis: CGFloat, startAngle: CGFloat, endAngle: CGFloat, height: CGFloat) -> Buffers {
//        let lengthSubDivision: UInt32 = 100
//        let heightSubDivision: UInt32 = 1
//        let lengthIndices = 0 ... Int(lengthSubDivision)
//        let heightIndices = 0 ... Int(heightSubDivision)
//        let columnSize: UInt32 = UInt32(heightIndices.count)
//
//        let buffers = Buffers(vertexCount: lengthIndices.count*Int(columnSize), triangleCount: Int(2*lengthSubDivision*heightSubDivision))
//
//        let arcAngle: Double = startAngle-endAngle
//        let centeringAngleOffset: Double = (.pi)/2
//
//        // Start from left column
//        for l in lengthIndices {
//            let angleRatio: Double = Double(l)/Double(lengthSubDivision)
//            let angle = startAngle+arcAngle*angleRatio
//            let x = Float(semiMajorAxis*cos(angle+centeringAngleOffset))
//            let z = Float(semiMinorAxis*sin(angle+centeringAngleOffset))
//
//            // Start from bottom row
//            for h in heightIndices {
//                let heightRatio: Double = Double(h)/Double(heightSubDivision)
//                let y = Float(height*heightRatio)
//
//                let position = SIMD3<Float>(x: x, y: y, z: z)
//                let textureCoordinate = SIMD2<Float>(x: Float(angleRatio), y: Float(heightRatio))
//
//                let positionIndex = h + l*Int(columnSize)
//
//                buffers.positions[positionIndex] = position
//                buffers.textureCoordinates[positionIndex] = textureCoordinate
//
//                guard h > 0 && l > 0 else {
//                    // skip computing triangles if current position is not the top right corner of a quad
//                    continue
//                }
//
//                setQuad_simd(in: buffers, topRightPositionRow: UInt32(h), topRightPositionColumn: UInt32(l), columnSize: columnSize)
//            }
//        }
//
//        return buffers
//    }
// }
