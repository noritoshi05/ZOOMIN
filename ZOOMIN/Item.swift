//
//  Item.swift
//  ZOOMIN
//
//  Created by 김승준 on 5/29/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
