//
//  TransitionOperation.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit
import AWPercentDrivenInteractiveTransition

class TransitionOperation: Operation {

    struct Animation {
        let animator: UIViewControllerAnimatedTransitioning
        let interactive: Bool
        let animated: Bool
    }
    
    let parent: UIViewController
    let fromBlock: () -> CardViewController?
    let toBlock: () -> CardViewController?
    
    var from: CardViewController?
    var to: CardViewController?
    
    let animation: Animation
    var transition: AWPercentDrivenInteractiveTransition?
    var action: ((TransitionOperation) -> Void)?
    var completion: ((Bool, CardViewController?) -> Void)?
    
    init(parent: UIViewController, from: @escaping () -> CardViewController?, to: @escaping () -> CardViewController?, animation: Animation, dependencies: [TransitionOperation] = [], action: ((TransitionOperation) -> Void)?, completion: ((Bool, CardViewController?) -> Void)?) {
        self.parent = parent
        self.fromBlock = from
        self.toBlock = to
        self.animation = animation
        self.action = action
        self.completion = completion
        
        super.init()
        
        self.qualityOfService = .userInteractive

        dependencies.forEach { addDependency($0) }
    }
    
    override func main() {
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async { [unowned self] in
            
            guard let to = self.toBlock(), let from = self.fromBlock() else {
                self.completion?(false, nil)
                semaphore.signal()
                return
            }

            precondition(to != from, "Cannot transition to the the existing UIViewController")
            
            self.to = to
            self.from = from
            
            self.action?(self)
            self.parent.addChildViewController(to)
            
            let context = TransitionContext(from: from, to: to)
            context.isInteractive = self.animation.interactive
            context.isAnimated = self.animation.animated
            
            context.completion = { [unowned self] didComplete in
                
                if didComplete {
                    from.view.removeFromSuperview()
                    from.removeFromParentViewController()
                    from.didMove(toParentViewController: nil)
                    to.didMove(toParentViewController: self.parent)
                } else {
                    to.view.removeFromSuperview()
                    to.removeFromParentViewController()
                }
                
                self.completion?(didComplete, to)
                semaphore.signal()
            }
            
            if self.animation.interactive, let transition = AWPercentDrivenInteractiveTransition(animator: self.animation.animator) {
                self.transition = transition
                transition.startInteractiveTransition(context)
            } else {
                self.animation.animator.animateTransition(using: context)
            }

        }
        
        semaphore.wait()
    }

}
