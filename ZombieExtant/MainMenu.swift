//
//  MainMenu.swift
//  ZombieExtant
//
//  Created by Cappillen on 8/2/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import Foundation
import SpriteKit

enum Location {
    case top, bottom, right, left
}
class MainMenu: SKScene {
    
    var timer: CFTimeInterval = 0
    var fixedDelta: CFTimeInterval = 1.0/60.0 // 60FPS
    override func didMove(to view: SKView) {
        //Set up scene here
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Gets called when touch begins
        let touch = touches.first!
        let location = touch.location(in: self)
        let nodeAtPoint = atPoint(location)
        if nodeAtPoint.name == "zombie" {
            print("found the zombie")
            nodeAtPoint.removeFromParent()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        //Gets called every frame that is rendered
        
        if timer > 1 {
            let randNumOfZombies = Int(arc4random_uniform(10))
            spawnZombies(atSector: .top, num: randNumOfZombies)
            spawnZombies(atSector: .left, num: randNumOfZombies)
            spawnZombies(atSector: .right, num: randNumOfZombies)
            spawnZombies(atSector: .bottom, num: randNumOfZombies)
            print("spawnZombie")
        }
        timer += fixedDelta
    }
    
    func spawnZombies(atSector: Location, num: Int) {
        switch atSector {
        case .top:
            break
        case .bottom:
            break
        case .right:
            break
        case .left:
            break
        }
        
    }
}
