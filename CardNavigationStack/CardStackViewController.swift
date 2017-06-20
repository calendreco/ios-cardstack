//
//  CardStackViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/16/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit
import AWPercentDrivenInteractiveTransition

// TODO: Allow `initial -> ViewController` transition
// TODO: Allow `ViewController -> Empty` transition (dismiss last card)

class CardStackViewController: UIViewController {
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = DispatchQueue.main
        return queue
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        gesture.delegate = self
        return gesture
    }()
    
    private var groups: [CardGroup] = []
    private var currentCard: CardViewController
    private var snapshot: UIView?
    
    init(group: CardGroup) {
        currentCard = group.loadingCard
        super.init(nibName: nil, bundle: nil)
        currentCard = fetchNextCard(for: group, isSameGroup: false)
        
        // Add our initial card to the screen (not animated)
        groups.append(group)
        addChildViewController(currentCard)
        view.addSubview(currentCard.view)
        currentCard.didMove(toParentViewController: self)
        
        // Register for any loading callbacks if necessary
        checkForLoadingState(for: group)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Helpers
    
    private func fetchNextCard(for group: CardGroup, isSameGroup: Bool) -> CardViewController {
        if group.shouldShowLoadingCard {
            return group.loadingCard
        } else {
            return isSameGroup ? group.nextCard : group.currentCard
        }
    }
    
    private func checkForLoadingState(for group: CardGroup) {
        
        if group.store.isLoading {
            // TODO: Should we check that group.shouldShowLoadingCard instead?
            panGesture.isEnabled = currentCard != group.loadingCard
            
            // Add our loading operation to block the operation queue
            let operation = LoadingOperation(group: group)
            operation.completionBlock = { [weak self] in
                DispatchQueue.main.async {
                    self?.panGesture.isEnabled = true
                    self?.hideLoadingCard(for: group, animated: true, completion: nil)
                }
            }
            
            queue.addOperation(operation)
        }
    }
    
    // MARK: Card group transitions (push, pop, hide loading card)
    
    func push(group: CardGroup, animated: Bool, completion: ((Bool) -> Void)?) {
        
        let animator = PushAnimator()
        let from = currentCard
        let to = fetchNextCard(for: group, isSameGroup: false)
        
        from.navigate(to: .stack, animated: true)
        
        let action: () -> Void = { [weak self] in
            self?.groups.append(group) // TODO: Pull this out since it shouldn't affect anything
        }
        
        let animation = TransitionOperation.Animation(animator: animator, interactive: false, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: action, completion: { [weak self] didComplete in
            if didComplete {
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        
        queue.addOperation(operation)
        checkForLoadingState(for: group)
    }
    
    // Convenience method that will pop either card/group based on conditions
    func pop(animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        guard let currentGroup = groups.last else { return }
        
        if currentGroup.isLastCard == true {
            popGroup(animated: animated, interactive: interactive, completion: completion)
        } else {
            popCard(for: currentGroup, animated: animated, interactive: interactive, completion: completion)
        }
    }
    
    func popGroup(animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        guard groups.count > 1 else {
            return
//            fatalError("Cannot pop last group")
        }
        
        let nextGroup = groups[groups.count - 2]
        let to = fetchNextCard(for: nextGroup, isSameGroup: false)
        let from = currentCard
        let animator: UIViewControllerAnimatedTransitioning = interactive ? InteractivePopAnimator() : PopAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: interactive, animated: animated)
        
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil) { [weak self] didComplete in
            if didComplete {
                self?.groups.removeLast()
                self?.currentCard = to
            }
            
            completion?(didComplete)
        }
        
        queue.addOperation(operation)
    }
    
    func popCard(for group: CardGroup, animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        let to = fetchNextCard(for: group, isSameGroup: true)
        let from = currentCard
        
        let animator: UIViewControllerAnimatedTransitioning = InteractivePopAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: interactive, animated: animated)
        
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete in
            if didComplete {
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        
        queue.addOperation(operation)
        checkForLoadingState(for: group)

    }
    
    func undoPopCard(animated: Bool, completion: ((Bool) -> Void)?) {
        guard let to = groups.last?.previousCard else {
            // TODO: Handle this
            return
        }
        to.view.isHidden = false
        to.updateSnapshot()
        
        let from = currentCard
        let animator = UndoPopAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: false, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete in
            if didComplete {
                self?.currentCard = to
            }
            completion?(didComplete)
            
        })
        
        queue.addOperation(operation)
    }
    
    func hideLoadingCard(for group: CardGroup, animated: Bool, completion: ((Bool) -> Void)?) {
        let from = group.loadingCard
        let to = group.currentCard
        
        let animator = LoadingCardAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: false, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete in
            if didComplete {
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        queue.addOperation(operation)
    }
    
    // MARK: Pan gesture handling
    private var currentTransition: AWPercentDrivenInteractiveTransition?
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        
        let translation = panGesture.translation(in: nil)
        let angle: CGFloat = translation.x > 0 ? .pi / 10 : -.pi / 10
        let percent = max(0, min(1, fabs(translation.x / (view.bounds.width / 2))))
        
        switch gesture.state {
        case .began:
            
            // Check that we have a valid screenshot, that we aren't already transitioning, and that it's a horizontal pan
            guard gesture.isHorizontal(), let snapshot = currentCard.snapshot, queue.operations.count == 0 else {
                gesture.isEnabled = false
                gesture.isEnabled = true
                return
            }
            
            // Notify our topmost group that we're about to start swiping
            groups.last?.willBeginSwiping()
            
            // Add our snapshot to the viewport, hide our viewController
            view.addSubview(snapshot)
            
            // Position our snapshot to match the card's position
            let center = CGPoint(x: currentCard.container.center.x,
                                 y: currentCard.container.frame.minY + (snapshot.frame.height / 2))
            snapshot.center = center
            snapshot.layer.zPosition = 50
            
            self.snapshot = snapshot
            
            // Hide our current viewController since we're using the snapshot instead
            currentCard.view.isHidden = true
            
            // Begin a pop transition that's animated and interactive
            pop(animated: true, interactive: true, completion: nil)
//            currentTransition = (queue.operations.first as? TransitionOperation)?.transition
            
        case .changed:
            // Update our UIViewController transition's percentage
            (queue.operations.first as? TransitionOperation)?.transition?.update(percent)
            
            // Apply a transform for rotation/translation of the dragging card
            snapshot?.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
                .concatenating(CGAffineTransform.init(rotationAngle: angle * percent))
            
        case .ended:
            // TODO: Implement better handling with velocity/percentage complete
            guard let snapshot = self.snapshot else {
                return
            }
            
            // Check if we should finish throwing the card or snap it back to the center
            if percent > 0.25 {
                let direction: PanDirection = translation.x > 0 ? .right : .left
                groups.last?.didSwipe(card: currentCard, inDirection: direction)
                throwSnapshot(snapshot, inDirection: direction, withTranslation: translation)
                (queue.operations.first as? TransitionOperation)?.transition?.finish()
            } else {
                resetSnapshot(snapshot)
                (queue.operations.first as? TransitionOperation)?.transition?.cancel()
            }
            
            // TODO: Reset currentTransition to nil after finish
            
        default: break
        }
    }
    
    // MARK: Pan gesture helpers
    
    private func throwSnapshot(_ view: UIView, inDirection direction: PanDirection, withTranslation translation: CGPoint) {
        let finalX: CGFloat = direction == .left ? -view.bounds.width : view.bounds.width
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .allowUserInteraction, animations: {
            view.center.x += finalX
        }, completion: { finished in
            view.removeFromSuperview()
            view.transform = .identity
            view.isHidden = true
            self.snapshot = nil
        })
    }
    
    private func resetSnapshot(_ view: UIView) {
        // TODO: Fix the animation not working when a transition is active
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .allowUserInteraction, animations: {
            view.transform = .identity
        }, completion: { finished in
            view.removeFromSuperview()
            view.isHidden = true
            self.snapshot = nil
            self.currentCard.view.isHidden = false
        })
    }
    
}

extension CardStackViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
