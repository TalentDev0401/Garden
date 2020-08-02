//
//  SharedInstance.swift
//  Garden
//
//  Created by Admin on 03.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

class SharedInstance {
    static let shared = SharedInstance()
    
    var layerImges: [String] = []
    var selectedImg: String!
    var matrix: Int!
//    var mappoint: CGPoint?
    var gardenArray: [Garden] = []
    var objectArray: [Object] = []
    var centerLocation: CGPoint!
    var displayTileNumber: Int!
    var tilesets = ["BushyTree_1", "BushyTree_2", "BushyTree_3", "Cactus_1", "Cactus_2", "Cactus_3", "Elk_1", "Elk_2", "Elk_3", "Palm_1", "Palm_2", "Palm_3"]
}
