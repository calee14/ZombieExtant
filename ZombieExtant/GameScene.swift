//
//  GameScene.swift
//  ZombieExtant
//
//  Created by Cappillen on 7/22/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import SpriteKit
import GameplayKit

enum ZombieGameState {
    case wave, stop, destroy
}

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
    var baseLayer: SKNode!
    //Spawners
    var topSpawn: SKSpriteNode!
    var rightSpawn: SKSpriteNode!
    var leftSpawn: SKSpriteNode!
    var bottomSpawn: SKSpriteNode!
    //Smoke emmiters
    var topGunSmoke: SKEmitterNode!
    var leftGunSmoke: SKEmitterNode!
    var rightGunSmoke: SKEmitterNode!
    //UI objects
    var ammoLabel: SKLabelNode!
    var waveLabel: SKLabelNode!
    var restartScene: SKNode!
    //Initialize variables
    var fixedDelta: CFTimeInterval = 1.0/60.0 // 60 FPS
    var toBeDeleted: [SKSpriteNode] = [SKSpriteNode]()
    var contactTimer: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    var stagerTimer: UInt32 = 6
    var turretsDisabled = true
    //Wave Controller
    var waveNum = 1
    var zombieCount = 0
    var zombieSpawned = 0
    var zombieOnGroundCount = 0
    var waveBegan = false
    var filterZombiesPerWave = 18
    var zombiesInTheWave = 0
    var zombieZ = 0
    var fastBigZombies = 97
    var zombiePause: ZombieGameState = .wave
    var normalZombies = 94 {
        didSet {
            fastBigZombies = 100 - ((100 - normalZombies) / 2)
        }
    }
    override func didMove(to view: SKView) {
        //Set up scene here
        
        physicsWorld.contactDelegate = self
        
        //Connect the game objects
        bulletLayer = self.childNode(withName: "bulletLayer")!
        turretLayer = self.childNode(withName: "turretLayer")!
        zombieLayer = self.childNode(withName: "zombieLayer")!
        baseLayer = self.childNode(withName: "baseLayer")!
        restartScene = self.childNode(withName: "backgroundLayer")!
        
        //Connect the spawners
        topSpawn = self.childNode(withName: "topSpawn") as! SKSpriteNode
        rightSpawn = self.childNode(withName: "rightSpawn") as! SKSpriteNode
        leftSpawn = self.childNode(withName: "leftSpawn") as! SKSpriteNode
        bottomSpawn = self.childNode(withName: "bottomSpawn") as! SKSpriteNode
        
        //Connect the turrets
        topGun = self.childNode(withName: "//topGun") as! TopGun
        topGun.isHidden = true
        leftGun = self.childNode(withName: "//leftGun") as! TopGun
        leftGun.isHidden = true
        rightGun = self.childNode(withName: "//rightGun") as! TopGun
        rightGun.isHidden = true
        
        //Connect the Emmiter Nodes
        topGunSmoke = self.childNode(withName: "topGunSmoke") as! SKEmitterNode
        leftGunSmoke = self.childNode(withName: "leftGunSmoke") as! SKEmitterNode
        rightGunSmoke = self.childNode(withName: "rightGunSmoke") as! SKEmitterNode
        
        //Connect the UI objects
        waveLabel = self.childNode(withName: "waveLabel") as! SKLabelNode
        waveLabel.text = "Wave: \(waveNum)"
        
        //Hide the bases for animation
        for base in baseLayer.children as! [SKSpriteNode] {
            base.isHidden = true
        }
        
        //Connect the turrets to the gameScene
        for turret in turretLayer.children as! [TopGun] {
            turret.gameScene = self
        }
        
        /* Slam Animation */
        var delay = 0.0
        //Play the animation
        for turret in turretLayer.children as! [TopGun] {
            turret.xScale = 1.5
            turret.yScale = 1.5
            let scaleDownX = SKAction.scaleX(to: 0.4, duration: 0.2)
            let scaleDownY = SKAction.scaleY(to: 0.4, duration: 0.2)
            let scaleDown = SKAction.run({
                turret.isHidden = false
                turret.run(scaleDownX)
                turret.run(scaleDownY)
            })
            let wait = SKAction.wait(forDuration: delay)
            let seq = SKAction.sequence([wait, scaleDown])
            turret.run(seq)
            delay += 0.5
        }
        
        var baseDelay = 0.0
        //Play the animation
        for base in baseLayer.children as! [SKSpriteNode] {
            base.xScale = 1.5
            base.yScale = 1.5
            let scaleDownX = SKAction.scaleX(to: 0.4, duration: 0.3)
            let scaleDownY = SKAction.scaleY(to: 0.4, duration: 0.3)
            let scaleDown = SKAction.run({
                base.isHidden = false
                base.run(scaleDownX)
                base.run(scaleDownY)
            })
            let wait = SKAction.wait(forDuration: baseDelay)
            let seq = SKAction.sequence([wait, scaleDown])
            base.run(seq)
            baseDelay += 0.5
        }
        
        let wait = SKAction.wait(forDuration: 1.8)
        let reenable = SKAction.run({
            self.turretsDisabled = false
        })
        let seq = SKAction.sequence([wait, reenable])
        self.run(seq)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        
        if turretsDisabled == true { return }
        if turretLayer.children.count == 0 { return }
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
        if turretChildren[minimum].health <= 0 { return }
        turretChildren[minimum].turnGun(destPoint: location)
        turretChildren[minimum].fireBullet()
        print(minimum)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA: SKPhysicsBody = contact.bodyA
        print("contactA = \(contactA)")
        let contactB: SKPhysicsBody = contact.bodyB
        print("contactB = \(contactB)")
        
        //Does a check for node A if it is dead
        let contactNodeA = contactA.node
        var nodeA: SKNode!
        if contactNodeA != nil {
            nodeA = contactNodeA
            print("nodeA = \(nodeA)")
        } else {
            return
        }
        
        //Does a check for node B if it is dead
        let contactNodeB = contactB.node
        var nodeB: SKNode!
        if contactNodeB != nil {
            nodeB = contactNodeB
            print("nodeB = \(nodeB)")
        } else {
            return
        }
        
        if nodeA.name == "zombie" || nodeB.name == "zombie" {
            if nodeA.name == "zombie" && nodeB.name == "zombie" { return }
            
            //If the zombie collided with the base
            if nodeA.name == "zombie" && nodeB.physicsBody?.contactTestBitMask == 3 {
                //if the zombies collide with the gun
                nodeA.removeAllActions()
                let zombie = nodeA as! Zombie
                zombie.attack()
                return
            } else if nodeB.name == "zombie" && nodeA.physicsBody?.contactTestBitMask == 3 {
                nodeB.removeAllActions()
                let zombie = nodeB as! Zombie
                zombie.attack()
                return
            }
            
            //If the bullet collides with the zombie
            if nodeA.name == "zombie" && nodeB.name == "bullet" {
                let bullet = nodeB as! Bullet
                //To prevent multiple collisions
                if bullet.bulletHit != false { return }
                
                //Check the zombie if it has no more health
                let zombie = nodeA as! Zombie
                if zombie.health == 1 {
                    //removePhysicsBody.append(zombie)
                    zombie.deathAnimation()
                    //toBeDeleted.append(nodeA as! SKSpriteNode)
                    
                    //Update zombie count
                    zombieCount -= 1
                    zombieOnGroundCount -= 1
                } else {
                    zombie.health -= 1
                    zombie.takeHitAnimation()
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
                    //removePhysicsBody.append(zombie)
                    zombie.deathAnimation()
                    //toBeDeleted.append(nodeB as! SKSpriteNode)
                    
                    //Update zombie count
                    zombieCount -= 1
                    zombieOnGroundCount -= 1
                } else {
                    zombie.health -= 1
                    zombie.takeHitAnimation()
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
        
        if turretsDisabled == true { return }
        
        //Call the restart scene only once
        if turretLayer.children.count == 0 {
            if zombiePause == .stop { return }
            //Set the enum and from now on it will not be called again
            zombiePause = .stop
            if turretLayer.children.count == 0 {
                stopAllZombies()
            }
        }
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
            if bullet.position.x > 578 || bullet.position.x < -10 {
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
    
    func stopAllZombies() {
        // Restart scene here
        //Should start deleting after restart sreen pops up
        var waitTime = 1.0
        for zombie in zombieLayer.children as! [Zombie] {
            zombie.removeAllActions()
            let wait = SKAction.wait(forDuration: waitTime)
            let removeZombie = SKAction.run({
                zombie.removeFromParent()
            })
            let seq = SKAction.sequence([wait, removeZombie])
            run(seq)
            waitTime += 0.05
        }
        
        let moveTo = SKAction.move(to: CGPoint.zero, duration: 0.7)
        restartScene.run(moveTo)
        
        /* Connect the buttons from the restart scene */
        let restartButton = restartScene.childNode(withName: "restartButton") as! MSButtonNode
        restartButton.selectedHandler = {
            let moveMenu = SKAction.run({ [unowned self] in
                self.moveRestartSceneOutOfScene()
            })
            let loadGame = SKAction.run({ [unowned self] in
                self.loadGame(fileName: "GameScene")
            })
            let wait = SKAction.wait(forDuration: 1.0)
            let seq = SKAction.sequence([moveMenu, wait, loadGame])
            self.run(seq)
        }
        let mainMenuButton = restartScene.childNode(withName: "mainMenuButton") as! MSButtonNode
        mainMenuButton.selectedHandler = {
            let moveMenu = SKAction.run({ [unowned self] in
                self.moveRestartSceneOutOfScene()
            })
            let loadMenu = SKAction.run({ [unowned self] in
                self.loadGame(fileName: "MainMenu")
            })
            let wait = SKAction.wait(forDuration: 0.7)
            let seq = SKAction.sequence([moveMenu, wait, loadMenu])
            self.run(seq)
        }
        
    }
    
    func moveRestartSceneOutOfScene() {
        //Move the menu out of the scene
        let moveTo = SKAction.move(to: CGPoint(x: 0, y: 520), duration: 0.5)
        restartScene.run(moveTo)
        //Remove all zombies
        if zombieLayer.children.count >= 1 {
            for zombie in zombieLayer.children {
                zombie.removeFromParent()
            }
        }
        //Disable buttons
        let mainMenuButton = restartScene.childNode(withName: "mainMenuButton") as! MSButtonNode
        let restartButton = restartScene.childNode(withName: "restartButton") as! MSButtonNode
        let settingsButton = restartScene.childNode(withName: "settingsButton") as! MSButtonNode
        mainMenuButton.isDisabled = true
        restartButton.isDisabled = true
        settingsButton.isDisabled = true
    }
    
    func addRestartSceneConstraints() {
        //Add constraints for the restart scene ui here
    }
    
    func waveManager() {
        if waveBegan == false {
            
            //Gets the value of the num of zombies in the wave
            //Important for spawning the entire wave
            zombieCount = waveNum * filterZombiesPerWave
            
            //Wave spawning editor
            if waveNum < 6 {
                //Number of spawns editor
                zombieCount = waveNum * 24
                zombiesInTheWave = waveNum * 24
            } else if waveNum >= 6 {
                //96 is four 24 * num of spawners which is 4
                //4 is for every level after 5
                //The mulitplier will need to be divisible by 4 and the result must be the filterZombiePerWave
                zombieCount = (waveNum - 4) * filterZombiesPerWave * 4 // 96
                zombiesInTheWave = (waveNum - 4) * filterZombiesPerWave * 4 // 96
                
                //Filter the num of zombies coming in
                if waveNum > 11 {
                    zombieCount = (11 - 4) * filterZombiesPerWave * 4 // 96
                    zombiesInTheWave = (11 - 4) * filterZombiesPerWave * 4 // 96
                }
            }
            zombieZ = zombiesInTheWave + 6
            waveBegan = true
        }
        
        //if waveBegan == false { return }
        
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
            //update our filter zombies
            //896
            //1008
            if waveNum > 6 {
                //get more zombies with abilities
                if normalZombies > 60 {
                    normalZombies -= 2
                }
                print("normal Zombies = \(normalZombies)")
                print("fastBig Zombies = \(fastBigZombies)")
                //update the filter zombies per wave
                if filterZombiesPerWave >= 26 {
                    filterZombiesPerWave = 26
                } else {
                    filterZombiesPerWave += 2
                }
                if waveNum > 11 {
                    //Start adding more zombies again
                    if filterZombiesPerWave >= 28 {
                        filterZombiesPerWave = 28
                    } else {
                        filterZombiesPerWave += 2
                    }
                }
            }
        }
    }
    
    func spawnWave(wave: Int) {
        //Get the total num zombies for the wave
        
        if waveBegan == false {
            return
        }
        var zombiesPerSpawner = Int(zombiesInTheWave / 4)
        
        if wave < 6 {
            zombiesPerSpawner = 24 / 4
        }
        
        //Filter the num of zombies per spawner
        if zombiesPerSpawner >= filterZombiesPerWave {
            zombiesPerSpawner = filterZombiesPerWave
        }
        print("filter zombies \(filterZombiesPerWave)")
        print("zombies per spawner = \(zombiesPerSpawner)")
        //Update the spawned num of zombies
        zombieSpawned += zombiesPerSpawner * 4 // zombiePerSpawner is the error != filter
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
                let randX = -1 * (CGFloat(arc4random_uniform(UInt32(spawner.position.x + spawner.size.width + 100)))) - distanceCounter / 4
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
            newZombie.zPosition = CGFloat(zombieZ)
            zombieZ -= 1
            
            //Level editor
            if waveNum == 1 {
                newZombie.zombieType = .normal
            } else if waveNum == 2 {
                //let rand = arc4random_uniform(100)
                newZombie.zombieType = .fast
            } else if waveNum == 3 {
                //Big zombies
                newZombie.zombieType = .big
            } else if waveNum <= 5 {
                newZombie.pickRandomZombieType(normal: 90, fast: 95, big: 100)
            } else if waveNum >= 6 {
                newZombie.pickRandomZombieType(normal: Double(normalZombies), fast: Double(fastBigZombies), big: 100)
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
    
    func loadGame(fileName: String) {
        //Grab reference to our sprite kit view
        
        //1) grab reference to our spriteKit view
        guard let skView = self.view as SKView! else {
            print("could not get SKView")
            return
        }
        //2) Load game scene
        guard let scene = SKScene(fileNamed: fileName) else {
            print("Could not make GameScene, check the name is spelled correctly")
            return
        }
        //Enusre the aspect mode is correct
        scene.scaleMode = .aspectFit
        
        //Show Debug
        skView.showsPhysics = true
        skView.showsDrawCount = true
        skView.showsFPS = true
        
        //4)
        skView.presentScene(scene)
        
    }
}
