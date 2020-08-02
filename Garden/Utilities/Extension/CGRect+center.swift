//
//  CGRect+center.swift
//  Garden
//
//  Created by Admin on 02.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import CoreGraphics

extension CGRect {
    var centerD: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
