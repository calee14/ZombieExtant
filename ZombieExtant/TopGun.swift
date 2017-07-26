//
//  TopGun.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/24/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

class TopGun: SKSpriteNode {
    
    weak var gameScene: GameScene!
    var health = 200
    
    func turnGun(destPoint: CGPoint) {
        //turns the gun
        let adjust = Double.pi/2.0
        let v1 = CGVector(dx:0, dy:1)
        let v2 = CGVector(dx:destPoint.x - position.x, dy: destPoint.y - position.y)
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        zRotation = angle - CGFloat(adjust)
    }
    
    func removeHealth() {
        self.health -= 10
        if health <= 0 {
            self.removeFromParent()
        }
    }
    
    func fireBullet() {
        //Adding the bullet to the scene
        let bullet = Bullet()
        gameScene.bulletLayer.addChild(bullet)
        //gameScene.addChild(bullet)
        
        //Get the bullet ready to shoot
        bullet.position = self.position
        bullet.zRotation = self.zRotation
        
        //Let it rip
        bullet.shoot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
