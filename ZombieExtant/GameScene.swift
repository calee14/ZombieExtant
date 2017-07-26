//
//  GameScene.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/22/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Connect Game Objects
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
    
    //Initialize vriables
    var fixedDelta: CFTimeInterval = 1.0/60.0 // 60 FPS
    var toBeDeleted: [SKSpriteNode] = [SKSpriteNode]()
    var contactTimer: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 1.4
    
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
        
        for turret in turretLayer.children as! [TopGun] {
            turret.gameScene = self
        }
        
        spawnWave(wave: 1)
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
                toBeDeleted.append(nodeA as! SKSpriteNode)
                toBeDeleted.append(nodeB as! Bullet)
                
                bullet.bulletHit = true
                return
            } else if nodeB.name == "zombie" && nodeA.name == "bullet" {
                let bullet = nodeA as! Bullet
                //To prevent multiple collisions
                if bullet.bulletHit != false { return }
                toBeDeleted.append(nodeB as! SKSpriteNode)
                toBeDeleted.append(nodeA as! Bullet)
                bullet.bulletHit = true
                return
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
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
    }
    
    func spawnWave(wave: Int) {
        let zombiesPerWave = wave * 100
        let zombiesPerSpawner = zombiesPerWave / 4
        if spawnTimer > 1 {
            //Top spawn
            addZombies(count: zombiesPerSpawner, spawner: topSpawn)
            //Right spawn
            addZombies(count: zombiesPerSpawner, spawner: rightSpawn)
            //Left spawn
            addZombies(count: zombiesPerSpawner, spawner: leftSpawn)
            //Bottom spawn
            addZombies(count: zombiesPerSpawner, spawner: bottomSpawn)
        }
        
        
    }
    
    func addZombies(count: Int, spawner: SKSpriteNode) {
        //Using the four spawners around the
        //if spawner.name == "topSpawn" || spawner.name == "rightSpawn" {
            var distanceCounter: CGFloat = 0
            var randPosition = CGPoint()
            for _ in 0...count {
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
                    let randX = -1 * (CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width)))) - distanceCounter
                    let randY = CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height)))
                    randPosition = CGPoint(x: randX, y: randY)
                } else if spawner.name == "bottomSpawn" {
                    //Create the bottomSpawn rand position
                    let randX = CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width)))
                    let randY = -1 * (CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height)))) - CGFloat(arc4random_uniform(50))
                    randPosition = CGPoint(x: randX, y: randY)
                }
                //Creates a number of zombies
                if distanceCounter > 50 { distanceCounter = 0 }
//                //Creates a random position
//                let randX = CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width))) //+ spawner.position.x
//                let randY = CGFloat(arc4random_uniform(UInt32(spawner.position.y + spawner.size.height)))// + spawner.position.y
//                let position = CGPoint(x: CGFloat(randX), y: CGFloat(randY))
                //Add a zombie to the scene
                let newZombie = Zombie()
                newZombie.gameScene = self
                self.zombieLayer.addChild(newZombie)
                newZombie.spd = Double(arc4random_uniform(4)) + 20.0
                newZombie.position = randPosition
                //Make the zombie move
                newZombie.moveToClosestTurret()
                //Update the distance Counter
                distanceCounter += 1
            }
    }
    func distanceTo(_ dist1: CGPoint, _ dist2: CGPoint) -> CGFloat {
        //Finds the distance between two positions
        let xDist = dist1.x - dist2.x
        let yDist = dist1.y - dist2.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
}
