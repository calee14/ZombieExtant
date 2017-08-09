//
//  MainMenu.swift
//  ZombieExtant
//
//  Created by Cappillen on 8/2/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenu: SKScene {
    
    var timer: CFTimeInterval = 0
    var fixedDelta: CFTimeInterval = 1.0/60.0 // 60FPS
    var zombieLayer: SKNode!
    var zombieZ = 6
    var spawnZombies = true
    /* Ui */
    var playButton: MSButtonNode!
    var title: SKNode!
    var settingsButton: MSButtonNode!
    
    override func didMove(to view: SKView) {
        //Set up scene here
        zombieLayer = self.childNode(withName: "zombieLayer")!
        
        //Connect the UI
        title = self.childNode(withName: "title")!
        settingsButton = self.childNode(withName: "settingsButton") as! MSButtonNode
        playButton = self.childNode(withName: "playButton") as! MSButtonNode
        playButton.selectedHandler = { [unowned self] in
            /* Play Button Handler*/
            
            //Move the settings button out of the scene
            let moveSettings = SKAction.move(to: CGPoint(x: self.size.width + self.settingsButton.size.width ,y: self.settingsButton.position.y), duration: 1.0)
            self.settingsButton.run(moveSettings)
            
            //Move the title out of the screen
            let moveTitle = SKAction.move(to: CGPoint(x: self.title.position.x, y: self.size.height + 100) , duration: 1.0)
            self.title.run(moveTitle)
            
            //Dissable the button
            self.playButton.isDisabled = true
            
            //Action to move the button
            let moveButton = SKAction.move(to: CGPoint(x: self.size.width / 2, y: -(self.playButton.size.height)) , duration: 0.5)
            self.playButton.run(moveButton)
            
            //Stop spawning the zombies
            self.spawnZombies = false
            
            //Apply the action to all of the zombies based on their position
            for zombie in self.zombieLayer.children as! [Zombie] {
                if zombie.zombieAction == .death { continue }
                
                //Stop the current action
                zombie.removeAllActions()
                
                //Get the move positon
                var moveToPosition = CGPoint()
                if zombie.position.y < self.size.height / 2 {
                    //If the zombie is on the bottom half of the scene
                    if zombie.position.x < self.size.width / 2 {
                        //Bottom Left
                        moveToPosition = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width / 2))), y: -zombie.size.height)
                        print(moveToPosition)
                        if zombie.position.x < self.size.width / 6 {
                            //If it is closer to the left wall than bottom
                            moveToPosition = CGPoint(x: -zombie.size.width, y: CGFloat(arc4random_uniform(UInt32(self.size.height / 2))))
                        }
                    } else if zombie.position.x > self.size.width / 2 {
                        //Bottom Right
                        moveToPosition = CGPoint(x: CGFloat(CGFloat(arc4random_uniform(UInt32(self.size.width / 2))) + (self.size.width / 2)) , y: -zombie.size.height)
                        print(moveToPosition)
                        if zombie.position.x > self.size.width - self.size.width / 6 {
                            //If it is closer to the right wall than bottom
                            moveToPosition = CGPoint(x: self.size.width + zombie.size.width, y: CGFloat(arc4random_uniform(UInt32(self.size.height / 2))))
                        }
                    }
                } else if zombie.position.y > self.size.height / 2 {
                    //If the zombie is on the top half of the scene
                    if zombie.position.x < self.size.width / 2 {
                        //Top Left
                        moveToPosition = CGPoint(x: CGFloat(arc4random_uniform(UInt32(self.size.width / 2))), y: self.size.height + zombie.size.height)
                        print(moveToPosition)
                        if zombie.position.x < self.size.width / 6 {
                            //If it is closer to the left then the top
                            moveToPosition = CGPoint(x: -zombie.size.width, y: CGFloat(arc4random_uniform(UInt32(self.size.height / 2))) + self.size.height / 2)
                        }
                    } else if zombie.position.x > self.size.width / 2 {
                        //Top Right
                        moveToPosition = CGPoint(x: CGFloat(CGFloat(arc4random_uniform(UInt32(self.size.width / 2))) + (self.size.width / 2)) , y: self.size.height + zombie.size.height)
                        print(moveToPosition)
                        if zombie.position.x > self.size.width - self.size.width / 6 {
                            //If it is closer to the right then the top
                            moveToPosition = CGPoint(x: self.size.width + zombie.size.width, y: CGFloat(arc4random_uniform(UInt32(self.size.height / 2))) + self.size.height / 2)
                        }
                    }
                }
                //Run the anitmation
                self.animateZombie(newNode: zombie)
                let moveTo = SKAction.move(to: moveToPosition, duration: TimeInterval(TimeInterval(arc4random_uniform(UInt32(0.5)) + 1)))
                zombie.run(moveTo, completion: {
                    zombie.removeFromParent()
                })
            }
            //Then change the scene
            let wait = SKAction.wait(forDuration: 2.0)
            let changeScene = SKAction.run({ [unowned self] in
                self.loadGame(fileName: "GameScene")
            })
            let seq = SKAction.sequence([wait, changeScene])
            self.run(seq)
        }
        
        //Start to spawn the zombies
        spawnZombies(num: 7)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Gets called when touch begins
        let touch = touches.first!
        let location = touch.location(in: self)
        let nodeAtPoint = atPoint(location)
        if nodeAtPoint.name == "zombie" {
            print("found the zombie")
            let zombie = nodeAtPoint as! Zombie
            if zombie.health == 1 {
                deathAnimation(newNode: zombie)
//            } else {
//                zombie.takeHitAnimation()
//                zombie.health -= 1
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        //Gets called every frame that is rendered
        
        if spawnZombies == false { return }
        
        if timer > 1.5 {
            if zombieLayer.children.count >= 150 { return }
            spawnZombies(num: 10)
            timer = 0
        }
        
        timer += fixedDelta
    }
    
    func spawnZombies(num: Int) {
        for _ in 0...num {
            let newZombie = Zombie()
            zombieLayer.addChild(newZombie)
            newZombie.physicsBody = nil
            
            let side = arc4random_uniform(100)
            var randPosition = CGPoint.zero
            if side < 0 {
                //Left
                randPosition = CGPoint(x: CGFloat(arc4random_uniform(25)) + self.size.width, y: CGFloat(arc4random_uniform(UInt32(self.size.height - 20)) + 10))
                newZombie.finalPos = CGPoint(x: -10, y: randPosition.y)
            } else if side < 100 {
                //Right
                randPosition = CGPoint(x: -1 * CGFloat(arc4random_uniform(25)), y: CGFloat(arc4random_uniform(UInt32(self.size.height - 20)) + 10))
                newZombie.finalPos = CGPoint(x: self.size.width + 10, y: randPosition.y)
            }
            
            //Give it the characteristics
            newZombie.position = randPosition
            let randomZombie = arc4random_uniform(100)
            if randomZombie < 70 {
                newZombie.zombieType = .normal
            } else if randomZombie < 85 {
                newZombie.zombieType = .fast
            } else if randomZombie < 100 {
                newZombie.zombieType = .big
            }
            setZombieType(newNode: newZombie)
            animateZombie(newNode: newZombie)
            
            newZombie.zPosition = CGFloat(zombieZ)
            zombieZ += 1
            if zombieZ >= 200 {
                zombieZ = 6
            }
            //random movement
            //Set game Scene to the zombie
            let movement = SKAction.move(to: newZombie.finalPos, duration: newZombie.spd + Double(arc4random_uniform(6)) - 3)
            newZombie.run(movement, completion: { 
                newZombie.removeFromParent()
            })
        }
    }
    
    func deathAnimation(newNode: Zombie) {
        
        if newNode.zombieAction == .death { return }
        
        //Keep track of what the zombie is doing
        newNode.zombieAction = .death
        
        //Animate death scene
        newNode.removeAllActions()
        newNode.physicsBody = nil
        
        //Animation for the walking zombie
        if self.position.x < self.size.width / 2 {
            newNode.xScale = CGFloat(newNode.initialScale * -1)
        } else if self.position.x < self.size.width / 2 {
            newNode.xScale = xScale
        }
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        
        //Images  20 , 29 - 32 are falling for zombies
        imageArray.append(SKTexture(imageNamed: "\(imageName)\(newNode.zombieImage)0020"))
        for i in 29...32 {
            imageArray.append(SKTexture(imageNamed: "\(imageName)\(newNode.zombieImage)00\(i)"))
        }
        let animate = SKAction.animate(with: imageArray, timePerFrame: newNode.spd * 0.01) //0.2
        let wait = SKAction.wait(forDuration: newNode.spd * 0.01 * Double(imageArray.count))
        let remove = SKAction.run({ [unowned newNode] in
            //self.gameScene.toBeDeleted.append(self)
            newNode.removeFromParent()
        })
        let seq = SKAction.sequence([animate, wait, remove])
        newNode.run(seq)
    }


    func setZombieType(newNode: Zombie) {
        //Animation for the walking zombie
        if newNode.position.x < self.size.width / 2 {
            newNode.xScale *= -1
        } else if newNode.position.x < self.size.width / 2 {
            newNode.xScale = xScale
        }
        
        switch newNode.zombieType {
        case .fast:
            //Set the image
            newNode.zombieImage = 5
            //size of the fast zombie
            newNode.xScale = 0.13
            newNode.yScale = 0.13
            newNode.initialScale = 0.13
            //Health of the fast zombie
            newNode.health = 1
            //Spd of the fast zombie
            newNode.spd = 7.5
            break
        case .normal:
            //Set the image
            newNode.zombieImage = Int(arc4random_uniform(2)) + 1
            //size of the normal zombie
            newNode.xScale = 0.13
            newNode.yScale = 0.13
            newNode.initialScale = 0.13
            //Health of the normal zombie
            newNode.health = 1
            //Spd of the normal zombie
            newNode.spd = 20.0
            break
        case .big:
            //Set the image
            newNode.zombieImage = 3
            //size of the big zombie
            newNode.xScale = 0.16
            newNode.yScale = 0.16
            newNode.initialScale = 0.16
            //Health of the big zombie
            newNode.health = 1
            //Spd of the big zombie
            newNode.spd = 25.0
            break
        }
    }
    
    func animateZombie(newNode: Zombie) {
        
        if newNode.zombieAction == .death { return }
        
        self.removeAllActions()
        //Animation for the walking zombie
        if newNode.position.x < self.size.width / 2 {
            newNode.xScale = newNode.xScale * -1
        } else if newNode.position.x > self.size.width / 2 {
            newNode.xScale = newNode.xScale
        }
        print("new node \(newNode.xScale)")
        //let rand = Int(arc4random_uniform(4)) + 1
        let imageName = "zombie"
        var imageArray: [SKTexture] = [SKTexture]()
        //Images 4 - 12 are walking for zombies
        for i in 4...12 {
            if i > 9 {
                imageArray.append(SKTexture(imageNamed: "\(imageName)\(newNode.zombieImage)00\(i)"))
            } else if i <= 9 {
                imageArray.append(SKTexture(imageNamed: "\(imageName)\(newNode.zombieImage)000\(i)"))
            }
        }
        let animate = SKAction.repeatForever(SKAction.animate(with: imageArray, timePerFrame: newNode.spd * 0.005)) //0.1
        newNode.run(animate, withKey: "walk")
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
