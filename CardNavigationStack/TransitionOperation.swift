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
    let fromBlock: () -> CardViewController?
    let toBlock: () -> CardViewController?
    
    var from: CardViewController?
    var to: CardViewController?
    
    let animation: Animation
    var transition: AWPercentDrivenInteractiveTransition?
    var action: ((TransitionOperation) -> Void)?
    var completion: ((Bool, CardViewController?) -> Void)?
    
    private var _cancelled: Bool = false {
        willSet {
            willChangeValue(forKey: "isCancelled")
        }
        
        didSet {
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    override var isCancelled: Bool {
        return _cancelled
    }
    
    private var _executing: Bool = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished: Bool = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    init(parent: UIViewController, from: @escaping () -> CardViewController?, to: @escaping () -> CardViewController?, animation: Animation, dependencies: [TransitionOperation] = [], action: ((TransitionOperation) -> Void)?, completion: ((Bool, CardViewController?) -> Void)?) {
        self.parent = parent
        self.fromBlock = from
        self.toBlock = to
        self.animation = animation
        self.action = action
        self.completion = completion
        
        super.init()
        
        self.qualityOfService = .userInteractive
        // TODO: Completion block
        dependencies.forEach { addDependency($0) }
    }
    
    override func start() {
        
        if isCancelled {
            _finished = true
        }
        
        _executing = true
        
        guard let to = toBlock(), let from = fromBlock() else {
            _cancelled = true
            _finished = true
            _executing = false
            self.completion?(false, nil)
            return
        }
        
        precondition(to != from, "Cannot transition to the the existing UIViewController")
        
        self.to = to
        self.from = from
        
        action?(self)
        parent.addChildViewController(to)
        
        let context = TransitionContext(from: from, to: to)
        context.isInteractive = animation.interactive
        context.isAnimated = animation.animated
        
        context.completion = { [weak self] didComplete in
            guard let `self` = self else { return }
            
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
            self._finished = true
            self._executing = false
        }
        
        if animation.interactive, let transition = AWPercentDrivenInteractiveTransition(animator: animation.animator) {
            self.transition = transition
            transition.startInteractiveTransition(context)
        } else {
            animation.animator.animateTransition(using: context)
        }
    }
}
