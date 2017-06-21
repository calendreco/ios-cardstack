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

class LoadingOperation: Operation {
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
    
    let group: CardGroup
    
    init(group: CardGroup) {
        self.group = group
        super.init()
        queuePriority = .high
    }
    
    override func start() {
        super.start()
        
        if isCancelled {
            self.isFinished = true
        }
        
        isExecuting = true
        
        group.store.didFinishLoading = { [unowned self] in
            // TODO: Why are we losing our `self` here?
            self.isFinished = true
            self.isExecuting = false
        }
    }
}

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
    
    override var isAsynchronous: Bool {
        return true
    }
    
    var _cancelled: Bool = false
    var _finished: Bool = false
    var _executing: Bool = false
    
    override var isCancelled: Bool {
        get {
            return _cancelled
        }
        
        set {
            willChangeValue(forKey: "isCancelled")
            _cancelled = newValue
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    
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
    
    init(parent: UIViewController, from: @escaping () -> CardViewController?, to: @escaping () -> CardViewController?, animation: Animation, dependencies: [TransitionOperation] = [], action: ((TransitionOperation) -> Void)?, completion: ((Bool, CardViewController?) -> Void)?) {
//        precondition(to != from, "Cannot transition to the the existing UIViewController")
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
        super.start()
        
        if isCancelled {
            isFinished = true
        }
        
        isExecuting = true
        
        guard let to = toBlock(), let from = fromBlock() else {
            isCancelled = true
            isFinished = true
            isExecuting = false
            self.completion?(false, nil)
            return
        }
        
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
