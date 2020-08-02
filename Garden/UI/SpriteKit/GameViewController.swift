//
//  GameViewController.swift
//  Garden
//
//  Created by Admin on 29.03.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import UIKit
import SwiftUI
import SpriteKit
import GameplayKit

//MARK: - ViewControllerRepresentable

struct GameView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<GameView>) -> GameViewController {
        return GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: UIViewControllerRepresentableContext<GameView>) {
    }
}

class GameViewController: UIViewController, Loggable {
    
    var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel
    
    override func loadView() {
        super.loadView()
        view = SKView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        loggingLevel = TiledGlobals.default.loggingLevel
        sceneDelegate()?.gardenController.loggingLevel = loggingLevel
        sceneDelegate()?.gardenController.view = skView
                
        guard let currentURL = sceneDelegate()?.gardenController.currentURL else {
            log("no tilemap to load.", level: .warning)
            return
        }
        
        /* SpriteKit optimizations */
        skView.shouldCullNonVisibleNodes = true
        skView.ignoresSiblingOrder = true
        
        sceneDelegate()?.gardenController.loadScene(url: currentURL, usePreviousCamera: (sceneDelegate()?.gardenController.preferences.usePreviousCamera)!)
    }
   
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
