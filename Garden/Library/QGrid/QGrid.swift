//
//  QGrid.swift
//  Garden
//
//  Created by Admin on 29.03.2020.
//  Copyright © 2020 Bohdan Dankovych All rights reserved.
//

import SwiftUI


/// A container that presents rows of data arranged in multiple columns.
@available(iOS 13.0, OSX 10.15, *)
public struct QGrid<Data, Content>: View
  where Data : RandomAccessCollection, Content : View, Data.Element : Identifiable {
  private struct QGridIndex : Identifiable { var id: Int }
  
  // MARK: - STORED PROPERTIES
  
  private let columns: Int
  private let columnsInLandscape: Int
  private let vSpacing: CGFloat
  private let hSpacing: CGFloat
  private let vPadding: CGFloat
  private let hPadding: CGFloat
  
  private let data: [Data.Element]
  private let content: (Data.Element) -> Content
  
  // MARK: - INITIALIZERS
  
  /// Creates a QGrid that computes its cells on demand from an underlying
  /// collection of identified data.
  ///
  /// - Parameters:
  ///     - data: A collection of identified data.
  ///     - columns: Target number of columns for this grid, in Portrait device orientation
  ///     - columnsInLandscape: Target number of columns for this grid, in Landscape device orientation; If not provided, `columns` value will be used.
  ///     - vSpacing: Vertical spacing: The distance between each row in grid. If not provided, the default value will be used.
  ///     - hSpacing: Horizontal spacing: The distance between each cell in grid's row. If not provided, the default value will be used.
  ///     - vPadding: Vertical padding: The distance between top/bottom edge of the grid and the parent view. If not provided, the default value will be used.
  ///     - hPadding: Horizontal padding: The distance between leading/trailing edge of the grid and the parent view. If not provided, the default value will be used.
  ///     - content: A closure returning the content of the individual cell
  public init(_ data: Data,
              columns: Int,
              columnsInLandscape: Int? = nil,
              vSpacing: CGFloat = 10,
              hSpacing: CGFloat = 10,
              vPadding: CGFloat = 10,
              hPadding: CGFloat = 10,
              content: @escaping (Data.Element) -> Content) {
    self.data = data.map { $0 }
    self.content = content
    self.columns = max(1, columns)
    self.columnsInLandscape = columnsInLandscape ?? max(1, columns)
    self.vSpacing = vSpacing
    self.hSpacing = hSpacing
    self.vPadding = vPadding
    self.hPadding = hPadding
  }
  
  // MARK: - COMPUTED PROPERTIES
  
  private var rows: Int {
    data.count / self.cols
  }
  
  private var cols: Int {
    return UIDevice.current.orientation.isLandscape ? columnsInLandscape : columns
  }
  
  /// Declares the content and behavior of this view.
  public var body : some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: self.vSpacing) {
                HStack(spacing: self.hSpacing) {
                ForEach((0..<self.rows).map { QGridIndex(id: $0) }) { row in
                    self.rowAtIndex(row.id * self.cols,
                                    geometry: geometry)
                      
                  }
              }
              
            // Handle last row
            if (self.data.count % self.cols > 0) {
              self.rowAtIndex(self.cols * self.rows,
                              geometry: geometry,
                              isLastRow: true)
            }
          }
        }
        .padding(.horizontal, self.hPadding)
        .padding(.vertical, self.vPadding)
    }
  }
  
  // MARK: - `BODY BUILDER` 💪 FUNCTIONS
  
  private func rowAtIndex(_ index: Int,
                          geometry: GeometryProxy,
                          isLastRow: Bool = false) -> some View {
    VStack(spacing: self.hSpacing) {
      ForEach((0..<(isLastRow ? data.count % cols : cols))
      .map { QGridIndex(id: $0) }) { column in
        self.content(self.data[index + column.id])
            .frame(width: self.contentWidthFor(geometry))
      }
      if isLastRow { Spacer() }
    }
  }
    
  // MARK: - HELPER FUNCTIONS
  
  private func contentWidthFor(_ geometry: GeometryProxy) -> CGFloat {
   
    let hSpacings = hSpacing * (CGFloat(self.cols) - 1)
    let width = geometry.size.width - hSpacings - hPadding * 2
    return width / CGFloat(self.cols)
  }
    private func contentHeightFor(_ geometry: GeometryProxy) -> CGFloat {
        let vSpacings = vSpacing * (CGFloat(self.cols) - 1)
        let height = geometry.size.width - vSpacings - vPadding * 2
        return height / CGFloat(self.cols)
    }
}

