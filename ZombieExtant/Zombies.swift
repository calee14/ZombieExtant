//
//  Zombies.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/25/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

class Zombie: SKSpriteNode {
    
    weak var gameScene: GameScene!
    var spd = 20.0
    var target: TopGun!
    
    func moveToClosestTurret() {
        //Creating an array to store our data
        var arrayDist: [(turret: Int, dist: CGFloat)] = []
        
        //TODO: fix for loop
        for turret in 1...gameScene.turretLayer.children.count {
            let num = turret - 1
            //Gets the distance of all the turrets from the tap
            let distance: CGFloat = gameScene.distanceTo(self.position, gameScene.turretLayer.children[num].position)
            arrayDist.append((turret: num, dist: distance))
        }
        //Looks for the turret with the less distance to the tap
        var minimum = 0
        for item in arrayDist {
            //Takes an item from the array
            var count = 0
            for dist in arrayDist {
                //Compares it with the others
                if item.dist < dist.dist {
                    //Updates the count
                    count += 1
                }
            }
            //if the item is greater than the others use it
            if count == arrayDist.count - 1 {
                print("found it")
                minimum = item.turret
            }
        }
        target = gameScene.turretLayer.children[minimum] as! TopGun
        self.run(SKAction.move(to: gameScene.turretLayer.children[minimum].position, duration: spd))
    }
    
    func attack() {
        //Attack the turret
        let wait = SKAction.wait(forDuration: 0.5)
        let attack = SKAction.run({ [unowned self] in
            //Takes away health from the player
            self.target.removeHealth()
            //Checks if there are no more turrets in the game then stop all actions
            if self.gameScene.turretLayer.children.count == 0 {
                self.removeAllActions()
                return
            }
            //if our target health is zero move on to the next one
            if self.target.health <= 0 {
                self.removeAction(forKey: "attack")
                self.moveToClosestTurret()
            }
            print(self.target.health)
        })
        //Run the attack actions
        let seq = SKAction.sequence([wait, attack])
        let eat = SKAction.repeatForever(seq)
        self.run(eat, withKey: "attack")
    }
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        //initializing the zombie
        self.name = "zombie"
        self.texture = SKTexture(imageNamed: "zombie50001")
        self.size = (self.texture?.size())!
        self.zPosition = 5
        self.xScale = 0.13
        self.yScale = 0.13
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 1
        self.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}
