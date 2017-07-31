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
    var health = 100
    var explosion1: SKSpriteNode!
    var explosion2: SKSpriteNode!
    var explosion3: SKSpriteNode!
    var muzzle: SKSpriteNode!
    
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
        
        //Check if health is 0 then remove the turret
        if health <= 0 {
            
            var imageArray: [SKTexture] = [SKTexture]()
            for i in 1...7 {
                imageArray.append(SKTexture(imageNamed: "explosion\(i)"))
            }
            let animate = SKAction.animate(with: imageArray, timePerFrame: 0.1)
            
            let removeTurret = SKAction.run({ [unowned self] in
                self.removeFromParent()
            })
            
            let removeBase = SKAction.run({ [unowned self] in
                let base = self.gameScene.childNode(withName: "\(self.name!)Base") as! SKSpriteNode
                base.physicsBody = nil
            })
            
            let runAnimation = SKAction.run({ [unowned self] in
                self.explosion1.run(animate)
                self.explosion2.run(animate)
                self.explosion3.run(animate)
            })
            
            let wait = SKAction.wait(forDuration: 0.8)
            let seq = SKAction.sequence([runAnimation, wait , removeBase, removeTurret])
            self.run(seq)
        }
    }
    
    func fireBullet() {
        
        //Animate the gun
        let animation = SKAction.init(named: "muzzle")
        self.muzzle.run(animation!, withKey: "muzzle")
        
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
    
    func connectExplosion() {
        explosion1 = self.childNode(withName: "explosion1") as! SKSpriteNode
        explosion2 = self.childNode(withName: "explosion2") as! SKSpriteNode
        explosion3 = self.childNode(withName: "explosion3") as! SKSpriteNode
        muzzle = self.childNode(withName: "muzzle") as! SKSpriteNode
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        connectExplosion()
    }
}
