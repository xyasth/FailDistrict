//
//  Contactable.swift
//  FailDistrict
//
//  Created by Prayogo kosasih. W on 18/05/26.
//

import GameplayKit
import SpriteKit

protocol Contactable {
    func didBeginContact(with other: GKEntity?, contact: SKPhysicsContact)
    func didEndContact(with other: GKEntity?, contact: SKPhysicsContact)
}
