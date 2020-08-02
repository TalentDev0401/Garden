//
//  ImageDropDelegate.swift
//  Garden
//
//  Created by Admin on 29.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SwiftUI

struct ImgDropDelegate: DropDelegate {
    
    @Binding var images: [Int: UIImage]
    @Binding var active: Int
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.file-UIImage"])
    }
    
    func dropEntered(info: DropInfo) {
        print("drop entered")
    }
    
    // - Detecting dropping touch event
    func performDrop(info: DropInfo) -> Bool {
       
        if let scene = sceneDelegate()?.gardenController.view?.scene as? SKTiledScene {
            var performLocation: CGPoint!
            /**
             Check UIDevice type(whether it is iphone x type or not)
             */
            let notch = UIDevice.current.notch
            let modelName = UIDevice.modelName
            if modelName.contains("iPhone 11") {
                performLocation = CGPoint(x: info.location.x, y: info.location.y + notch)
            } else {
                performLocation = info.location
            }
            
            let positionInScene = scene.view!.convert(performLocation, to: scene)
            // convert a scene point to the layer's position
            let positionInLayer = scene.tilemap.tileLayers(named: "garden").first!.convert(positionInScene, from: scene)
            // get the coordinate at the specified point
            let coord = scene.tilemap.tileLayers(named: "garden").first!.coordinateForPoint(positionInLayer)
            
            for item in SharedInstance.shared.gardenArray {
                if CGPoint(x: item.column, y: item.row) == coord {
                    
                    let sameplaces = SharedInstance.shared.objectArray.filter { $0.column == item.column && $0.row == item.row }
                    
                    if sameplaces.count == 0 {
                        /**
                         Add new tile to obejct layer in SKScene
                         */
                        sceneDelegate()?.gardenController.addNewTileSet(position: coord, img: SharedInstance.shared.selectedImg)
                        /**
                         Save matrix number to user default
                         */
                        self.SaveObjectTileInfoToPlist(coord: coord)
                        return true
                    } else {
                        return false
                    }
                }
            }
            return false
        } else { return false}
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
                            
        return nil
    }
    
    func dropExited(info: DropInfo) {
        self.active = 0
    }
   
    // - Save tile's info
    func SaveObjectTileInfoToPlist(coord: CGPoint) {
        /**
         Case multi tiles' info
         */
        UserDefaultManager.shared.SaveTilesPosition(coord: coord)
    }
}
