//
//  Democontroller.swift
//  Garden
//
//  Created by Admin on 01.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

/// Controller & Asset manager for the demo app
public class GardenController: NSObject, Loggable {

    public var sceneCount: Int = 0
    private let fm = FileManager.default
    static let `default` = GardenController()

    var preferences: DemoPreferences!
    weak public var view: SKView?

    /// Logging verbosity.
    public var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel

    /// Debug visualization options.
    public var debugDrawOptions: DebugDrawOptions = []
    private let demoQueue = DispatchQueue.global(qos: .userInteractive)

    /// tiled resources
    public var demourls: [URL] = []
    public var currentURL: URL!
    private var roots: [URL] = []
    private var resources: [URL] = []
    public var resourceTypes: [String] = ["tmx", "tsx", "tx", "png"]

    /// convenience properties
    public var tilemaps: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tmx" }
    }

    public var tilesets: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tsx" }
    }

    public var templates: [URL] {
        return resources.filter { $0.pathExtension.lowercased() == "tx" }
    }

    public var images: [URL] {
        return resources.filter { ["png", "jpg", "gif"].contains($0.pathExtension.lowercased()) }
    }

    /// Returns the current demo file index.
    public var currentIndex: Int {
        guard let currentURL = currentURL else { return 0 }

        var currentMapIndex = demourls.count - 1
        if let mapIndex = demourls.firstIndex(of: currentURL) {
            currentMapIndex = Int(mapIndex) + 1
        }
        return currentMapIndex
    }


    // MARK: - Init
    override public init() {
        super.init()

        self.readPreferences()
        SKTiledGlobals()

        // scan for resources
        if let rpath = Bundle.main.resourceURL {
            self.addRoot(url: rpath)
        }

        if (self.tilemaps.isEmpty == false) && (self.preferences.demoFiles.isEmpty == false) {
            // stash user maps here
            var userMaps: [URL] = []
            // loop through the demo files in order to preserve order
            for demoFile in self.preferences.demoFiles {

                var fileMatched = false

                // add files included in the demo plist
                for tilemap in self.tilemaps {
                    let pathComponents = tilemap.relativePath.split(separator: "/")
                    if (pathComponents.count > 1) && (userMaps.contains(tilemap) == false) {
                        userMaps.append(tilemap)
                    }

                    // get the name of the file
                    let tilemapName = tilemap.lastPathComponent
                    let tilemapBase = tilemap.basename

                    if (demoFile == tilemapName) || (demoFile == tilemapBase) {
                        fileMatched = true
                        self.demourls.append(tilemap)
                    }
                }

                if (fileMatched == false) {
                    self.log("cannot find file: \"\(demoFile)\"", level: .error)
                }
            }

            // set the first url
            if let firstURL = self.demourls.first {
                self.currentURL = firstURL
            }

            // append user maps
            if (userMaps.isEmpty == false) && (self.preferences.allowUserMaps == true) {
                for userMap in userMaps {
                    guard self.demourls.contains(userMap) == false else {
                        continue
                    }

                    self.demourls.append(userMap)
                }
            }
        }
    }

    public init(view: SKView) {
        self.view = view
        super.init()
    }

    // MARK: - Asset Management

    /**
     Add a new root path and scan.

     - parameter path: `String` resource root path.
     */
    public func addRoot(url: URL) {
        if !roots.contains(url) {
            roots.append(url)
            scanForResourceTypes()
        }
    }

    /**
     URL is relative.
     */
    public func addTilemap(url: URL, at index: Int) {
        demourls.insert(url, at: index)
        loadScene(url: url, usePreviousCamera: preferences.usePreviousCamera)
    }

    /**
     Scan root directories and return any matching resource files.
     */
    private func scanForResourceTypes() {
        var resourcesAdded = 0
        for root in roots {
            let urls = fm.listFiles(path: root.path, withExtensions: resourceTypes)

            for url in urls {
                guard resources.contains(url) == false else {
                    continue
                }

                resources.append(url)
                resourcesAdded += 1
            }
        }

        let statusMsg = (resourcesAdded > 0) ? "\(resourcesAdded) resources added." : "WARNING: no resources found."
        let statusLevel = (resourcesAdded > 0) ? LoggingLevel.info : LoggingLevel.warning
        log(statusMsg, level: statusLevel)
    }

    /**
     Read demo preferences from property list.
     */
    private func readPreferences() {
        let configurationURL = URL(fileURLWithPath: "Demo.plist", isDirectory: false, relativeTo: Bundle.main.resourceURL!)
        let decoder = PropertyListDecoder()

        if let configData = loadDataFrom(url: configurationURL) {
            if let demoPreferences = try? decoder.decode(DemoPreferences.self, from: configData) {
                preferences = demoPreferences
                self.log("demo preferences loaded.", level: .info)
                self.updateGlobalsWithPreferences()
            } else {
                self.log("preferences could not be loaded.", level: .fatal)
                abort()
            }
        }
    }

    // MARK: - Globals

    /**
     Update globals with demo prefs.
     */
    private func updateGlobalsWithPreferences() {
        self.log("updating globals...", level: .info)

        TiledGlobals.default.renderQuality.default = CGFloat(preferences.renderQuality)
        TiledGlobals.default.renderQuality.object = CGFloat(preferences.objectRenderQuality)
        TiledGlobals.default.renderQuality.text = CGFloat(preferences.textRenderQuality)
        TiledGlobals.default.enableRenderCallbacks = preferences.renderCallbacks
        TiledGlobals.default.enableCameraCallbacks = preferences.cameraCallbacks

        // Tile animation mode
        guard let demoAnimationMode = TileUpdateMode.init(rawValue: preferences.updateMode) else {
            log("invalid update mode: \(preferences.updateMode)", level: .error)
            return
        }

        TiledGlobals.default.updateMode = demoAnimationMode

        // Logging level
        guard let demoLoggingLevel = LoggingLevel.init(rawValue: preferences.loggingLevel) else {
            log("invalid logging level: \(preferences.loggingLevel)", level: .error)
            return
        }

        self.loggingLevel = demoLoggingLevel
        Logger.default.loggingLevel = demoLoggingLevel
        TiledGlobals.default.loggingLevel = demoLoggingLevel
        TiledGlobals.default.debug.mouseFilters = TiledGlobals.DebugDisplayOptions.MouseFilters.init(rawValue: preferences.mouseFilters)
    }

    
    // MARK: - Helpers

    /**
     Load data from a URL.
     */
    func loadDataFrom(url: URL) -> Data? {
        if let xmlData = try? Data(contentsOf: url) {
            self.log("reading: \"\(url.relativePath)\"...", level: .debug)
            return xmlData
        }
        return nil
    }

    // MARK: - Scene Management

    /**
     Clear the current scene.
     */
    @objc public func flushScene() {
        guard let view = self.view else {
            log("view is not set.", level: .error)
            return
        }

        view.presentScene(nil)
        let nextScene = SKTiledDemoScene(size: view.bounds.size)
        view.presentScene(nextScene)
    }

    /**
     Reload the current scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func reloadScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else { return }
        loadScene(url: currentURL, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: true)
    }

    /**
     Load the next tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func loadNextScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else {
            log("current url does not exist.", level: .error)
            return
        }


        var nextFilename = demourls.first!
        if let index = demourls.firstIndex(of: currentURL), index + 1 < demourls.count {
            nextFilename = demourls[index + 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: false)
    }

    /**
     Load the previous tilemap scene.

     - parameter interval: `TimeInterval` transition duration.
     */
    @objc public func loadPreviousScene(_ interval: TimeInterval = 0.3) {
        guard let currentURL = currentURL else { return }
        var nextFilename = demourls.last!
        if let index = demourls.firstIndex(of: currentURL), index > 0, index - 1 < demourls.count {
            nextFilename = demourls[index - 1]
        }
        loadScene(url: nextFilename, usePreviousCamera: preferences.usePreviousCamera, interval: interval, reload: false)
    }

    // MARK: - Loading

    /**
     Loads a new demo scene with a named tilemap.

     - parameter url:               `URL` tilemap file url.
     - parameter usePreviousCamera: `Bool` transfer camera information.
     - parameter interval:          `TimeInterval` transition duration.
     */
    internal func loadScene(url: URL, usePreviousCamera: Bool, interval: TimeInterval = 0.3, reload: Bool = false, _ completion: (() -> Void)? = nil) {
        guard let view = self.view,
            let preferences = self.preferences else {
            return
        }

        // loaded from preferences
        var showObjects: Bool = preferences.showObjects
        var enableEffects: Bool = preferences.enableEffects
        var shouldRasterize: Bool = false
        var tileUpdateMode: TileUpdateMode?


        if (tileUpdateMode == nil) {
            if let prefsUpdateMode = TileUpdateMode(rawValue: preferences.updateMode) {
                tileUpdateMode = prefsUpdateMode
            }
        }

        // grid visualization
        let drawGrid: Bool = preferences.drawGrid
        if (drawGrid == true) {
            debugDrawOptions.insert([.drawGrid, .drawBounds])
        }

        let drawSceneAnchor: Bool = preferences.drawAnchor
        if (drawSceneAnchor == true) {
            debugDrawOptions.insert(.drawAnchor)
        }

        let hasCurrent = false
        var showOverlay = true
        var cameraPosition = CGPoint.zero
        var cameraZoom: CGFloat = 1
        var isPaused: Bool = false

        var currentSpeed: CGFloat = 1
        var ignoreZoomClamping: Bool = false
        var zoomClamping: CameraZoomClamping = CameraZoomClamping.none
        var ignoreZoomConstraints: Bool = preferences.ignoreZoomConstraints

        var sceneInfo: [String: Any] = [:]


        // get current scene info
        if let currentScene = view.scene as? SKTiledDemoScene {

            if let cameraNode = currentScene.cameraNode {
                showOverlay = cameraNode.showOverlay
                cameraPosition = cameraNode.position
                cameraZoom = cameraNode.zoom
                ignoreZoomClamping = cameraNode.ignoreZoomClamping
                zoomClamping = cameraNode.zoomClamping
                ignoreZoomConstraints = cameraNode.ignoreZoomConstraints
            }

            // pass current values to next tilemap
            if let tilemap = currentScene.tilemap {
                tilemap.dataStorage?.blockNotifications = true
                debugDrawOptions = tilemap.debugDrawOptions
                currentURL = url
                showObjects = tilemap.showObjects
                enableEffects = tilemap.shouldEnableEffects
                shouldRasterize = tilemap.shouldRasterize
                tileUpdateMode = tilemap.updateMode
                
            }

            isPaused = currentScene.isPaused
            currentSpeed = currentScene.speed
            currentScene.gardenController = nil
        }
        // load the next scene on the main queue
        DispatchQueue.main.async { [unowned self] in

            let nextScene = SKTiledDemoScene(size: view.bounds.size)
            nextScene.scaleMode = .aspectFill
            nextScene.gardenController = self
            nextScene.receiveCameraUpdates = TiledGlobals.default.enableCameraCallbacks

            // flushing old scene from memory
            view.presentScene(nil)

            // create the transition
            let transition = SKTransition.fade(withDuration: interval)
            view.presentScene(nextScene, transition: transition)
            nextScene.isPaused = isPaused

            // setup a new scene with the next tilemap filename
            nextScene.setup(tmxFile: url.relativePath,
                            inDirectory: (url.baseURL == nil) ? nil : url.baseURL!.path,
                            withTilesets: [],
                            ignoreProperties: false,
                            loggingLevel: self.loggingLevel) { tilemap in

                            // completion handler
                            if (usePreviousCamera == true) {
                                nextScene.cameraNode?.showOverlay = showOverlay
                                nextScene.cameraNode?.position = cameraPosition
                                nextScene.cameraNode?.setCameraZoom(cameraZoom, interval: interval)
                            }

                            nextScene.cameraNode?.ignoreZoomClamping = ignoreZoomClamping
                            nextScene.cameraNode?.zoomClamping = zoomClamping
                            nextScene.cameraNode?.ignoreZoomConstraints = ignoreZoomConstraints

                            // if tilemap has a property override to show objects, use it...else use demo prefs
                            tilemap.showObjects = (tilemap.boolForKey("showObjects") == true) ? true : showObjects

                            sceneInfo["hasGraphs"] = (nextScene.graphs.isEmpty == false)
                            sceneInfo["hasObjects"] = nextScene.tilemap.getObjects().isEmpty == false
                            sceneInfo["propertiesInfo"] = "--"


                            if (hasCurrent == false) {
                                self.log("auto-resizing the view.", level: .debug)
                                nextScene.cameraNode.fitToView(newSize: view.bounds.size)
                            }

                            // add caching here
                            tilemap.shouldEnableEffects = (tilemap.boolForKey("shouldEnableEffects") == true) ? true : enableEffects
                            tilemap.shouldRasterize = shouldRasterize
                            tilemap.updateMode = tileUpdateMode ?? TiledGlobals.default.updateMode


                            self.demoQueue.async { [unowned self] in
                                tilemap.debugDrawOptions = self.debugDrawOptions
                            }

                            self.sceneCount += 1
                                
                            // set the previous scene's speed
                            nextScene.speed = currentSpeed

                            // Create garden map
                            self.createGardenMap(new: false)
                            // Get flowers data and add to scene from plist
                            self.getFlowersFromDefault()
            } // end of completion handler
        }
    }

    // MARK: - Demo Control
    /**
     Get flowers from plist
     */
    func getFlowersFromDefault() {
        if let save_flowers = UserDefaults.standard.array(forKey: "flowers") as? [[String: Any]] {
            save_flowers.forEach { (flower) in
                let flower_x = flower["column"] as! CGFloat
                let flower_y = flower["row"] as! CGFloat
                let flowername = flower["flowername"] as! String
                let position = CGPoint(x: flower_x, y: flower_y)
                sceneDelegate()?.gardenController.addNewTileSet(position: position, img: flowername)
            }
        }
    }
    /**
     Add new tileset to "object" layer.
     */
    public func addNewTileSet(position: CGPoint, img: String) {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if let tilemap = scene.tilemap {
            var flower: SKSpriteNode!
            let tileSet = tilemap.getTileset(named: img)
            // get data for a specific id
            let tileData = tileSet!.getTileData(localID: 0)!
            flower = SKTile(data: tileData)
            tilemap.tileLayers(named: "object").first!.addChild(flower, coord: CGPoint(x: Int(position.x), y: Int(position.y)), offset: CGPoint(x: 0, y: 384), zpos: 200 + position.x*position.y)
            SharedInstance.shared.objectArray.append(Object(column: Int(position.x), row: Int(position.y), sprite: flower))
        }
    }
    /**
     Save matrix number to user default
     */
    func SaveMatrixNumber() {
        UserDefaults.standard.set(SharedInstance.shared.matrix!, forKey: "matrix")
    }
    /**
     Create garden map
     */
    func createGardenMap(new: Bool) {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }
        
        if new {
            scene.cameraNode.zoom = 0.2
            scene.cameraNode.setCameraZoom(scene.cameraNode.zoom)
        }
                   
        let layerpoint = scene.convert(CGPoint(x: 0, y: 0), to: scene.tilemap.tileLayers(named: "garden").first!)
        SharedInstance.shared.centerLocation = layerpoint
        let mappoint = CGPoint(x: 50, y: 50)
        if let tilemap = scene.tilemap {
            
            if let oldlayer = scene.tilemap.tileLayers(named: "garden").first {
                oldlayer.removeAllChildren()
                SharedInstance.shared.gardenArray.removeAll()
            }
            /**
             Save matrix number to plist
             */
            self.SaveMatrixNumber()
                                    
            /**
            Add child for first row
             */
            let matrix = SharedInstance.shared.matrix
            let initial = (matrix! - 1)/2
            let tile_0_0 = SKSpriteNode(imageNamed: "5.png")
            tilemap.tileLayers(named: "garden").first!.addChild(tile_0_0, coord: CGPoint(x: Int(mappoint.x - initial), y: Int(mappoint.y - initial)))
            SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial), row: Int(mappoint.y - initial), sprite: tile_0_0))
            if (matrix! - 2) == 1 {
                let tile_0_1 = SKSpriteNode(imageNamed: "6.png")
                tilemap.tileLayers(named: "garden").first!.addChild(tile_0_1, coord: CGPoint(x: Int(mappoint.x - initial), y: Int(mappoint.y - initial + 1)))
                SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial), row: Int(mappoint.y - initial + 1), sprite: tile_0_1))
                
                let tile_0_2 = SKSpriteNode(imageNamed: "9.png")
                tilemap.tileLayers(named: "garden").first!.addChild(tile_0_2, coord: CGPoint(x: Int(mappoint.x - initial), y: Int(mappoint.y - initial + (matrix! - 1))))
                SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial), row: Int(mappoint.y - initial + (matrix! - 1)), sprite: tile_0_2))
            } else {
                for i in 1...(matrix! - 1) {
                    if i == (matrix! - 1) {
                        let tile_0_2 = SKSpriteNode(imageNamed: "9.png")
                        tilemap.tileLayers(named: "garden").first!.addChild(tile_0_2, coord: CGPoint(x: Int(mappoint.x - initial), y: Int(mappoint.y - initial + i)))
                        SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial), row: Int(mappoint.y - initial + i), sprite: tile_0_2))
                        continue
                    }
                    
                    let tile_0_1 = SKSpriteNode(imageNamed: "6.png")
                    tilemap.tileLayers(named: "garden").first!.addChild(tile_0_1, coord: CGPoint(x: Int(mappoint.x - initial), y: Int(mappoint.y - initial + i)))
                    SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial), row: Int(mappoint.y - initial + i), sprite: tile_0_1))
                }
            }
                
            /**
             Add child middle rows
             */
            for j in 1...(matrix! - 2) {
                let tile_1_0 = SKSpriteNode(imageNamed: "7.png")
                tilemap.tileLayers(named: "garden").first!.addChild(tile_1_0, coord: CGPoint(x: Int(mappoint.x - initial + j), y: Int(mappoint.y - initial)))
                SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + j), row: Int(mappoint.y - initial), sprite: tile_1_0))
                for i in 1...(matrix! - 1) {
                    if i == (matrix! - 1) {
                        let tile_1_2 = SKSpriteNode(imageNamed: "2.png")
                        tilemap.tileLayers(named: "garden").first!.addChild(tile_1_2, coord: CGPoint(x: Int(mappoint.x - initial + j), y: Int(mappoint.y - initial + i)))
                        SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + j), row: Int(mappoint.y - initial + i), sprite: tile_1_2))
                        continue
                    }
                    
                    let tile_1_1 = SKSpriteNode(imageNamed: "1_3_Dirt.png")
                    tilemap.tileLayers(named: "garden").first!.addChild(tile_1_1, coord: CGPoint(x: Int(mappoint.x - initial + j), y: Int(mappoint.y - initial + i)))
                    SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + j), row: Int(mappoint.y - initial + i), sprite: tile_1_1))
                }
            }
                        
            /**
             Add child last row
             */
            let tile_2_0 = SKSpriteNode(imageNamed: "8.png")
            tilemap.tileLayers(named: "garden").first!.addChild(tile_2_0, coord: CGPoint(x: Int(mappoint.x - initial + (matrix! - 1)), y: Int(mappoint.y - initial)))
            SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + (matrix! - 1)), row: Int(mappoint.y - initial), sprite: tile_2_0))
            if (matrix! - 2) == 1 {
                let tile_2_1 = SKSpriteNode(imageNamed: "4.png")
                tilemap.tileLayers(named: "garden").first!.addChild(tile_2_1, coord: CGPoint(x: Int(mappoint.x - initial + (matrix! - 1)), y: Int(mappoint.y - initial + 1)))
                SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + (matrix! - 1)), row: Int(mappoint.y - initial + 1), sprite: tile_2_1))
                
                let tile_2_2 = SKSpriteNode(imageNamed: "3.png")
                tilemap.tileLayers(named: "garden").first!.addChild(tile_2_2, coord: CGPoint(x: Int(mappoint.x - initial + (matrix! - 1)), y: Int(mappoint.y - initial + (matrix! - 1))))
                SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + (matrix! - 1)), row: Int(mappoint.y - initial + (matrix! - 1)), sprite: tile_2_2))
            } else {
                for i in 1...(matrix! - 1) {
                    if i == (matrix! - 1) {
                        let tile_2_2 = SKSpriteNode(imageNamed: "3.png")
                        tilemap.tileLayers(named: "garden").first!.addChild(tile_2_2, coord: CGPoint(x: Int(mappoint.x - initial + (matrix! - 1)), y: Int(mappoint.y - initial + i)))
                        SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + (matrix! - 1)), row: Int(mappoint.y - initial + i), sprite: tile_2_2))
                        continue
                    }
                    
                    let tile_2_1 = SKSpriteNode(imageNamed: "4.png")                    
                    tilemap.tileLayers(named: "garden").first!.addChild(tile_2_1, coord: CGPoint(x: Int(mappoint.x - initial + (matrix! - 1)), y: Int(mappoint.y - initial + i)))
                    SharedInstance.shared.gardenArray.append(Garden(column: Int(mappoint.x - initial + (matrix! - 1)), row: Int(mappoint.y - initial + i), sprite: tile_2_1))
                }
            }
        }
    }
    

    /**
     Fit the current scene to the view.
     */
    public func fitSceneToView() {
        guard let view = self.view else { return }
        guard let scene = view.scene as? SKTiledScene else { return }

        if let cameraNode = scene.cameraNode {
            cameraNode.centerOn(scenePoint: scene.center)
            cameraNode.fitToView(newSize: view.bounds.size, transition: 0.25)
        }
    }

    /**
     Show/hide the map bounds.
     */
    public func toggleMapDemoDrawBounds() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            if (tilemap.debugDrawOptions.contains(.drawBounds)) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(.drawBounds)
            } else {
                tilemap.debugDrawOptions.insert(.drawBounds)
            }           
        }
    }

    /**
     Show/hide the map grid.
     */
    public func toggleMapDemoDrawGrid() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            if (tilemap.debugDrawOptions.contains(.drawGrid)) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting(.drawGrid)
            } else {
                tilemap.debugDrawOptions.insert(.drawGrid)
            }
        }
    }

    /**
     Show/hide navigation graph visualizations.
     */
    public func toggleMapGraphVisualization() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            var graphsCount = 0
            var graphsDrawn = 0
            for tileLayer in tilemap.tileLayers() where tileLayer.graph != nil {
                if (tileLayer.debugDrawOptions.contains(.drawGraph) == false) {
                    graphsDrawn += 1
                }
                if (tileLayer.debugDrawOptions.contains(.drawGraph)) {
                    tileLayer.debugDrawOptions = tileLayer.debugDrawOptions.subtracting([.drawGraph])
                } else {
                    tileLayer.debugDrawOptions.insert([.drawGraph])
                }
                graphsCount += 1
            }
        }
    }

    /**
     Show/hide the grid & map bounds. This is meant to be used with the interface buttons/keys to quickly turn grid & bounds drawing on.
     */
    @objc public func toggleMapDemoDrawGridAndBounds() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            if (tilemap.debugDrawOptions.contains(.drawGrid) || tilemap.debugDrawOptions.contains(.drawBounds) ) {
                tilemap.debugDrawOptions = tilemap.debugDrawOptions.subtracting([.drawGrid, .drawBounds])
            } else {
                tilemap.debugDrawOptions.insert([.drawGrid, .drawBounds])
            }
        }
    }

    /**
     Show/hide current scene objects.
     */
    @objc public func toggleMapObjectDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            let doShowObjects = !tilemap.showObjects
            tilemap.showObjects = doShowObjects
        }
    }

    /**
     Show/hide current scene objects.
     */
    @objc public func toggleObjectBoundaryDrawing() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {

            let currentObjectBoundsMode = tilemap.debugDrawOptions.contains(.drawObjectBounds)
            if (currentObjectBoundsMode == false) {
                tilemap.debugDrawOptions.insert(.drawObjectBounds)
            } else {
                tilemap.debugDrawOptions.remove(.drawObjectBounds)
            }

        }
    }


    // Debug.MapEffectsRenderingChanged
    @objc public func toggleTilemapEffectsRendering() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {

            let effectsMode = tilemap.shouldEnableEffects
            tilemap.shouldEnableEffects = !effectsMode
        }
    }

    @objc public func cycleTilemapUpdateMode() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene,
            let tilemap = scene.tilemap else { return }


        let currentValue = tilemap.updateMode
        let nextValue = currentValue.next()
        tilemap.updateMode = nextValue
    }

    @objc public func toggleRenderStatistics() {
        let statsCurrentState = TiledGlobals.default.enableRenderCallbacks
        let statsNextState = !statsCurrentState
        TiledGlobals.default.enableRenderCallbacks = statsNextState

    }

    // MARK: - Debugging Output

    /**
     Dump the map statistics to the console.
     */
    public func dumpMapStatistics() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let tilemap = scene.tilemap {
            tilemap.dumpStatistics()
        }
    }

    public func updateTileUpdateMode(value: Int = -1) {
        guard let view = self.view,
            let _ = view.scene as? SKTiledScene else { return }

        let nextUpdateMode: TileUpdateMode = TileUpdateMode.init(rawValue: value) ?? TiledGlobals.default.updateMode.next()

        if (nextUpdateMode != TiledGlobals.default.updateMode) {
            TiledGlobals.default.updateMode = nextUpdateMode
        }
    }

    // MARK: - Layer Isolation/Visibility
    /**
     Toggle layer isolation.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
    public func toggleLayerVisibility(layerID: String, visible isVisible: Bool) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                selectedLayer.isHidden = !isVisible
            }
        }
    }

    /**
     Toggle layer visibility.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
    public func toggleAllLayerVisibility(visible isVisible: Bool) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        if let tilemap = scene.tilemap {
            tilemap.layers.forEach { layer in
                layer.isHidden = !isVisible
            }
        }
    }

    /**
     Toggle layer isolation.

     - parameter layerID:  `String` layer uuid.
     - parameter isolated: `Bool` isolated on/off.
     */
    public func toggleLayerIsolated(layerID: String, isolated isIsolated: Bool) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        if let tilemap = scene.tilemap {
            if let selectedLayer = tilemap.getLayer(withID: layerID) {
                selectedLayer.isolateLayer(duration: 0.25)
            }
        }
    }

    /**
     Disable all layer isolation.
     */
    public func turnIsolationOff() {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }
        if let tilemap = scene.tilemap {
            tilemap.getLayers().forEach { layer in
                if (layer.isolated == true) {
                    layer.isolateLayer(duration: 0.1)
                }
            }
        }
    }

    public func cycleTilemapUpdateMode(mode: String) {
        guard let view = self.view,
            let scene = view.scene as? SKTiledScene else { return }

        if let updateMode = Int(mode) {
            if let newUpdateMode = TileUpdateMode.init(rawValue: updateMode) {
                if let tilemap = scene.tilemap {
                    tilemap.updateMode = newUpdateMode
                }
            }
        }
    }
}


/// Class to manage preferences loaded from a property list.
class DemoPreferences: Codable {

    var renderQuality: Double = 0
    var objectRenderQuality: Double = 0
    var textRenderQuality: Double = 0
    var maxRenderQuality: Double = 0

    var showObjects: Bool = false
    var drawGrid: Bool = false
    var drawAnchor: Bool = false
    var enableEffects: Bool = false
    var updateMode: Int = 0
    var allowUserMaps: Bool = true
    var loggingLevel: Int = 0
    var renderCallbacks: Bool = true
    var cameraCallbacks: Bool = true
    var mouseFilters: Int = 0
    var ignoreZoomConstraints: Bool = false
    var usePreviousCamera: Bool = false
    var demoFiles: [String] = []

    enum ConfigKeys: String, CodingKey {
        case renderQuality
        case objectRenderQuality
        case textRenderQuality
        case maxRenderQuality
        case showObjects
        case drawGrid
        case drawAnchor
        case enableEffects
        case updateMode
        case allowUserMaps
        case loggingLevel
        case renderCallbacks
        case cameraCallbacks
        case mouseFilters
        case ignoreZoomConstraints
        case usePreviousCamera
        case demoFiles
    }

    required init?(coder aDecoder: NSCoder) {}

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: ConfigKeys.self)
        renderQuality = try values.decode(Double.self, forKey: .renderQuality)
        objectRenderQuality = try values.decode(Double.self, forKey: .objectRenderQuality)
        textRenderQuality = try values.decode(Double.self, forKey: .textRenderQuality)
        maxRenderQuality = try values.decode(Double.self, forKey: .maxRenderQuality)
        showObjects = try values.decode(Bool.self, forKey: .showObjects)
        drawGrid = try values.decode(Bool.self, forKey: .drawGrid)
        drawAnchor = try values.decode(Bool.self, forKey: .drawAnchor)
        enableEffects = try values.decode(Bool.self, forKey: .enableEffects)
        updateMode = try values.decode(Int.self, forKey: .updateMode)
        allowUserMaps = try values.decode(Bool.self, forKey: .allowUserMaps)
        loggingLevel = try values.decode(Int.self, forKey: .loggingLevel)
        renderCallbacks = try values.decode(Bool.self, forKey: .renderCallbacks)
        cameraCallbacks = try values.decode(Bool.self, forKey: .cameraCallbacks)
        mouseFilters = try values.decode(Int.self, forKey: .mouseFilters)
        ignoreZoomConstraints = try values.decode(Bool.self, forKey: .ignoreZoomConstraints)
        usePreviousCamera = try values.decode(Bool.self, forKey: .usePreviousCamera)
        demoFiles = try values.decode(Array.self, forKey: .demoFiles)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        try container.encode(renderQuality, forKey: .renderQuality)
        try container.encode(objectRenderQuality, forKey: .objectRenderQuality)
        try container.encode(textRenderQuality, forKey: .textRenderQuality)
        try container.encode(maxRenderQuality, forKey: .maxRenderQuality)
        try container.encode(showObjects, forKey: .showObjects)
        try container.encode(drawGrid, forKey: .drawGrid)
        try container.encode(drawAnchor, forKey: .drawAnchor)
        try container.encode(enableEffects, forKey: .enableEffects)
        try container.encode(updateMode, forKey: .updateMode)
        try container.encode(allowUserMaps, forKey: .allowUserMaps)
        try container.encode(loggingLevel, forKey: .loggingLevel)
        try container.encode(renderCallbacks, forKey: .renderCallbacks)
        try container.encode(cameraCallbacks, forKey: .cameraCallbacks)
        try container.encode(mouseFilters, forKey: .mouseFilters)
        try container.encode(ignoreZoomConstraints, forKey: .ignoreZoomConstraints)
        try container.encode(usePreviousCamera, forKey: .usePreviousCamera)
        try container.encode(demoFiles, forKey: .demoFiles)
    }
}



extension DemoPreferences: CustomDebugReflectable {

    func dumpStatistics() {
        let spacing = "     "
        var headerString = "\(spacing)Demo Preferences\(spacing)"
        let headerUnderline = String(repeating: "-", count: headerString.count )

        var animModeString = "**invalid**"
        if let demoAnimationMode = TileUpdateMode.init(rawValue: updateMode) {
            animModeString = demoAnimationMode.name
        }

        //var mouseFilterStrings = mouseFilters

        var loggingLevelString = "**invalid**"
        if let demoLoggingLevel = LoggingLevel.init(rawValue: loggingLevel) {
            loggingLevelString = demoLoggingLevel.description
        }

        headerString = "\n\(headerString)\n\(headerUnderline)\n"
        headerString += " - render quality:              \(renderQuality)\n"
        headerString += " - object quality:              \(objectRenderQuality)\n"
        headerString += " - text quality:                \(textRenderQuality)\n"
        headerString += " - max render quality:          \(maxRenderQuality)\n"
        headerString += " - show objects:                \(showObjects)\n"
        headerString += " - draw grid:                   \(drawGrid)\n"
        headerString += " - draw anchor:                 \(drawAnchor)\n"
        headerString += " - effects rendering:           \(enableEffects)\n"
        headerString += " - update mode:                 \(updateMode)\n"
        headerString += " - animation mode:              \(animModeString)\n"
        headerString += " - allow user maps:             \(allowUserMaps)\n"
        headerString += " - logging level:               \(loggingLevelString)\n"
        headerString += " - render callbacks:            \(renderCallbacks)\n"
        headerString += " - camera callbacks:            \(cameraCallbacks)\n"
        headerString += " - ignore camera contstraints:  \(ignoreZoomConstraints)\n"
        headerString += " - user previous camera:        \(usePreviousCamera)\n"
        headerString += " - mouse filters:\n"

        print("\(headerString)\n\n")
    }
}




extension FileManager {

    func listFiles(path: String, withExtensions: [String] = []) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls: [URL] = []
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }

            let url = URL(fileURLWithPath: s, relativeTo: baseurl)
            let pathExtension = url.pathExtension.lowercased()

            if withExtensions.contains(pathExtension) || (withExtensions.isEmpty) {
                urls.append(url)
            }
        })
        return urls
    }
}


extension TileUpdateMode {

    /// Control string to be used with the render stats menu.
    public var uiControlString: String {
        switch self {
        case .dynamic: return "Cached"
        case .full: return "Full"
        case .actions: return "SpriteKit Actions"
        }
    }
}



extension SKTilemap.RenderStatistics {

    /// Returns an attributed string with the current CPU usage percentage.
    var processorAttributedString: NSAttributedString {
        let fontSize: CGFloat
        fontSize = 9

        let labelText = "CPU Usage: \(cpuPercentage)%"
        let labelStyle = NSMutableParagraphStyle()
        labelStyle.alignment = .left
        labelStyle.firstLineHeadIndent = 0
        let fontColor: UIColor
        switch cpuPercentage {
        case 0...18:
            fontColor = UIColor(hexString: "#7ED321")
        case 19...30:
            fontColor = UIColor(hexString: "#FFFFFF")
        case 31...49:
            fontColor = UIColor(hexString: "#F8E71C")
        case 50...74:
            fontColor = UIColor(hexString: "#F5A623")
        default:
            fontColor = UIColor(hexString: "#FD4444")
        }

        let cpuStatsAttributes = [
            .font: UIFont(name: "Courier", size: fontSize)!,
            .foregroundColor: fontColor,
            .paragraphStyle: labelStyle
            ] as [NSAttributedString.Key: Any]

        return NSMutableAttributedString(string: labelText, attributes: cpuStatsAttributes)
    }
}
