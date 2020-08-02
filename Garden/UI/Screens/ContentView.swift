//
//  ContentView.swift
//  Garden
//
//  Created by Admin on 29.03.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
          
    //MARK: - Private variables

    @State private var imageArr: [Int: UIImage] = [:]
    @State private var active = 0
    private var loggingLevel: LoggingLevel = TiledGlobals.default.loggingLevel
    private let imageModels: [ImageModel]
    
    init(imageModels: [ImageModel]) {
        self.imageModels = imageModels
    }
     
    //MARK: - Lifecycle
    var body: some View {
                  
        let dropDelegate = ImgDropDelegate(images: $imageArr, active: $active)
        
        return VStack {
            GameView().edgesIgnoringSafeArea(.all).onDrop(of: ["public.file-UIImage"], delegate: dropDelegate).overlay(ButtonView(), alignment: .bottom)
            QGrid(imageModels,
                    columns: 3,
                    vSpacing: 0,
                    hSpacing: 0,
                    vPadding: 0,
                    hPadding: 0) { img in
                    GridCell(imgName: img.imgname)
            }.frame(width: UIScreen.screenWidth, height: tView_height, alignment: .center)
        }.frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .bottom)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(imageModels: [])
    }
}
