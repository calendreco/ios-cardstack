//
//  Transition.swift
//  property-animator
//
//  Created by Stephen Silber on 4/13/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class PercentDrivenInteractiveTransition: NSObject, UIViewControllerInteractiveTransitioning {
    var duration: CGFloat {
        guard let context = transitionContext else { return 0 }
        return CGFloat(animator.transitionDuration(using: context))
    }
    
    private(set) var percentComplete: CGFloat = 0
    var completionSpeed: CGFloat = 1
    var completionCurve: UIViewAnimationCurve = .easeOut
    
    private var displayLink: CADisplayLink?
    private var transitionContext: UIViewControllerContextTransitioning?
    private var transition: TransitionContext?
    
    var animator: UIViewControllerAnimatedTransitioning
    
    init(animator: UIViewControllerAnimatedTransitioning) {
        self.animator = animator
        super.init()
    }
    
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        transitionContext.containerView.layer.speed = 0
        animator.animateTransition(using: transitionContext)
    }
    
    func update(_ percent: CGFloat) {
        percentComplete = min(1, max(0, percent))
        transitionContext?.containerView.layer.timeOffset = CFTimeInterval(percentComplete) * CFTimeInterval(duration)
        transitionContext?.updateInteractiveTransition(percentComplete)
    }
    
    func cancel() {
        transitionContext?.cancelInteractiveTransition()
        completeTransition()
    }
    
    func completeTransition() {
        displayLink = CADisplayLink(target: self, selector: #selector(tickAnimation))
        displayLink?.add(to: RunLoop.main, forMode: .commonModes)
    }
    
    func finish() {
        transitionContext?.finishInteractiveTransition()
        completeTransition()
    }
    
    @objc private func tickAnimation() {
        guard var timeOffset = transitionContext?.containerView.layer.timeOffset,
            let duration = displayLink?.duration
        else {
            print("Error")
            return
        }
        
        let tick = duration * Double(completionSpeed)
        timeOffset *= transitionContext?.transitionWasCancelled == true ? -tick : tick
        
        if timeOffset < 0 || timeOffset > TimeInterval(self.duration) {
            transitionFinished()
        } else {
            transitionContext?.containerView.layer.timeOffset = timeOffset
        }
    }
    
    func transitionFinished() {
        displayLink?.invalidate()
        
        guard let context = transitionContext else { return }
        
        if transitionContext?.transitionWasCancelled == false {
            let layer = context.containerView.layer
            layer.speed = Float(completionSpeed)
            let pausedTime = layer.timeOffset
            layer.timeOffset = 0
            layer.beginTime = 0
            let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
            layer.beginTime = timeSincePause
        }
    }
}

class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        _ = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        transitionContext.containerView.addSubview(to.view)

        to.view.alpha = 0.9
        to.view.transform = CGAffineTransform(translationX: 0, y: 10).concatenating(CGAffineTransform(scaleX: 0.9, y: 0.9))
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
            to.view.alpha = 1
            to.view.transform = .identity
        }) { (finished) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class TransitionContext: NSObject, UIViewControllerContextTransitioning {

    var completion: ((Bool) -> Void)?
    var targetTransform: CGAffineTransform = .identity
    var presentationStyle: UIModalPresentationStyle = .custom
    var transitionWasCancelled: Bool = false
    
    var isAnimated: Bool {
        return true
    }
    
    var isInteractive: Bool {
        return true
    }
    
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
