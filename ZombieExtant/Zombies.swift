//
//  Zombies.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/25/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

enum ZombieType {
    case fast, normal, big
}

enum ZombieActions {
    case idle, walk, attack, death
}

class Zombie: SKSpriteNode {
    
    weak var gameScene: GameScene!
    weak var mainMenu: MainMenu!
    
    /* Game Scene Variables */
    var spd = 20.0
    weak var target: TopGun!
    var zombieType: ZombieType = .normal
    var health = 1
    var zombieAction: ZombieActions = .idle
    var zombieImage = 1
    var initialScale = 0.13
    var zombieScene: SKScene!
    /* Main Menu Variables */
    var finalPos: CGPoint!
    
    /* GameScene Function */
    func moveToClosestTurret() {
        print("we are moving")
        
        if self.zombieAction == .death { return }
        
        self.removeAllActions()
        //Animate the zombie for the specific action
        //Keep track of what the zombie is doing
        self.zombieAction = .walk
        self.animateZombie()
        
        if target == nil {
            //Creating an array to store our data
            var arrayDist: [(turret: Int, dist: CGFloat)] = []
        
            //TODO: fix for loop
            for turret in 1...gameScene.turretLayer.children.count {
                //If the turret is the same one we could skip it
                if target != nil {
                    let thing = gameScene.turretLayer.children[turret - 1] as! TopGun
                    if thing.name! == target.name { continue }
                }
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
        }
        
        //Move our zombie to the target
        self.run(SKAction.move(to: target.position, duration: spd),
                //After action is done, just call the completion-handler.
            completion: { [unowned self] in
                //If there are no more zombies we can stop the zombie
                if self.gameScene.turretLayer.children.count == 0 {
                    self.removeAllActions()
                    return
                }
                self.target = nil
                self.moveToClosestTurret()
        })
        
        //Check Note may remove due to difficulty
        /* Checking implementation */
            /* put movement here */
    }
    
    func takeHitAnimation() {
        
        if self.zombieAction == .death { return }
        
        self.removeAllActions()
        
        //Animation scaling for the walking zombie
        if self.position.x < gameScene.size.width / 2 {
            self.xScale = CGFloat(initialScale * -1)
        } else if self.position.x < gameScene.size.width / 2 {
            self.xScale = xScale
        }
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        
        //Images 1 - 3 are falling for zombies
        for i in 1...3 {
            imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)000\(i)"))
        }
        let animate = SKAction.animate(with: imageArray, timePerFrame: 0.2) //0.2
        let wait = SKAction.wait(forDuration: spd * 0.01 * Double(imageArray.count))
        let resumeActions = SKAction.run({ [unowned self] in
            //Animation scaling for the walking zombie
            if self.position.x < self.gameScene.size.width / 2 {
                self.xScale = -self.xScale
            } else if self.position.x < self.gameScene.size.width / 2 {
                self.xScale = self.xScale
            }
            if self.zombieAction == .attack {
                self.attack()
            } else if self.zombieAction == .walk {
                self.moveToClosestTurret()
            }
        })
        let seq = SKAction.sequence([animate, wait, resumeActions])
        self.run(seq)
    }
    
    func deathAnimation() {
        
        if zombieAction == .death { return }
        
        //Keep track of what the zombie is doing
        zombieAction = .death
        
        //Animate death scene
        self.removeAllActions()
        self.physicsBody = nil
        
        //Animation for the walking zombie
        if self.position.x < gameScene.size.width / 2 {
            self.xScale = CGFloat(initialScale * -1)
        } else if self.position.x < gameScene.size.width / 2 {
            self.xScale = xScale
        }
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        
        //Images  20 , 29 - 32 are falling for zombies
        imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)0020"))
        for i in 29...32 {
            imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)00\(i)"))
        }
        let animate = SKAction.animate(with: imageArray, timePerFrame: spd * 0.01) //0.2
        let wait = SKAction.wait(forDuration: spd * 0.01 * Double(imageArray.count))
        let remove = SKAction.run({ [unowned self] in
            //self.gameScene.toBeDeleted.append(self)
            self.removeFromParent()
        })
        let seq = SKAction.sequence([animate, wait, remove])
        self.run(seq)
    }
    
    func attack() {
        
        if self.zombieAction == .death { return }
        
        //Animate the zombie for the specific action
        self.attackZombie()
        
        //Keep track of the zombie actions
        zombieAction = .attack
        
        //Attack the turret
        let wait = SKAction.wait(forDuration: spd * 0.01 * 6.0) //0.2 * num of animates in array
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
                print("we lost our target")
                self.target = nil
                self.removeAction(forKey: "attack")
                self.moveToClosestTurret()
            }
            //print(self.target.health)
        })
        //Run the attack actions
        let seq = SKAction.sequence([wait, attack])
        let eat = SKAction.repeatForever(seq)
        self.run(eat, withKey: "attack")
    }
    
    func attackZombie() {
        
        if self.zombieAction == .death { return }
        
        //Animaiton for the attacking zombie
        self.removeAction(forKey: "walk")
        if self.position.x < gameScene.size.width / 2 {
            self.xScale = CGFloat(initialScale * -1)
        } else if self.position.x < gameScene.size.width / 2 {
            self.xScale = self.xScale
        }
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        //Images 13 - 19 are attacking for zombies
        for i in 13...19 {
            imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)00\(i)"))
        }
        let animate = SKAction.repeatForever(SKAction.animate(with: imageArray, timePerFrame: spd * 0.01)) //0.2
        self.run(animate, withKey: "animationAttack")
    }
    
    func animateZombie() {
        
        if self.zombieAction == .death { return }
        
        self.removeAllActions()
        //Animation for the walking zombie
        if self.position.x < gameScene.size.width / 2 {
            self.xScale = CGFloat(initialScale * -1)
        } else if self.position.x < gameScene.size.width / 2 {
            self.xScale = self.xScale
        }
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        //Images 4 - 12 are walking for zombies
        for i in 4...12 {
            if i > 9 {
                imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)00\(i)"))
            } else if i <= 9 {
                imageArray.append(SKTexture(imageNamed: "\(imageName)\(zombieImage)000\(i)"))
            }
        }
        let animate = SKAction.repeatForever(SKAction.animate(with: imageArray, timePerFrame: spd * 0.005)) //0.1
        self.run(animate, withKey: "walk")
    }
    
    func pickRandomZombieType(normal: Double, fast: Double, big: Double) {
        let randNum = Double(arc4random_uniform(100))
        if randNum < normal {
            //Zombie is normal type
            zombieType = .normal
        } else if randNum < fast {
            //Zombie is fast type
            zombieType = .fast
        } else if randNum < big {
            //Zombie is nig type
            zombieType = .big
        }
        setZombieType()
    }
    
    func setZombieType() {
        //Animation for the walking zombie
        if self.position.x < gameScene.size.width / 2 {
            self.xScale *= -1
        } else if self.position.x < gameScene.size.width / 2 {
            self.xScale = xScale
        }
        
        switch zombieType {
        case .fast:
            //Set the image
            zombieImage = 5
            //size of the fast zombie
            self.xScale = 0.13
            self.yScale = 0.13
            initialScale = 0.13
            //Health of the fast zombie
            self.health = 1
            //Spd of the fast zombie
            self.spd = 7.5
            break
        case .normal:
            //Set the image
            zombieImage = Int(arc4random_uniform(2)) + 1
            //size of the normal zombie
            self.xScale = 0.13
            self.yScale = 0.13
            initialScale = 0.13
            //Health of the normal zombie
            self.health = 1
            //Spd of the normal zombie
            self.spd = 20.0
            break
        case .big:
            //Set the image
            let rand = arc4random_uniform(100)
            if rand < 25 {
                zombieImage = 4
            } else if rand < 100 {
                zombieImage = 3
            }
            //size of the big zombie
            self.xScale = 0.16
            self.yScale = 0.16
            initialScale = 0.16
            //Health of the big zombie
            self.health = 2
            //Spd of the big zombie
            self.spd = 25.0
            break
        }
    }
    
    /* End of GameScene Funtions */
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        
        //initializing the zombie
        self.name = "zombie"
        self.texture = SKTexture(imageNamed: "zombie50001")
        self.size = (self.texture?.size())!
        //self.zPosition = 5
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
