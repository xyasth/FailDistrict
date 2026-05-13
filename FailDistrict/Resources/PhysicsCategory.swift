//
//  PhysicsCategory.swift
//  FailDistrict
//
//  Created by Hansel Meinhard on 13/05/26.
//

import Foundation

// Struct untuk memisahkan identitas benturan fisik
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let ground: UInt32 = 0b10
    static let hazard: UInt32 = 0b100 // Disiapkan untuk temanmu yang bikin jebakan
}
