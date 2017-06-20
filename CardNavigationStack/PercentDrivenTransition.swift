//
//  PercentDrivenTransition.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/20/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

// Swift translation of AWPercentDrivenTransition, but has a couple of bugs :(

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
