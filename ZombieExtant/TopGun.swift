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
    var image = 1
    
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
        
        //Initializing the particle emitter: Smoke
        let smokeEmitter = gameScene.childNode(withName: "\(self.name!)Smoke") as! SKEmitterNode
        smokeEmitter.particleBirthRate += 1
        
        //Initializing the particle emitter: Sparkds
        let particle = SKEmitterNode(fileNamed: "Sparks")!
        self.addChild(particle)
        let randX: CGFloat = CGFloat(arc4random_uniform(UInt32(self.size.width))) - self.size.width / 2
        let randY: CGFloat = CGFloat(arc4random_uniform(UInt32(self.size.height))) - self.size.height / 2
        particle.position = CGPoint(x: randX, y: randY)
        particle.setScale(2.0)
        particle.zPosition = 6
        let wait = SKAction.wait(forDuration: 0.3)
        let remove = SKAction.run({
            particle.removeFromParent()
        })
        let seq = SKAction.sequence([wait, remove])
        self.run(seq)
        
        //Check if health is 0 then remove the turret
        if health <= 0 {
            
            var imageArray: [SKTexture] = [SKTexture]()
            
            for i in 1...7 {
                //Appending 7 images
                imageArray.append(SKTexture(imageNamed: "explosion\(i)"))
            }
            //Adding the explosions
            let animate = SKAction.animate(with: imageArray, timePerFrame: 0.1)
            
            //Removing the base
            let removeTurret = SKAction.run({ [unowned self] in
                let smokeEmitter = self.gameScene.childNode(withName: "\(self.name!)Smoke") as! SKEmitterNode
                smokeEmitter.zPosition = 5
                smokeEmitter.particleBirthRate = 5
                
                self.removeFromParent()
            })
            
            let removeBase = SKAction.run({ [unowned self] in
                let base = self.gameScene.childNode(withName: "//\(self.name!)Base") as! SKSpriteNode
                base.physicsBody = nil
            })
            
            //Initializing the explosions
            let firstExplosion = SKAction.run({ [unowned self] in
                self.explosion1.run(animate)
            })
            let secondExplosion = SKAction.run({ [unowned self] in
                self.explosion2.run(animate)
            })
            let thirdExplosion = SKAction.run({ [unowned self] in
                self.explosion3.run(animate)
            })
            
            let runAnimation = SKAction.run({ [unowned self] in
                //Run the death animation
                self.run(SKAction.sequence([SKAction.wait(forDuration: 0), firstExplosion]))
                self.run(SKAction.sequence([SKAction.wait(forDuration: 0.1), secondExplosion]))
                self.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), thirdExplosion]))
                
            })
            
            let wait = SKAction.wait(forDuration: 1.0)
            let seq = SKAction.sequence([runAnimation, wait , removeBase, removeTurret])
            self.run(seq)
        }
    }
    
    func fireBullet() {
        
        //Animate the gun
        let animation = SKAction.init(named: "muzzle")
        self.muzzle.run(animation!, withKey: "muzzle")
        
        if image == 1 {
            self.texture = SKTexture(imageNamed: "MG_Tier3")
            image = 2
        } else if image == 2 {
            self.texture = SKTexture(imageNamed: "MG_Tier32")
            image = 1
        }
        
        //Adding the bullet to the scene
        let bullet = Bullet()
        bullet.zPosition = 101
        gameScene.bulletLayer.addChild(bullet)
        //gameScene.addChild(bullet)
        
        //Get the bullet ready to shoot
        bullet.position.x = self.position.x + CGFloat(arc4random_uniform(8)) - 4
        bullet.position.y = self.position.y + CGFloat(arc4random_uniform(8)) - 4
        bullet.zRotation = self.zRotation
        
        //Let it rip
        bullet.shoot()
    }
    
    func connectExplosion() {
        //Set up turret here
        
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
        self.zPosition = 101
    }
}
