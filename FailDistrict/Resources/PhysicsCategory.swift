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
    static let fruit: UInt32 = 0b1_0000
    static let fruitTrigger: UInt32 = 0b10_0000
    static let monitor: UInt32 = 0b100_0000
    static let monitorTrigger: UInt32 = 0b1000_0000
    static let manhole: UInt32 = 0b1_0000_0000
}
