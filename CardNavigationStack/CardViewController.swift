//
//  ViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import UIKit

/*
 Goals:
     - Wrap a UIViewController in a 'card container'
     - UIViewController without being wrapped is a fullscreen scrollView most likely
     - Wrapping it puts it inside of a card and allows it to have 3 states. Scroll to expand/collapse
     - Wrapped 'card containers' can be swipped left and write and are responsible for providing a snapshot of themselves whenever they udate their UI
 
 
     1) pass in a scrollView
     2) pass in a CardChildScrollDelegate
     3) pass in a UIView that needs to be wrapped in a UIScrollView
 */

// Allows child view controllers to pass their scroll delegates without setting UIScrollView.delegate (breaks tableView, etc)
protocol CardChildScrollDelegate: class {
    //func shouldAllowScrollingToBegin() -> Bool
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
}

protocol CardChild: class {
    // Loading card allows different content types to provide custom loading cards
    var loadingCard: UIView? { get }
    
    // ContentView is the view wrapping the inner `UIScrollView`
    var contentView: UIView { get }
    
    var updateSnapshot: (() -> Void)? { get set }
    
    // Needs to be manually called within the `UIScrollViewDelegate`
    weak var scrollDelegate: CardChildScrollDelegate? { get set }
}

class CardViewController: UIViewController {

    enum State {
        case minimized
        case stack
        case expanded
    }

    var state: State
    // Do we ever want our previous state? Support a `transitionBack` similar to directions mode
    

    let container: UIView // This is the "card" that is positioned on the screen
    fileprivate(set) var snapshot: UIView? // We store our snapshot and update it whenever our child tells us we need to
    
    // MARK: Scroll delegate helper flags
    fileprivate struct ScrollFlags {
        var isDragging: Bool = false
        var isTransitioning: Bool = false
    }
    
    fileprivate let child: CardChild
    fileprivate var scrollFlags: ScrollFlags = ScrollFlags()

    // When passed a CardContainerChild, we need to wrap it in a view and position it
    init(child: CardChild, state: State) {
        self.state = state
        self.container = child.contentView
        self.child = child
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(container)
        
        child.scrollDelegate = self
        child.updateSnapshot = updateSnapshot
    }
    
    // TODO: Allow initializing without a CardContainerChild
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        if parent != nil {
            updateSnapshot()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.frame = self.frame(for: state)
    }
    
    func navigate(to state: State, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: [], animations: {
                self.container.frame = self.frame(for: state)
            }, completion: { finished in
                self.state = state
            })
        } else {
            container.frame = self.frame(for: state)
            self.state = state
        }
    }
    
    fileprivate func frame(for state: State) -> CGRect {
        return CGRect(x: 10, y: self.origin(for: state), width: view.bounds.width - 20, height: view.bounds.height * 0.9)
    }
    
    fileprivate func origin(for state: State) -> CGFloat {
        switch state {
        case .minimized:
            return view.bounds.height - 110
        
        case .stack:
            return view.bounds.height * 0.4
        
        case .expanded:
            return view.bounds.height * 0.1
            
        }
    }
    
    func updateSnapshot() {
        container.frame = self.frame(for: state)
        
        var snapshotRect = container.bounds
        snapshotRect.size.width = container.bounds.width
        snapshotRect.size.height = view.bounds.height - origin(for: .stack)
        
        guard let snapshot = container.resizableSnapshotView(from: snapshotRect, afterScreenUpdates: true, withCapInsets: .zero) else {
            print("Unable to snapshot view: \(container)")
            return
        }
        
        self.snapshot = snapshot
    }
    
}

extension CardViewController: CardChildScrollDelegate {
   
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollFlags.isDragging = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }
        
        if scrollView.contentOffset.y < 0 {
            container.frame.origin.y += fabs(scrollView.contentOffset.y)
            scrollView.contentOffset = .zero
        } else if container.frame.origin.y > self.origin(for: .expanded) {
            container.frame.origin.y -= scrollView.contentOffset.y
            scrollView.contentOffset = .zero
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollFlags.isDragging = false
        
        guard scrollView.contentOffset.y == 0 else {
            return
        }
        
        var nextState: State = state
        
        let buffer: CGFloat = 25
        
        targetContentOffset.pointee.y = 0
        
        switch self.state {
        case .minimized:
            if container.frame.origin.y >= self.origin(for: .stack) - buffer && velocity.y > 0 {
                nextState = .stack
            } else if velocity.y > 0 {
                nextState = .expanded
            }
        case .stack:
            if container.frame.origin.y >= self.origin(for: .expanded) - buffer && velocity.y > 0 {
                nextState = .expanded
            } else if container.frame.origin.y <= self.origin(for: .minimized) + buffer && velocity.y < 0 {
                nextState = .minimized
            }
        
        case .expanded:
            if container.frame.origin.y <= self.origin(for: .stack) + buffer && velocity.y < 0 {
                nextState = .stack
            } else if container.frame.origin.y >= self.origin(for: .stack) - buffer && velocity.y < 0 {
                nextState = .minimized
            }
        }
        
        navigate(to: nextState, animated: true)
    }
}
