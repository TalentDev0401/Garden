//
//  Constants.swift
//  Garden
//
//  Created by Admin on 03.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import SpriteKit

func sceneDelegate() -> SceneDelegate? {
    // getting access to the window object from SceneDelegate
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let sceneDelegate = windowScene.delegate as? SceneDelegate {
        return sceneDelegate
    }else {
        return nil
    }
}

let images = ["Bush_Red_1", "Bush_Red_2", "Bush_Red_3", "Bush_White_1", "Bush_White_2", "Bush_White_3", "Bush_Yellow_1", "Bush_Yellow_2", "Bush_Yellow_3", "BushyTree_1", "BushyTree_2", "BushyTree_3", "Cactus_1", "Cactus_2", "Cactus_3", "Elk_1", "Elk_2", "Elk_3", "Flowers_Red_1", "Flowers_Red_2", "Flowers_Red_3", "Flowers_White_1", "Flowers_White_2", "Flowers_White_3", "Flowers_Yellow_1", "Flowers_Yellow_2", "Flowers_Yellow_3", "Palm_1", "Palm_2", "Palm_3"]

let dirts = ["1_1_Dirt", "1_2_Dirt", "1_3_Dirt", "2", "3", "4", "5", "6", "7", "8", "9"]

let grasses = ["1_1_Grass", "1_2_Grass", "1_3_Grass"]

let iPhone = "iPhone"
let iPad = "iPad"
