//
//  SKTiledDemoScene.swift
//  Garden
//
//  Created by Admin on 01.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import SpriteKit
import Foundation
import GameplayKit
import UIKit
import SwiftUI

// special scene class used for the demo
public class SKTiledDemoScene: SKTiledScene {

    weak internal var gardenController: GardenController?
    public var uiScale: CGFloat = TiledGlobals.default.contentScale

    /// global information label font size.
    private let labelFontSize: CGFloat = 11

    /// objects stored for debugging
    internal var currentLayer: SKTiledLayerObject?
    internal var currentTile: SKTile?
    internal var currentVectorObject: SKTileObject?
    internal var currentProxyObject: TileObjectProxy?

    internal var selected: [SKTiledLayerObject] = []
    internal var focusObjects: [SKNode] = []

    internal var plotPathfindingPath: Bool = true
    internal var graphStartCoordinate: CGPoint?
    internal var graphEndCoordinate: CGPoint?
    private var selectObjectNode: SKSpriteNode?
    private var selectCoord: CGPoint!
    private var previousPosition: CGPoint!

    internal var currentPath: [GKGridGraphNode] = []
    
    private let demoQueue = DispatchQueue(label: "com.sktiled.sktiledDemoScene.demoQueue", qos: .utility)

    private var selectnode = SKSpriteNode()

    override public var isPaused: Bool {
        willSet {
            _ = (newValue == true) ? "Paused" : ""
        }
    }
        
    override public func didMove(to view: SKView) {
        super.didMove(to: view)

        cameraNode.ignoreZoomClamping = false

        // allow gestures on iOS
        cameraNode.allowGestures = true
        
    }

    override public func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateHud(tilemap)
    }

    override public func willMove(from view: SKView) {
        
    }

    /**
     Return tile nodes at the given point.

     - parameter coord: `CGPoint` event point.
     - returns: `[SKTile]` tile nodes.
     */
    func tilesAt(coord: CGPoint) -> [SKTile] {
        var result: [SKTile] = []
        guard let tilemap = tilemap else { return result }
        let tileLayers = tilemap.tileLayers(recursive: true).reversed().filter({ $0.visible == true })
        for tileLayer in tileLayers {
            if let tile = tileLayer.tileAt(coord: coord) {
                result.append(tile)
            }
        }
        return result
    }

    /**
     Return renderable nodes (tile & tile objects) at the given point.

     - parameter point: `CGPoint` event point.
     - returns: `[SKNode]` renderable nodes.
     */
    func renderableNodesAt(point: CGPoint) -> [SKNode] {
        var result: [SKNode] = []
        let nodes = self.nodes(at: point)
        for node in nodes {
            if (node is SKTileObject || node is SKTile) {
                result.append(node)
            }
        }
        return result
    }

    // MARK: - Demo

    /**
     Callback to the GameViewController to reload the current scene.
     */
    public func reloadScene() {
      
    }

    /**
     Callback to the GameViewController to load the next scene.
     */
    public func loadNextScene() {
        
    }

    /**
     Callback to the GameViewController to reload the previous scene.
     */
    public func loadPreviousScene() {
        
    }

    public func updateMapInfo(msg: String) {

       
    }

    public func updateTileInfo(msg: String) {
        
    }

    /**
     Send a command to the UI to update status.

     - parameter command:  `String` command string.
     - parameter duration: `TimeInterval` how long the message should be displayed (0 is indefinite).
     */
    public func updateCommandString(_ command: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {

        }
    }

    /**
     Update HUD elements when the view size changes.

     - parameter map: `SKTilemap?` tile map.
     */
    public func updateHud(_ map: SKTilemap?) {
        guard let map = map else { return }
        updateMapInfo(msg: map.description)
    }

    /**
     Plot a path between the last two points clicked.
     */
    func plotNavigationPath() {
        currentPath = []
        //guard (graphCoordinates.count == 2) else { return }
        guard let startCoord = graphStartCoordinate,
              let endCoord = graphEndCoordinate else { return }


        let startPoint = startCoord.toVec2
        let endPoint = endCoord.toVec2

        for (_, graph) in graphs {
            if let startNode = graph.node(atGridPosition: startPoint) {
                if let endNode = graph.node(atGridPosition: endPoint) {
                    currentPath = startNode.findPath(to: endNode) as! [GKGridGraphNode]
                }
            }
        }
    }

    /**
     Visualize the current grid graph path with a line.
     */
    func drawCurrentPath(withColor: SKColor = TiledObjectColors.lime) {
        guard let worldNode = worldNode,
              let tilemap = tilemap else { return }
        guard (currentPath.count > 2) else { return }

        worldNode.childNode(withName: "CURRENT_PATH")?.removeFromParent()

        // line dimensions
        let headWidth: CGFloat = tilemap.tileSize.height
        let lineWidth: CGFloat = tilemap.tileSize.halfWidth / 4

        let lastZPosition = tilemap.lastZPosition + (tilemap.zDeltaForLayers * 4)
        var points: [CGPoint] = []

        for node in currentPath {
            let nodePosition = worldNode.convert(tilemap.pointForCoordinate(vec2: node.gridPosition), from: tilemap.defaultLayer)
            points.append(nodePosition)
        }

        // path shape
        let path = polygonPath(points, threshold: 16)
        let shape = SKShapeNode(path: path)
        shape.isAntialiased = false
        shape.lineWidth = lineWidth * 2
        shape.strokeColor = withColor
        shape.fillColor = .clear

        worldNode.addChild(shape)
        shape.zPosition = lastZPosition
        shape.name = "CURRENT_PATH"

        // arrowhead shape
        let arrow = arrowFromPoints(startPoint: points[points.count - 2], endPoint: points.last!, tailWidth: lineWidth, headWidth: headWidth, headLength: headWidth)
        let arrowShape = SKShapeNode(path: arrow)
        arrowShape.strokeColor = .clear
        arrowShape.fillColor = withColor
        shape.addChild(arrowShape)
        arrowShape.zPosition = lastZPosition
    }

    /**
     Cleanup all tile shapes representing the current path.
     */
    open func cleanupPathfindingShapes() {
        // cleanup pathfinding shapes
        guard let worldNode = worldNode else { return }
        worldNode.childNode(withName: "CURRENT_PATH")?.removeFromParent()
    }

    /**
     Called before each frame is rendered.

     - parameter currentTime: `TimeInterval` update interval.
     */
    override open func update(_ currentTime: TimeInterval) {
        super.update(currentTime)


        var coordinateMessage = ""
        if let graphStartCoordinate = graphStartCoordinate {
            coordinateMessage += "Start: \(graphStartCoordinate.shortDescription)"
            if (currentPath.isEmpty == false) {
                coordinateMessage += ", \(currentPath.count) nodes"
            }
        }
    }

    // MARK: - Delegate Callbacks

    override open func didReadMap(_ tilemap: SKTilemap) {
        log("map read: \"\(tilemap.mapName)\"", level: .debug)
        self.physicsWorld.speed = 1
    }

    override open func didAddTileset(_ tileset: SKTileset) {
        let imageCount = (tileset.isImageCollection == true) ? tileset.dataCount : 0
        let statusMessage = (imageCount > 0) ? "images: \(imageCount)" : "rendered: \(tileset.isRendered)"
        log("tileset added: \"\(tileset.name)\", \(statusMessage)", level: .debug)
    }

    override open func didRenderMap(_ tilemap: SKTilemap) {
        // update the HUD to reflect the number of tiles created
        updateHud(tilemap)
        // allow the cache to send notifications
        tilemap.dataStorage?.blockNotifications = false
    }

    override open func didAddNavigationGraph(_ graph: GKGridGraph<GKGridGraphNode>) {
        super.didAddNavigationGraph(graph)
    }
    
    // MARK: - Private Methods
    
    private func isPositionInGarden(coord: CGPoint) -> Bool {
        let out_gardens = SharedInstance.shared.gardenArray.filter { $0.column == Int(coord.x) && $0.row == Int(coord.y) }
            
        if out_gardens.count == 0 {
            return false
        }
        return true
    }
    
    private func animateTile() {
        if selectCoord != nil && selectObjectNode != nil {
            let duration: TimeInterval = 0.3
            let changeposition = CGPoint(x: selectCoord.x, y: selectCoord.y + 384)
            let move = SKAction.move(to: changeposition, duration: duration)
            move.timingMode = .easeOut
            selectObjectNode!.run(move)
        }
    }    
}

// Touch-based event handling
extension SKTiledDemoScene {

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tilemap = tilemap else { return }
        
        for touch in touches {
            guard let objectlayer = tilemap.tileLayers(named: "object").first else { return }
            /**
             Get position in object layer and garden layer
             */
            let coordInObjectlayer = objectlayer.coordinateAtTouchLocation(touch)
            let positionInObjectlayer = objectlayer.touchLocation(touch)
            for item in SharedInstance.shared.objectArray {
                if CGPoint(x: item.column, y: item.row) == coordInObjectlayer {
                    previousPosition = coordInObjectlayer
                    selectObjectNode = item.sprite
                    selectObjectNode?.setScale(1.1)
                    selectObjectNode?.position = CGPoint(x: positionInObjectlayer.invertedY.x, y: positionInObjectlayer.invertedY.y + 384)
                    let positionInLayer = objectlayer.pointForCoordinate(item.column, item.row)
                    selectCoord = positionInLayer
                }
            }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let objectlayer = tilemap.tileLayers(named: "object").first else { return }
        guard let gardenlayer = tilemap.tileLayers(named: "garden").first else { return }
        
        for touch in touches {
            DispatchQueue.main.async {
                let positionInObjectlayer = objectlayer.touchLocation(touch)
                self.selectObjectNode?.position = CGPoint(x: positionInObjectlayer.invertedY.x, y: positionInObjectlayer.invertedY.y + 384)
                let coordInGardenlayer = gardenlayer.coordinateAtTouchLocation(touch)
                self.selectObjectNode?.zPosition = CGFloat(200 + coordInGardenlayer.x*coordInGardenlayer.y)
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let tilemap = tilemap else { return }
        
        for touch in touches {
            guard let gardenlayer = tilemap.tileLayers(named: "garden").first else { return }
                                    
            let coordInGardenlayer = gardenlayer.coordinateAtTouchLocation(touch)
            
            if isPositionInGarden(coord: coordInGardenlayer) {
                for item in SharedInstance.shared.objectArray {
                    if CGPoint(x: item.column, y: item.row) == previousPosition {
                        let savedFlower = SharedInstance.shared.objectArray.filter() { $0.column == Int(coordInGardenlayer.x) && $0.row == Int(coordInGardenlayer.y) }
                        if savedFlower.count == 0 {
                            item.column = Int(coordInGardenlayer.x)
                            item.row = Int(coordInGardenlayer.y)
                            let positionInLayer = gardenlayer.pointForCoordinate(item.column, item.row)
                            self.selectObjectNode?.position = CGPoint(x: positionInLayer.x, y: positionInLayer.y + 384)
                            self.selectObjectNode?.zPosition = CGFloat(200 + item.column*item.row)
                
                            /**
                             Save changed flower's position to user default
                             */
                            if let save_flowers = UserDefaults.standard.array(forKey: "flowers") as? [[String: Any]] {
                                UserDefaultManager.shared.UpdateMultiTilesPosition(oldPosition: previousPosition, newPosition: CGPoint(x: item.column, y: item.row), save_flowers: save_flowers) { (success) in }
                            }
                        } else {
                            animateTile()
                        }
                        break
                    }
                }
            } else {
                animateTile()
            }
            selectObjectNode?.setScale(1.0)
            selectObjectNode = nil
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch cancelled")
    }
}

extension SKTiledDemoScene {
    // MARK: - Delegate Methods

    /**
     Called when the camera positon changes.

     - parameter newPositon: `CGPoint` updated camera position.
     */
    override public func cameraPositionChanged(newPosition: CGPoint) {
        print("camera position changed")
    }

    /**
     Called when the camera zoom changes.

     - parameter newZoom: `CGFloat` camera zoom amount.
     */
    override public func cameraZoomChanged(newZoom: CGFloat) {
        print("camera zoom changed")
    }

    /**
     Called when the camera bounds updated.

     - parameter bounds:  `CGRect` camera view bounds.
     - parameter positon: `CGPoint` camera position.
     - parameter zoom:    `CGFloat` camera zoom amount.
     */
    override public func cameraBoundsChanged(bounds: CGRect, position: CGPoint, zoom: CGFloat) {
        // override in subclass
        log("camera bounds updated: \(bounds.roundTo()), pos: \(position.roundTo()), zoom: \(zoom.roundTo())", level: .debug)
    }

    /**
     Called when the scene receives a double-tap event (iOS only).

     - parameter location: `CGPoint` touch event location.
     */
    override public func sceneDoubleTapped(location: CGPoint) {
        log("scene was double tapped.", level: .debug)
    }
}
