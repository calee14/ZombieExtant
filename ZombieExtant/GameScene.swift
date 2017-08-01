//
//  GameScene.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/22/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import SpriteKit
import GameplayKit

//TODO: Add ammo
//TODO: Add collectables
//TODO: tweak difficulty
//TODO: change the difficulty for wave 2, 3
//
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Connect Game Objects
    //Guns
    var topGun: TopGun!
    var leftGun: TopGun!
    var rightGun: TopGun!
    //Layers
    var bulletLayer: SKNode!
    var turretLayer: SKNode!
    var zombieLayer: SKNode!
    //Spawners
    var topSpawn: SKSpriteNode!
    var rightSpawn: SKSpriteNode!
    var leftSpawn: SKSpriteNode!
    var bottomSpawn: SKSpriteNode!
    //UI objects
    var ammoLabel: SKLabelNode!
    var waveLabel: SKLabelNode!
    //Initialize variables
    var fixedDelta: CFTimeInterval = 1.0/60.0 // 60 FPS
    var toBeDeleted: [SKSpriteNode] = [SKSpriteNode]()
    var contactTimer: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var stagerTimer: UInt32 = 6
    var waveNum = 1
    var zombieCount = 0
    var zombieSpawned = 0
    var zombieOnGroundCount = 0
    var waveBegan = false
    var filterZombiesPerWave = 24
    var zombiesInTheWave = 0
    
    override func didMove(to view: SKView) {
        //Set up scene here
        
        physicsWorld.contactDelegate = self
        
        //Connect the game objects
        bulletLayer = self.childNode(withName: "bulletLayer")!
        turretLayer = self.childNode(withName: "turretLayer")!
        zombieLayer = self.childNode(withName: "zombieLayer")!
        
        //Connect the spawners
        topSpawn = self.childNode(withName: "topSpawn") as! SKSpriteNode
        rightSpawn = self.childNode(withName: "rightSpawn") as! SKSpriteNode
        leftSpawn = self.childNode(withName: "leftSpawn") as! SKSpriteNode
        bottomSpawn = self.childNode(withName: "bottomSpawn") as! SKSpriteNode
        
        //Connect the turrets
        topGun = self.childNode(withName: "//topGun") as! TopGun
        leftGun = self.childNode(withName: "//leftGun") as! TopGun
        rightGun = self.childNode(withName: "//rightGun") as! TopGun
        
        //Connect the UI objects
        waveLabel = self.childNode(withName: "waveLabel") as! SKLabelNode
        waveLabel.text = "Wave: \(waveNum)"
        
        //Connect the turrets to the gameScene
        for turret in turretLayer.children as! [TopGun] {
            turret.gameScene = self
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        
        //Creating an array to store our data
        var arrayDist: [(turret: Int, dist: CGFloat)] = []
        
        if turretLayer.children.count == 0 { return }
        for turret in 0...turretLayer.children.count - 1 {
            //Gets the distance of all the turrets from the tap
            let distance: CGFloat = distanceTo(location, turretLayer.children[turret].position)
            arrayDist.append((turret: turret, dist: distance))
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
        //Turns the turret
        let turretChildren = turretLayer.children as! [TopGun]
        turretChildren[minimum].turnGun(destPoint: location)
        turretChildren[minimum].fireBullet()
        print(minimum)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "zombie" || nodeB.name == "zombie" {
            if nodeA.name == "zombie" && nodeB.name == "zombie" { return }
            
            //If the zombie collided with the base
            if nodeA.name == "zombie" && nodeB.physicsBody?.contactTestBitMask == 3 {
                //if the zombies collide with the gun
                nodeA.removeAllActions()
                let zombie = nodeA as! Zombie
                zombie.attack()
            } else if nodeB.name == "zombie" && nodeA.physicsBody?.contactTestBitMask == 3 {
                nodeB.removeAllActions()
                let zombie = nodeB as! Zombie
                zombie.attack()
            }
            
            //If the bullet collides with the bullet
            if nodeA.name == "zombie" && nodeB.name == "bullet" {
                let bullet = nodeB as! Bullet
                //To prevent multiple collisions
                if bullet.bulletHit != false { return }
                
                //Check the zombie if it has no more health
                let zombie = nodeA as! Zombie
                if zombie.health == 1 {
                    //zombie.deathAnimation()
                    toBeDeleted.append(nodeA as! SKSpriteNode)
                    
                    //Update zombie count
                    zombieCount -= 1
                    zombieOnGroundCount -= 1
                } else {
                    zombie.health -= 1
                }
                toBeDeleted.append(nodeB as! Bullet)
                
                //Disable the bullet
                bullet.bulletHit = true
                return
            } else if nodeB.name == "zombie" && nodeA.name == "bullet" {
                let bullet = nodeA as! Bullet
                //To prevent multiple collisions
                if bullet.bulletHit != false { return }
                
                //Check the zombie if it has no more health
                let zombie = nodeB as! Zombie
                if zombie.health == 1 {
                    //zombie.deathAnimation()
                    toBeDeleted.append(nodeB as! SKSpriteNode)
                    
                    //Update zombie count
                    zombieCount -= 1
                    zombieOnGroundCount -= 1
                } else {
                    zombie.health -= 1
                }
                toBeDeleted.append(nodeA as! Bullet)
                
                //Disable the bullet
                bullet.bulletHit = true
                return
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        print("zombie count = \(zombieCount)")
        //Manages the waves
        waveManager()
        
        //removes the objects that need to be removed
        for object in toBeDeleted {
            object.removeFromParent()
        }
        //Important for removing instances of the nodes because the array stores it in memory
        toBeDeleted = [SKSpriteNode]()
        
        for bullet in bulletLayer.children as! [Bullet] {
            print(bulletLayer.children)
            if bullet.position.x > 600 || bullet.position.x < -50 {
                bullet.removeFromParent()
                print("remove it")
            } else if bullet.position.y > 330 || bullet.position.y < -10 {
                bullet.removeFromParent()
                print("remove it ")
            }
            print("remove")
        }
        
        //Update timers
        //spawnTimer += fixedDelta
    }
    
    func waveManager() {
        if waveBegan == false {
            
            //Gets the value of the num of zombies in the wave
            //Important for spawning the entire wave
            zombieCount = waveNum * filterZombiesPerWave
            if waveNum >= 5 {
                if filterZombiesPerWave >= 28 {
                    filterZombiesPerWave = 28
                } else {
                    filterZombiesPerWave += 2
                }
            }
            //Wave spawning editor
            if waveNum < 5 {
                //Number of spawns editor
                zombieCount = waveNum * filterZombiesPerWave
                zombiesInTheWave = waveNum * filterZombiesPerWave
            } else if waveNum >= 5 {
                //96 is four 24 * num of spawners which is 4
                //4 is for every level after 5
                //The mulitplier will need to be divisible by 4 and the result must be the filterZombiePerWave
                zombieCount = (waveNum - 4) * filterZombiesPerWave * 4 // 96
                zombiesInTheWave = (waveNum - 4) * filterZombiesPerWave * 4 // 96
            }
            waveBegan = true
        }
        
        if zombieSpawned < zombiesInTheWave {
            print("zombies \(zombieSpawned) count \(zombieOnGroundCount)")
            //Run code to add more zombies
            //Check if it is the right time to spawn zombies
            if zombieOnGroundCount <= zombieSpawned / 4 {
                spawnWave(wave: waveNum)
            }

        } else if zombieCount <= 0 && zombieLayer.children.count == 0 {
            //if we killed all the zombies start a new wave
            //make a new wave
            //Update the zombie spawned
            //let wait = SKAction.wait(forDuration: 5)
            zombieSpawned = 0
            zombieOnGroundCount = 0
            waveBegan = false
            //Start a new wave
            waveNum += 1
            waveLabel.text = "Wave: \(waveNum)"
            spawnWave(wave: waveNum)
            print("wave count = \(waveNum)")
        }
    }
    
    func spawnWave(wave: Int) {
        //Get the total num zombies for the wave
        
        var zombiesPerSpawner = Int(zombiesInTheWave / 4)
        if wave < 6 {
            zombiesPerSpawner = 24 / 4
        }
        //Filter the num of zombies per spawner
        if zombiesPerSpawner > filterZombiesPerWave {
            zombiesPerSpawner = filterZombiesPerWave
        }
        //Update the spawned num of zombies
        zombieSpawned += zombiesPerSpawner * 4
        zombieOnGroundCount += zombiesPerSpawner * 4
        
        //Top spawn
        addZombies(count: zombiesPerSpawner, spawner: topSpawn)
        //Right spawn
        addZombies(count: zombiesPerSpawner, spawner: rightSpawn)
        //Left spawn
        addZombies(count: zombiesPerSpawner, spawner: leftSpawn)
        //Bottom spawn
        addZombies(count: zombiesPerSpawner, spawner: bottomSpawn)
        
    }
    
    func addZombies(count: Int, spawner: SKSpriteNode) {
        //Using the four spawners around the map
        //Create an offset
        var randPosition = CGPoint()
        for _ in 1...count {
            let distanceCounter: CGFloat = CGFloat(arc4random_uniform(200))
            print("rand num = \(distanceCounter)")
            //if spawnTimer > 0.2 {
            if spawner.name == "topSpawn" {
                //Create the topSpawn rand position
                let randX = CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width)))
                let randY = CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height))) + spawner.position.y
                randPosition = CGPoint(x: randX, y: randY)
            } else if spawner.name == "rightSpawn" {
                //Create the right rand position
                let randX = CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width))) + spawner.position.x + distanceCounter
                let randY = CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height)))
                randPosition = CGPoint(x: randX, y: randY)
            } else if spawner.name == "leftSpawn" {
                //Create the leftSpawn rand position
                let randX = -1 * (CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width)))) - distanceCounter / 4
                let randY = CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height))) + distanceCounter / 4
                randPosition = CGPoint(x: randX, y: randY)
            } else if spawner.name == "bottomSpawn" {
                //Create the bottomSpawn rand position
                let randX = CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width))) + distanceCounter / 4
                let randY = -1 * (CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height)))) - CGFloat(distanceCounter)
                randPosition = CGPoint(x: randX, y: randY)
            }
            //Creates a number of zombies
            //Add a zombie to the scene
            let newZombie = Zombie()
            newZombie.gameScene = self
            
            //Level editor
            
            if waveNum == 2 {
                //let rand = arc4random_uniform(100)
                newZombie.zombieType = .fast
            } else if waveNum == 3 {
                //Big zombies
                newZombie.zombieType = .big
            } else {
                newZombie.spd = 20.0 //Double(arc4random_uniform(4)) + 20.0
            }
            
            newZombie.setZombieType()
            
            //End of Level editor
            newZombie.position = randPosition
            //Make the zombie move
            newZombie.moveToClosestTurret()
            //Update the distance Counter
            let wait = SKAction.wait(forDuration: TimeInterval(arc4random_uniform(stagerTimer)))
            let addZombie = SKAction.run({ [unowned self] in
                self.zombieLayer.addChild(newZombie)
            })
            let seq = SKAction.sequence([wait, addZombie])
            self.run(seq)
        }
        //}
    }
    
    func distanceTo(_ dist1: CGPoint, _ dist2: CGPoint) -> CGFloat {
        //Finds the distance between two positions
        let xDist = dist1.x - dist2.x
        let yDist = dist1.y - dist2.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
}
