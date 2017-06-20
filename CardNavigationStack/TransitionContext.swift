//
//  TransitionContext.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/20/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

class TransitionContext: NSObject, UIViewControllerContextTransitioning {
    
    var completion: ((Bool) -> Void)?
    var targetTransform: CGAffineTransform = .identity
    var presentationStyle: UIModalPresentationStyle = .custom
    var transitionWasCancelled: Bool = false
    
    var isAnimated: Bool = true
    
    var isInteractive: Bool = true
    
    var containerView: UIView
    
    let from: UIViewController
    let to: UIViewController
    init(from: UIViewController, to: UIViewController) {
        precondition(from.view.superview != nil, "Cannot transition from a UIViewController that has no superview")
        self.containerView = from.view.superview!
        self.from = from
        self.to = to
        super.init()
    }
    
    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return nil
    }
    
    func finalFrame(for vc: UIViewController) -> CGRect {
        return from.view.bounds
    }
    
    func initialFrame(for vc: UIViewController) -> CGRect {
        return from.view.bounds
    }
    
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case UITransitionContextViewControllerKey.from:
            return from
        case UITransitionContextViewControllerKey.to:
            return to
        default: return nil
        }
    }
    
    func completeTransition(_ didComplete: Bool) {
        completion?(didComplete)
    }
    
    func pauseInteractiveTransition() {}
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func cancelInteractiveTransition() {
        transitionWasCancelled = true
    }
    func finishInteractiveTransition() {
        transitionWasCancelled = false
    }
}
