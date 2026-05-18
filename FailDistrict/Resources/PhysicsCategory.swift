//
//  PhysicsCategory.swift
//  FailDistrict
//
//  Created by Hansel Meinhard on 13/05/26.
//

import Foundation

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let ground: UInt32 = 0b10
    static let tree: UInt32 = 0b100
    static let treeTrigger: UInt32 = 0b1000
}
