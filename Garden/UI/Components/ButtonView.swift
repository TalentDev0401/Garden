//
//  ButtonView.swift
//  Garden
//
//  Created by Admin on 01.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct ButtonView: View {
    @State private var showingAlert = false
    var body: some View {
        HStack {
            Button(action: {
                if SharedInstance.shared.matrix + 2 < SharedInstance.shared.displayTileNumber {
                    if let scene = sceneDelegate()?.gardenController.view?.scene as? SKTiledScene {
                        if scene.cameraNode.zoom > 0.2 {
                            self.showingAlert = false
                            SharedInstance.shared.matrix += 2
                            sceneDelegate()?.gardenController.createGardenMap(new: true)
                        } else {
                            DispatchQueue.main.async {
                                self.showingAlert = false
                                SharedInstance.shared.matrix += 2
                                sceneDelegate()?.gardenController.createGardenMap(new: false)
                            }
                        }
                    }
                } else {
                    self.showingAlert = true
                }
            }) {
                Image("plus").foregroundColor(Color.white)
            }.frame(maxWidth: 75, maxHeight: 55).background(Color.init(UIColor.init(hexString: "#347873"))).cornerRadius(5).shadow(color: .primary, radius: 5).alert(isPresented: $showingAlert) {
                Alert(title: Text("Warning!"), message: Text("Tile is full in view"), dismissButton: .default(Text("Got it!")))
            }
            Spacer()
            Button(action: {
                guard let scene = sceneDelegate()?.gardenController.view?.scene as? SKTiledScene else { return }
                
                DispatchQueue.main.async {
                    if let oldlayer_garden = scene.tilemap.tileLayers(named: "garden").first {
                        oldlayer_garden.removeAllChildren()
                    }
                    if let oldlayer_object = scene.tilemap.tileLayers(named: "object").first {
                        oldlayer_object.removeAllChildren()
                    }
                    SharedInstance.shared.objectArray.removeAll()
                    SharedInstance.shared.matrix = 3
                    UserDefaults.standard.removeObject(forKey: "flowers")
                    UserDefaults.standard.synchronize()
                    sceneDelegate()?.gardenController.createGardenMap(new: true)
                }
            }) {
                Text("NEW").padding()
                    .frame(maxWidth: 75)
                    .foregroundColor(Color.white)
            }.background(Color.init(UIColor.init(hexString: "#347873"))).cornerRadius(5).shadow(color: .primary, radius: 5)
        }.padding(.all)
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView()
    }
}
