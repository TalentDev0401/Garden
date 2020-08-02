//
//  Garden.swift
//  Garden
//
//  Created by Admin on 03.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Garden: CustomStringConvertible, Hashable {
    
    var hashValue: Int {
        return Int(row * 10 + column)
    }
    
    static func ==(lhs: Garden, rhs: Garden) -> Bool {
        return lhs.column == rhs.column && lhs.row == rhs.row

    }

    var description: String {
        return "square:(\(column),\(row))"
    }
    
    var column: Int
    var row: Int
    var sprite: SKSpriteNode

    init(column: Int, row: Int, sprite: SKSpriteNode) {
        self.column = column
        self.row = row
        self.sprite = sprite
        
    }
}
