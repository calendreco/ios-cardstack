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
import pop

// TODO: Allow `initial -> ViewController` transition
// TODO: Allow `ViewController -> Empty` transition (dismiss last card)

protocol CardStackViewDelegate: class {
    func didSwipe(card: CardViewController, inDirection direction: PanDirection)
}

class CardStackViewController: UIViewController {
    weak var delegate: CardStackViewDelegate?
    
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        gesture.delegate = self
        return gesture
    }()
    
    private var groups: [CardGroup] = []
    private var currentCard: CardViewController
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
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
            
            group.store.didFinishLoading = { [weak self] in
                DispatchQueue.main.async {
                    self?.panGesture.isEnabled = true
                    self?.hideLoadingCard(for: group, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Card group transitions (push, pop, hide loading card)
    
    func push(group: CardGroup, animated: Bool, completion: ((Bool) -> Void)?) {
        
        let animator = PushAnimator()
        let from: () -> CardViewController? = { [weak self] in
            return self?.currentCard
        }
        let to: () -> CardViewController? = { [weak self] in
            return self?.fetchNextCard(for: group, isSameGroup: false)
        }
        
        let action: (TransitionOperation) -> Void = { [weak self] operation in
            operation.from?.navigate(to: .stack, animated: animated)
            self?.groups.append(group) // TODO: Pull this out since it shouldn't affect anything
        }
        
        let animation = TransitionOperation.Animation(animator: animator, interactive: false, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: action, completion: { [weak self] didComplete, toViewController in
            if didComplete, let viewController = toViewController {
                self?.currentCard = viewController
            }
            
            completion?(didComplete)
        })
        
        queue.addOperation(operation)
        checkForLoadingState(for: group)
    }
    
    // Convenience method that will pop either card/group based on conditions
    func pop(animated: Bool, interactive: Bool, withAnimator animator: UIViewControllerAnimatedTransitioning, completion: ((Bool) -> Void)?) {
        guard let currentGroup = groups.last else { return }
        
        if currentGroup.isLastCard == true {
            popGroup(animated: animated, interactive: interactive, completion: completion)
        } else {
            popCard(for: currentGroup, animated: animated, interactive: interactive, animator: animator, completion: completion)
        }
    }
    
    func popGroup(animated: Bool, interactive: Bool, completion: ((Bool) -> Void)?) {
        guard groups.count > 1 else {
            shakeCard(currentCard)
            return
        }
        
        let from: () -> CardViewController? = { [weak self] in
            return self?.currentCard
        }
        
        let to: () -> CardViewController? = { [weak self] in
            guard let `self` = self, self.groups.count > 1 else {
                return nil
            }
            
            let nextGroup = self.groups[self.groups.count - 2]
            return self.fetchNextCard(for: nextGroup, isSameGroup: false)
        }
        
        let animator: UIViewControllerAnimatedTransitioning = interactive ? InteractiveGroupPopAnimator() : PopGroupAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: interactive, animated: animated)
        
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete, toViewController in
            if didComplete, let to = toViewController {
                self?.groups.removeLast()
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        
        queue.addOperation(operation)
    }
    
    func popCard(for group: CardGroup, animated: Bool, interactive: Bool, animator: UIViewControllerAnimatedTransitioning = InteractivePopAnimator(), completion: ((Bool) -> Void)?) {
        let from: () -> CardViewController? = { [weak self] in
            return self?.currentCard
        }
        let to: () -> CardViewController? = { [weak self] in
            return self?.fetchNextCard(for: group, isSameGroup: true)
        }
        
//        let animator: UIViewControllerAnimatedTransitioning = InteractivePopAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: interactive, animated: animated)
        
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete, toViewController in
            if didComplete, let to = toViewController {
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        
        queue.addOperation(operation)
        checkForLoadingState(for: group)

    }
    
    func undoPopCard(animated: Bool, interactive: Bool = false, completion: ((Bool) -> Void)?) {
        
        let animator = UndoPopAnimator()
        
        let from: () -> CardViewController? = { [weak self] in
            return self?.currentCard
        }
        
        let to: () -> CardViewController? = { [weak self] in
            guard let `self` = self else { return nil }
            guard let to = self.groups.last?.previousCard, let direction = self.groups.last?.swipeDirection(for: to) else {
                self.shakeCard(self.currentCard)
                return nil
            }
            
            animator.direction = direction
            to.view.isHidden = false
            to.updateSnapshot()
            
            return to
        }
        
        let animation = TransitionOperation.Animation(animator: animator, interactive: interactive, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete, toViewController in
            if didComplete, let to = toViewController {
                self?.currentCard = to
                self?.groups.last?.didUndoSwipe(card: to)
            }
            completion?(didComplete)
            
        })
        
        queue.addOperation(operation)
    }
    
    func hideLoadingCard(for group: CardGroup, animated: Bool, completion: ((Bool) -> Void)?) {
        let from: () -> CardViewController? = { [weak self] in
            guard self?.currentCard == group.loadingCard else {
                return nil
            }
            
            return group.loadingCard
        }
        
        let to: () -> CardViewController? = {
            return group.currentCard
        }
        
        let animator = LoadingCardAnimator()
        let animation = TransitionOperation.Animation(animator: animator, interactive: false, animated: animated)
        let operation = TransitionOperation(parent: self, from: from, to: to, animation: animation, action: nil, completion: { [weak self] didComplete, toViewController in
            if didComplete, let to = toViewController {
                self?.currentCard = to
            }
            
            completion?(didComplete)
        })
        queue.addOperation(operation)
    }
    
    private func shakeCard(_ card: CardViewController) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.03
        animation.repeatCount = 3
        animation.autoreverses = true
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        animation.fromValue = NSValue.init(cgPoint: CGPoint(x: card.view.center.x - 6, y: card.view.center.y))
        animation.toValue = NSValue.init(cgPoint: CGPoint(x: card.view.center.x + 6, y: card.view.center.y))
        card.view.layer.add(animation, forKey: "position")
    }
    
    private func angle(for percent: CGFloat, inDirection direction: PanDirection) -> CGFloat {
        return direction == .right ? .pi / 10 : -.pi / 10
    }
    
    // MARK: Pan gesture handling
    private var currentTransition: AWPercentDrivenInteractiveTransition?
    
    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        
        let translation = panGesture.translation(in: nil)
        let percent = max(0, min(1, fabs(translation.x / (view.bounds.width / 2))))
        let angle: CGFloat = self.angle(for: percent, inDirection: translation.x > 0 ? .right : .left)
        
        switch gesture.state {
        case .began:
            
            // Check that we have a valid screenshot, that we aren't already transitioning, and that it's a horizontal pan
            guard gesture.isHorizontal(), let snapshot = currentCard.snapshot, currentCard != groups.last?.loadingCard, queue.operations.count == 0 else {
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
            
            // Hide our current viewController since we're using the snapshot instead
//            currentCard.view.isHidden = gesture.currentDirection == .left ? false : true
            let animator: UIViewControllerAnimatedTransitioning
            if false {// gesture.currentDirection == .left {
                snapshot.isHidden = true
                currentCard.view.isHidden = false
                let undoAnimator = UndoPopAnimator()
                undoAnimator.direction = .right
                animator = undoAnimator
//                undoPopCard(animated: true, interactive: true, completion: nil)
            } else {
                snapshot.isHidden = false
                currentCard.view.isHidden = true
                animator = InteractivePopAnimator()
//                pop(animated: true, interactive: true, withAnimator: animator, completion: nil)

            }
            pop(animated: true, interactive: true, withAnimator: animator, completion: nil)

            // Begin a pop transition that's animated and interactive
            
        case .changed:
            // Update our UIViewController transition's percentage
            (queue.operations.first as? TransitionOperation)?.transition?.update(percent)
            
            // Apply a transform for rotation/translation of the dragging card
            let translationTransform = CGAffineTransform(translationX: translation.x, y: translation.y)
            let rotationTransform = CGAffineTransform.init(rotationAngle: angle * percent)
            
            currentCard.snapshot?.layer.transform = CATransform3DMakeAffineTransform(translationTransform.concatenating(rotationTransform))
            
        case .ended:
            // TODO: Implement better handling with velocity/percentage complete
            feedbackGenerator.prepare()

            // Check if we should finish throwing the card or snap it back to the center
            if percent > 0.25 {
                let direction: PanDirection = translation.x > 0 ? .right : .left
                groups.last?.didSwipe(card: currentCard, inDirection: direction)
                throwCard(currentCard, inDirection: direction, withTranslation: translation, andVelocity: gesture.velocity(in: nil))
                (queue.operations.first as? TransitionOperation)?.transition?.finish()
                delegate?.didSwipe(card: currentCard, inDirection: direction)
            } else {
                (queue.operations.first as? TransitionOperation)?.transition?.cancel()
                resetCard(currentCard, fromTranslation: translation)
            }
            
            // TODO: Reset currentTransition to nil after finish
            
        default: break
        }
    }
    
    private let minimumMagnitudeThreshold: CGFloat = 140
    private func normalizedMagnitude(for velocity: CGVector) -> CGFloat {
        let magnitude = sqrt((velocity.dx * velocity.dx) + (velocity.dy * velocity.dy))
        
        let adjustmentThreshold: CGFloat = 50
        if magnitude < 0 {
            return max(-minimumMagnitudeThreshold, magnitude) - adjustmentThreshold
        } else {
            return min(minimumMagnitudeThreshold, magnitude) + adjustmentThreshold
        }
    }
    
    // MARK: Pan gesture helpers
    // NOTE: (ss) Using CoreAnimation instead of UIView animations fixed the issue where UIReplicantViews would stick around after explicitly being removed, hidden, etc.
    private func throwCard(_ card: CardViewController, inDirection direction: PanDirection, withTranslation translation: CGPoint, andVelocity velocity: CGPoint) {
        guard let snapshot = card.snapshot else {
            fatalError("invalid snapshot when throwing card: \(card)")
        }
        
        let adjustedVelocity = CGPoint(x: velocity.x / 10, y: velocity.y / 10)
        let deltaX: CGFloat = translation.x > 0 ? view.bounds.width * 1.25 : -view.bounds.width * 1.25
        let angle = self.angle(for: 1.0, inDirection: direction)
        let targetPoint = CGPoint(x: deltaX, y: translation.y)// * 1.5)
        
        let swipePositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerTranslationXY)
        swipePositionAnimation?.fromValue = NSValue(cgPoint:translation)
        swipePositionAnimation?.toValue = NSValue(cgPoint: targetPoint)
        swipePositionAnimation?.velocity = adjustedVelocity
        swipePositionAnimation?.completionBlock = {
            (_, _) in
            card.resetSnapshot()
        }
        
        snapshot.layer.pop_add(swipePositionAnimation, forKey: "swipePositionAnimation")
        
        let swipeRotationAnimation = POPSpringAnimation(propertyNamed: kPOPLayerRotation)
        swipeRotationAnimation?.fromValue = POPLayerGetRotationZ(snapshot.layer)
        swipeRotationAnimation?.toValue = angle
        swipePositionAnimation?.velocity = velocity
        
        
        snapshot.layer.pop_add(swipeRotationAnimation, forKey: "swipeRotationAnimation")
    }
    
    private func resetCard(_ card: CardViewController, fromTranslation translation: CGPoint) {
        guard let snapshot = card.snapshot else { return }
        
        CATransaction.begin()
        let translationAnimation = CASpringAnimation(keyPath: "translation")
        translationAnimation.initialVelocity = 0.9
        translationAnimation.duration = 0.4
        translationAnimation.isRemovedOnCompletion = false
//        translationAnimation.fromValue = NSValue.init(caTransform3D: CATransform3DMakeAffineTransform(CGAffineTransform(translationX: translation.x, y: translation.y).concatenating(CGAffineTransform(rotationAngle: 0))))
        translationAnimation.toValue = NSValue.init(caTransform3D: CATransform3DMakeAffineTransform(CGAffineTransform(translationX: 0, y: 0).concatenating(CGAffineTransform(rotationAngle: 0))))
        
        let rotationAnimation = CASpringAnimation(keyPath: "rotation")
        rotationAnimation.initialVelocity = 0.9
        rotationAnimation.duration = 0.4
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.toValue = 0
        
        CATransaction.setCompletionBlock {
            snapshot.transform = .identity
            snapshot.removeFromSuperview()
            snapshot.isHidden = true
            card.view.isHidden = false
        }
        
        snapshot.layer.add(translationAnimation, forKey: "translation")
        snapshot.layer.add(rotationAnimation, forKey: "rotation")
        
        CATransaction.commit()
    }
    
}

extension CardStackViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
