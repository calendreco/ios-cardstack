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

struct LoadingCard { }

// Responsible for groups of cards
class CardGroup {
    
    fileprivate(set) var currentIndex: Int = 0
    
    var cards: [CardViewController]
    var loadingCard: LoadingCard?
    var title: String?
    
    var isLastCard: Bool {
        return currentIndex == cards.count - 1
    }
    
    var topCard: CardViewController? {
        return cards.last
    }
    
    var currentCard: CardViewController {
        let card = cards[currentIndex]
        if isLastCard {
            card.container.layer.cornerRadius = 0
        }
        return card
    }
    
    init(cards: [CardViewController], loadingCard: LoadingCard? = nil, title: String?) {
        self.cards = cards
        self.loadingCard = loadingCard
        self.title = title
    }
}

class CardStackViewController: UIViewController {
    
    enum SwipeDirection {
        case left
        case right
    }
    
    var topmostCard: CardViewController? {
        return groups.last?.currentCard
    }
    
    fileprivate(set) var groups: [CardGroup] = []
    private lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    
    fileprivate var transition: AWPercentDrivenInteractiveTransition?
    
    init(group: CardGroup) {
        super.init(nibName: nil, bundle: nil)
        
        // Add our cardGroup to the screen
        guard let card = group.topCard else {
            fatalError("CardGroup must have at least one card")
        }
        
        groups.append(group)
        addChildViewController(card)
        view.addSubview(card.view)
        card.didMove(toParentViewController: self)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    // Pushing a card onto the stack enforces that the existing 'top' card navigates to the .stack state
    func push(cardGroup: CardGroup, animated: Bool, completion: ((Bool) -> Void)?) {
        guard let currentGroup = groups.last, !isTransitioning else {
            return
        }
        
        isTransitioning = true
        let from = currentGroup.currentCard
        let to = cardGroup.currentCard
        
        groups.append(cardGroup)
        
        addChildViewController(to)
        
        let context = TransitionContext(from: from, to: to)
        context.isAnimated = animated
        context.isInteractive = false
        context.completion = { [weak self] didComplete in
            guard let `self` = self else { return }
            
            if didComplete {
                
                context.from.view.removeFromSuperview()
                context.from.removeFromParentViewController()
                context.from.didMove(toParentViewController: nil)
                context.to.didMove(toParentViewController: self)
//                self.bottomBar.text = String(describing: self.groups.count)
                
            } else {
                
                context.to.view.removeFromSuperview()
                context.to.removeFromParentViewController()
                
            }
            
            completion?(didComplete)
            self.isTransitioning = false
        }
        
        let animator = PushAnimator()
        animator.animateTransition(using: context)
    }
    
    func pop(animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        guard let currentGroup = groups.last else { return }
        if currentGroup.isLastCard == true {
            popGroup(animated: animated, interactive: interactive, completion: completion)
        } else {
            let to = currentGroup.cards[currentGroup.currentIndex + 1]
            let from = currentGroup.currentCard
            
            pop(from: from, to: to, animated: animated, interactive: interactive) { didComplete in
                if didComplete {
                    currentGroup.currentIndex += 1
                }
                completion?(didComplete)
            }
        }
    }
    
    func popGroup(animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        guard groups.count > 1, let currentGroup = groups.last else {
            fatalError("Cannot pop group")
        }
        
        guard !isTransitioning else { return }
        
        let to = groups[groups.count - 2].currentCard
        let from = currentGroup.currentCard
        
        pop(from: from, to: to, animated: animated, interactive: interactive) { [weak self] didComplete in
            guard let `self` = self else { return }
            self.groups.removeLast()
            completion?(didComplete)
        }
    }
    
    var isTransitioning: Bool = false
    private func pop(from: CardViewController, to: CardViewController, animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        isTransitioning = true
        addChildViewController(to)
        
        let context = TransitionContext(from: from, to: to)
        context.isInteractive = interactive
        context.completion = { [weak self] didComplete in
            guard let `self` = self else { return }
            
            if didComplete {
                
                from.view.removeFromSuperview()
                from.removeFromParentViewController()
                from.didMove(toParentViewController: nil)
                to.didMove(toParentViewController: self)
                
            } else {
                
                to.view.removeFromSuperview()
                to.removeFromParentViewController()
                
            }
            
            completion?(didComplete)
            self.transition = nil
            self.isTransitioning = false
        }
        
        
        
        if interactive {
            let animator = Animator()
            transition = AWPercentDrivenInteractiveTransition(animator: animator)
            transition?.startInteractiveTransition(context)
        } else {
            let animator = MultiPopAnimator()
            animator.animateTransition(using: context)
        }
        
    }
    
    var snapshot: UIView?
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: nil)
        let angle: CGFloat = translation.x > 0 ? .pi / 10 : -.pi / 10
        let percent = max(0, min(1, fabs(translation.x / (view.bounds.width / 2))))
        
        switch gesture.state {
        case .began:
            topmostCard?.updateSnapshot()
            
            guard gesture.isHorizontal(), let viewController = topmostCard, let snapshot = viewController.snapshot, !isTransitioning else {
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            
            // Add our snapshot to the viewport, hide our viewController
            view.addSubview(snapshot)
            snapshot.layer.zPosition = 50
//            snapshot.layer.anchorPoint = panGesture.location(in: snapshot)
            
            let center = CGPoint(x: viewController.container.center.x, y: viewController.container.frame.minY + (snapshot.frame.height / 2))
            snapshot.center = center
            
            self.snapshot = snapshot
            
            viewController.view.isHidden = true
            
            pop(animated: true, interactive: true, completion: nil)
            
        case .changed:
            transition?.update(percent)
            snapshot?.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .concatenating(CGAffineTransform.init(rotationAngle: angle * percent))
            
        case .cancelled, .ended:
            
            if percent > 0.25 {
                if let snapshot = snapshot {
                    let direction: SwipeDirection = translation.x > 0 ? .right : .left
                    throwSnapshot(snapshot, inDirection: direction, withTranslation: translation)
                }
                transition?.finish()
                
            } else {
                if let snapshot = snapshot {
                    resetSnapshot(snapshot)
                }
                transition?.cancel()
                
            }
            
        default: break
        }
    }
    
    private func finalPoint(for translation: CGPoint, inDirection direction: SwipeDirection) -> CGPoint {
        return CGPoint(x: translation.x * 3, y: translation.y * 3)
    }
    
    private func throwSnapshot(_ view: UIView, inDirection direction: SwipeDirection, withTranslation translation: CGPoint) {
        let finalX: CGFloat = direction == .left ? -view.bounds.width : view.bounds.width
//        let angle: CGFloat = direction == .left ? -(.pi / 5) : .pi / 5
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .allowUserInteraction, animations: {
            view.center.x += finalX
        }, completion: { finished in
            view.removeFromSuperview()
            print("Removing \(view) from superview: \(view.superview)")
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



