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
    // TODO: Probably not necessary to abstract this out
    struct Animation {
        let animator: UIViewControllerAnimatedTransitioning
        let interactive: Bool
        let animated: Bool
    }
    
    let parent: UIViewController
    let from: CardViewController
    let to: CardViewController
    let animation: Animation
    var transition: AWPercentDrivenInteractiveTransition?
    var action: (() -> Void)?
    var completion: ((Bool) -> Void)?
    
    override var isAsynchronous: Bool {
        return true
    }
    
    var _finished: Bool = false
    var _executing: Bool = false
    
    override var isFinished: Bool {
        get {
            return _finished
        }
        
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isExecuting: Bool {
        get {
            return _executing
        }
        
        set {
            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    init(parent: UIViewController, from: CardViewController, to: CardViewController, animation: Animation, dependencies: [TransitionOperation] = [], action: (() -> Void)?, completion: ((Bool) -> Void)?) {
        self.parent = parent
        self.from = from
        self.to = to
        self.animation = animation
        self.action = action
        self.completion = completion
        
        super.init()
        
        self.qualityOfService = .userInteractive
        // TODO: Completion block
        dependencies.forEach { addDependency($0) }
    }
    
    override func start() {
        super.start()
        
        if isCancelled {
            _finished = true
        }
        
        isExecuting = true
        
        action?()
        parent.addChildViewController(to)
        
        let context = TransitionContext(from: from, to: to)
        context.isInteractive = animation.interactive
        context.isAnimated = animation.animated
        
        context.completion = { [weak self] didComplete in
            guard let `self` = self else { return }
            
            if didComplete {
                self.from.view.removeFromSuperview()
                self.from.removeFromParentViewController()
                self.from.didMove(toParentViewController: nil)
                self.to.didMove(toParentViewController: self.parent)
            } else {
                self.to.view.removeFromSuperview()
                self.to.removeFromParentViewController()
            }
            
            self.completion?(didComplete)
            self.isFinished = true
            self.isExecuting = false
        }
        
        if animation.interactive, let transition = AWPercentDrivenInteractiveTransition(animator: animation.animator) {
            self.transition = transition
            transition.startInteractiveTransition(context)
        } else {
            animation.animator.animateTransition(using: context)
        }
    }
}
