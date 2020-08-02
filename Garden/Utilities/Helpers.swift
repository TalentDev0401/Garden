//
//  Helpers.swift
//  Garden
//
//  Created by Admin on 29.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SwiftUI

var tView_height: CGFloat {
    let height = UIScreen.screenHeight
    let model = modelNameDetect()
    if model == iPhone {
        if height >= 812 {
            return 330
        } else if height > 736 && height < 812 {
            return 270
        } else {
            return 270
        }
    } else if model == iPad {
        return 300
    } else {
        return height
    }
}
var column: Int {
    let model = modelNameDetect()
    if model == iPhone {
        return 3
    } else if model == iPad {
        return 3
    } else {
        return 3
    }
}

func modelNameDetect() -> String {
    let modelName = UIDevice.modelName
    if modelName.contains("iPad") {
        return iPad
    } else if modelName.contains("iPhone") {
        return iPhone
    } else {
        return iPhone
    }
}
