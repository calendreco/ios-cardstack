//
//  UIPanGestureRecognizer+Direction.swift
//  Live
//
//  Created by Stephen Silber on 4/17/17.
//  Copyright © 2017 Calendre. All rights reserved.
//

import Foundation
import UIKit

public enum PanDirection {
    case up
    case left
    case down
    case right
}

extension UIPanGestureRecognizer {
    func isHorizontal() -> Bool {
        let velocity = self.velocity(in: view)
        let absVelocity = CGPoint(x: abs(velocity.x), y: abs(velocity.y))
        
        return absVelocity.x > absVelocity.y
    }
    
    var currentDirection: PanDirection {
        let velocity = self.velocity(in: view)
        let absVelocity = CGPoint(x: abs(velocity.x), y: abs(velocity.y))
        
        if absVelocity.x > absVelocity.y {
            // Horizontal
            return velocity.x > 0 ? .right : .left
        } else {
            // Veritcal
            return velocity.y > 0 ? .down : .up
        }
    }
}
