//
//  CardNavigationStack.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

// Transitions between CardStackControllers

class CardStackNavigationController: UINavigationController {
    
    enum SwipeDirection {
        case left
        case right
    }
    
    fileprivate lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    
    fileprivate let animator = Animator()
    fileprivate var interactionController: UIPercentDrivenInteractiveTransition?
    
    private var bottomBar: UILabel = {
        let view = UILabel()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        view.frame.size.height = 44
        view.text = "Next 3 hours"
        view.textColor = .white
        view.textAlignment = .center
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        bottomBar.layer.zPosition = 60
        isNavigationBarHidden = true
        delegate = self
        
        panGesture.delaysTouchesBegan = true
        panGesture.requiresExclusiveTouchType = false
        panGesture.delegate = self
        view.addSubview(bottomBar)
        view.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomBar.frame = CGRect(x: 0, y: view.bounds.height - 44, width: view.bounds.width, height: 44)
    }
    
    var snapshot: UIView!
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: nil)
        let angle: CGFloat = translation.x > 0 ? .pi / 10 : -.pi / 10
        let percent = max(0, min(1, fabs(translation.x / (view.bounds.width / 2))))
        
        guard let topmostCard = topViewController as? CardViewController else { return }
        
        switch gesture.state {
        case .began:
            print("#\(translation)")
            guard gesture.isHorizontal(), let snapshot = topmostCard.snapshot else {
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            
            // Add our snapshot to the viewport, hide our viewController
            view.addSubview(snapshot)
            self.snapshot = snapshot
            
            snapshot.layer.zPosition = 50
            
            let center = CGPoint(x: self.view.center.x, y: topmostCard.container.frame.minY + (snapshot.frame.height / 2))
            snapshot.center = center
            topmostCard.view.isHidden = true
            interactionController = UIPercentDrivenInteractiveTransition()
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            CATransaction.setCompletionBlock({
                self.bottomBar.text = String(describing: self.viewControllers.count)
                guard let topmostCard = self.topViewController as? CardViewController else { return }
                topmostCard.updateSnapshot()
            })
            popViewController(animated: true)
            CATransaction.commit()
            
        case .changed:
            print("Translate: \(translation) -- \(angle)")
            snapshot.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .concatenating(CGAffineTransform.init(rotationAngle: angle * percent))
            
            interactionController?.update(percent)
            
        case .cancelled, .ended:
            
            if percent > 0.45 {
                let direction: SwipeDirection = translation.x > 0 ? .right : .left
                throwSnapshot(snapshot, inDirection: direction, withTranslation: translation)
                interactionController?.finish()
            } else {
                resetSnapshot(snapshot)
                interactionController?.cancel()
            }
            
            interactionController = nil
            
        default: break
        }
    }
    
    private func finalPoint(for translation: CGPoint, inDirection direction: SwipeDirection) -> CGPoint {
        print("Translation: \(translation)")
        return CGPoint(x: translation.x * 3, y: translation.y * 3)
    }
    
    private func throwSnapshot(_ view: UIView, inDirection direction: SwipeDirection, withTranslation translation: CGPoint) {
        let finalX: CGFloat = direction == .left ? -view.bounds.width : view.bounds.width
//        let angle: CGFloat = direction == .left ? -(.pi / 5) : .pi / 5
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: .allowUserInteraction, animations: {
            view.center.x += finalX
        }, completion: { finished in
            view.removeFromSuperview()
        })
    }
    
    private func resetSnapshot(_ view: UIView) {
        // TODO: Fix the animation not working when a transition is active
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .allowUserInteraction, animations: {
            view.transform = .identity
        }, completion: { finished in
            view.removeFromSuperview()
            self.topViewController?.view.isHidden = false
        })
    }
    
}

extension CardStackNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        switch operation {
        case .push:
            return PushAnimator()
        case .pop:
            if interactionController == nil {
                return PopAnimator()
            } else {
                return InteractivePopAnimator()
            }
            
        case .none:
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return interactionController
        
    }
    
}

extension CardStackNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

