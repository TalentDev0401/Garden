//
//  GridCell.swift
//  Garden
//
//  Created by Admin on 01.04.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct GridCell: View {

  @State var imgName: String
  
  var body: some View {
    VStack() {
        Image(uiImage: UIImage(named: imgName)!)
        .resizable()
        .frame(width: 70, height: 70, alignment: .center)
        .shadow(color: .primary, radius: 5)
        .padding(7).onDrag {
            SharedInstance.shared.selectedImg = self.imgName
            return NSItemProvider(object: UIImage(named: self.imgName)!) }
    }
  }
}
