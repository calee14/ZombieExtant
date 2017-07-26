//
//  Bullet.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/25/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

class Bullet: SKSpriteNode {
    
    var bulletHit = false
    
    func shoot() {
        //Physics for applying the force to the node
        // grab the spaceship rotation and add M_PI_2
        let projectileRotation : CGFloat = self.zRotation
        let calcRotation : Float = Float(projectileRotation) + Float(Double.pi);
        
        // cosf and sinf use a Float and return a Float
        // however CGVector need CGFloat
        let intensity : CGFloat = 1000 // put your value
        let xv = intensity * CGFloat(cosf(calcRotation))
        let yv = intensity * CGFloat(sinf(calcRotation))
        let vector : CGVector = CGVector(dx: xv, dy: yv)
        
        // apply force to spaceship
        self.physicsBody?.applyForce(vector)
    }
    
    func checkPosition() {
        //check if outside screen
            //remove if outside screen
        // else return
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        //Initializing the bullet
        self.name = "bullet"
        self.zPosition = 5
        self.texture = SKTexture(imageNamed: "Bullet1")
        self.color = .clear
        self.size = (self.texture?.size())!
        self.physicsBody = SKPhysicsBody(rectangleOf: (self.texture?.size())!)
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 2
        self.physicsBody?.affectedByGravity = false
        self.xScale = 0.4
        self.yScale = 0.6
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
