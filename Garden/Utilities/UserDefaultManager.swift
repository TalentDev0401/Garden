//
//  UserDefaultManager.swift
//  Garden
//
//  Created by Admin on 03.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import UIKit

class UserDefaultManager {
    static let shared = UserDefaultManager()
        
    func SaveTilesPosition(coord: CGPoint) {
        
        var flowers: [[String:Any]] = [[:]]
        if let save_flowers = UserDefaults.standard.array(forKey: "flowers") as? [[String: Any]] {
            if save_flowers.count != 0 {
                flowers = save_flowers
            }
        }
 
        var flower : [String:Any] = [:]
        flower["column"] = coord.x
        flower["row"] = coord.y
        flower["flowername"] = SharedInstance.shared.selectedImg
        
        flowers.append(flower)
        let empty = flowers[0].isEmpty
        if empty {
            flowers.remove(at: 0)
        }
        /**
        Save flower data to user default
        */
        UserDefaults.standard.set(flowers, forKey: "flowers")
    }
    
    func UpdateMultiTilesPosition(oldPosition: CGPoint, newPosition: CGPoint, save_flowers: [[String:Any]], completion: @escaping (_ success: Bool?)->()) {
        
        var flowers = save_flowers
        for i in 0...flowers.count - 1 {
            if let column = flowers[i]["column"] as? CGFloat, let row = flowers[i]["row"] as? CGFloat {
                if column == oldPosition.x && row == oldPosition.y {
                    flowers[i]["column"] = newPosition.x
                    flowers[i]["row"] = newPosition.y
                    break
                }
            }
        }
               
        UserDefaults.standard.set(flowers, forKey: "flowers")
        completion(true)
    }
    /**
     Rounded CGFloat to Int
     */
    func roundToHundreds(_ value: Int) -> Int {
        return value/100 * 100 + (value % 100)/50 * 100
    }
}
