//
//  CardStackNavigationController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit
import AWPercentDrivenInteractiveTransition

// Transitions between CardContainerViewControllers

class CardStackViewController: UIViewController {
    
    enum SwipeDirection {
        case left
        case right
    }
    
    var topmostCard: CardViewController? {
        return cards[currentIndex]
    }
    
    fileprivate var currentIndex: Int = 0
    fileprivate(set) var cards: [CardViewController] = []
    fileprivate lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    
    fileprivate var transition: AWPercentDrivenInteractiveTransition?
    
    private var resetSnapPoint: CGPoint = .zero
    
    private var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.frame.size.height = 44
        return view
    }()
    
    init(cardContainer: CardViewController) {
        cards.append(cardContainer)
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(cardContainer)
        view.addSubview(cardContainer.view)
        cardContainer.didMove(toParentViewController: self)
     }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        bottomBar.layer.zPosition = 25
        
        panGesture.delegate = self
        view.addSubview(bottomBar)
        view.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bottomBar.frame = CGRect(x: 0, y: view.bounds.height - 44, width: view.bounds.width, height: 44)
    }
    
    // Pushing a card onto the stack enforces that the existing 'top' card navigates to the .stack state
    func push(cardContainer: CardViewController, animated: Bool, completion: ((Bool) -> Void)?) {
        // TODO: transition between view controllers
        cards.append(cardContainer)
        print("Adding card to stack: \(cardContainer)")
    }
    
    func pop(animated: Bool, completion: ((Bool) -> Void)?) {
        // TODO: transition backwards
    }
    
    // Helper method to adjust the topmost card of a cardstack controller
    func navigate(to state: CardViewController.State, animated: Bool, completion: (() -> Void)?) {
        cards.last?.navigate(to: state, animated: animated, completion: completion)
    }
    
    private func transition(to: CardViewController, from: CardViewController, interactive: Bool, completion: ((Bool) -> Void)?) {
        
        addChildViewController(to)
        
        let context = TransitionContext(from: from, to: to)
        
        context.completion = { [weak self] didComplete in
            guard let `self` = self else { return }
            
            if didComplete {
                
                from.view.removeFromSuperview()
                from.removeFromParentViewController()
                from.didMove(toParentViewController: nil)
                to.didMove(toParentViewController: self)
                to.container.layer.shadowOpacity = 0.15
                
                self.currentIndex += 1
                
            } else {
                
                to.view.removeFromSuperview()
                to.removeFromParentViewController()
                
            }
            
            completion?(didComplete)
            self.transition = nil
        }
        
        if interactive {
            let animator = Animator()
            transition = AWPercentDrivenInteractiveTransition(animator: animator)
            transition?.startInteractiveTransition(context)
        }
        
    }
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: nil)
        let angle: CGFloat = translation.x > 0 ? .pi / 10 : -.pi / 10
        let percent = max(0, min(1, fabs(translation.x / (view.bounds.width / 2))))
        
        switch gesture.state {
        case .began:
            
            topmostCard?.updateSnapshot()
            
            guard gesture.isHorizontal(), let viewController = topmostCard, let snapshot = viewController.snapshot else {
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            
            // Add our snapshot to the viewport, hide our viewController
            view.addSubview(snapshot)
            snapshot.layer.zPosition = 50
            
            let center = CGPoint(x: viewController.container.center.x, y: viewController.container.frame.minY + (snapshot.frame.height / 2))
            snapshot.center = center
            resetSnapPoint = center
            
            viewController.view.isHidden = true
            
            if currentIndex + 1 < cards.count {
                 let nextViewController = cards[currentIndex + 1]
                transition(to: nextViewController,
                           from: viewController,
                           interactive: true,
                           completion: nil)
            }
            
        case .changed:
            
            topmostCard?.snapshot?.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .concatenating(CGAffineTransform.init(rotationAngle: angle * percent))
//                .concatenating(CGAffineTransform.init(scaleX: 1.05, y: 1.05))
            
            transition?.update(percent)
            
        case .cancelled, .ended:
            
            if percent > 0.15 {
                if let snapshot = topmostCard?.snapshot {
                    let direction: SwipeDirection = translation.x > 0 ? .right : .left
                    throwSnapshot(snapshot, inDirection: direction, withTranslation: translation)
                }
                transition?.finish()
            } else {
                if let snapshot = topmostCard?.snapshot {
                    resetSnapshot(snapshot)
                }
                transition?.cancel()
            }
            
        default: break
        }
    }
    
    private func throwSnapshot(_ view: UIView, inDirection direction: SwipeDirection, withTranslation translation: CGPoint) {
        let finalX: CGFloat = direction == .left ? -view.bounds.width : view.bounds.width
//        let angle: CGFloat = direction == .left ? -(.pi / 5) : .pi / 5
        UIView.animate(withDuration: 0.25, animations: {
            view.center.x = finalX
            view.center.y += 60
//            view.transform = CGAffineTransform(translationX: translation.x, y: translation.y).concatenating(CGAffineTransform(rotationAngle: angle))
        }, completion: { finished in
            view.removeFromSuperview()
            self.topmostCard?.view.isHidden = false
        })
    }
    
    private func resetSnapshot(_ view: UIView) {
        // TODO: Fix the animation not working when a transition is active
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .allowUserInteraction, animations: {
            view.transform = .identity
        }, completion: { finished in
            view.removeFromSuperview()
            self.topmostCard?.view.isHidden = false
        })
    }
    
}

extension CardStackViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

