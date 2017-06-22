//
//  RootViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/14/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit
import pop

class RootViewController: UIViewController {
    
    var history: [CardViewController] = []
    
    private var bottomBar: UILabel = {
        let view = UILabel()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        view.frame.size.height = 44
        view.text = ""
        view.textColor = .white
        view.textAlignment = .center
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var undoButton: UIButton = {
        let button = UIButton()
        button.setTitle("UNDO", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
        
        button.addTarget(self, action: #selector(handleUndoButton), for: .touchUpInside)
        
        return button
    }()
    
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("CLOSE", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
        
        button.addTarget(self, action: #selector(handleCloseButton), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton()
        button.setTitle("PUSH", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
        
        button.addTarget(self, action: #selector(handleAddButton), for: .touchUpInside)
        
        return button
    }()
    
    fileprivate lazy var historyButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "undo-icon"), for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.layer.isDoubleSided = true
        button.addTarget(self, action: #selector(handleHistoryButton), for: .touchUpInside)
        
        return button
    }()
    
    let stack: CardStackViewController
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        let loadingView = LoadingCard(frame: CGRect(x: 0, y: 0, width: 375, height: 670))
        let loadingViewContainer = MockCardChild(view: loadingView)
        let loadingCard = CardViewController(child: loadingViewContainer, state: .stack)
        
        let store = CardGroupStore()
        store.simulatedDelay = 1
        let group = CardGroup(loadingCard: loadingCard, store: store, title: nil)
        group.store.loadCounter = 100 // So we never reach the end of the stack
        
        stack = CardStackViewController(group: group)
        
//        let loadingView2 = LoadingCard(frame: CGRect(x: 0, y: 0, width: 375, height: 670))
//        let loadingViewContainer2 = MockCardChild(view: loadingView)
//        let loadingCard2 = CardViewController(child: loadingViewContainer, state: .stack)
//        historyGroup = CardGroup(loadingCard: loadingCard2, store: HistoryCardGroupStore(), title: nil)
//
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(stack)
        view.addSubview(stack.view)
        stack.delegate = self
        
        loadingCard.view.frame = view.bounds
        
        view.addSubview(historyButton)
        bottomBar.addSubview(undoButton)
        bottomBar.addSubview(closeButton)
        bottomBar.addSubview(plusButton)
        view.addSubview(bottomBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleHistoryButton() {
        
        let viewController = HistoryViewController(cards: history)
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.view.frame = view.bounds
        
        historyButton.frame = CGRect(x: view.bounds.width - 80, y: 40, width: 40, height: 40)
        historyButton.layer.cornerRadius = 20
        
        bottomBar.frame = CGRect(x: 0, y: view.bounds.height - 44, width: view.bounds.width, height: 44)
        undoButton.frame = bottomBar.bounds
        undoButton.frame.size.width = 100
        
        closeButton.frame = bottomBar.bounds
        closeButton.frame.size.width = 100
        closeButton.frame.origin.x = bottomBar.center.x - 50
        
        plusButton.frame = bottomBar.bounds
        plusButton.frame.size.width = 100
        plusButton.frame.origin.x = view.bounds.width - plusButton.frame.width
        
    }
    
    @objc private func handleUndoButton() {
        stack.undoPopCard(animated: true, completion: nil)
    }
    
    @objc private func handleCloseButton() {
        stack.popGroup(animated: true, interactive: false, completion: nil)
    }
    
    @objc private func handleAddButton() {
        
        let loadingView = LoadingCard(frame: view.bounds)
        let loadingViewContainer = MockCardChild(view: loadingView)
        let loadingCard = CardViewController(child: loadingViewContainer, state: .stack)
        
        let store = CardGroupStore()
        store.simulatedDelay = 1
        let group = CardGroup(loadingCard: loadingCard, store: store, title: nil)

        stack.push(group: group, animated: true, completion: nil)
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        switch motion {
        case .motionShake:
            stack.undoPopCard(animated: true, completion: nil)
        default: break
        }
    }
}

extension RootViewController: CardStackViewDelegate {
    func didSwipe(card: CardViewController, inDirection direction: PanDirection) {
        if direction == .right {
            if let index = history.index(of: card) {
                history.remove(at: index)
            }
            
            history.append(card)
            
            if let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY) {
                
                anim.fromValue = CGSize(width: 1, height: 1)
                anim.toValue = CGSize(width: 1.45, height: 1.45)//historyButton.bounds.size.applying(CGAffineTransform.init(scaleX: 1.25, y: 1.25))
                anim.autoreverses = true
//                anim.duration = 0.25
//                anim.springBounciness = 10
//                anim.velocity = 10//CGPoint(x: 0, y: 100)
                
                historyButton.layer.pop_add(anim, forKey: "popButton")
                
            }
        }
    }
}


extension RootViewController: HistoryViewDelegate {
    
    func historyViewDidClearHistory(_ viewController: HistoryViewController) {
        history.removeAll()
    }
    
    func historyView(_ viewController: HistoryViewController, didSelectCard card: CardViewController) {
        viewController.dismiss(animated: true) {
            card.view.isHidden = false
            card.updateSnapshot()

            let loadingView = LoadingCard(frame: self.view.bounds)
            let loadingViewContainer = MockCardChild(view: loadingView)
            let loadingCard = CardViewController(child: loadingViewContainer, state: .stack)
            
            let store = HistoryCardGroupStore()
            let group = CardGroup(loadingCard: loadingCard, store: store, title: nil)
            group.cards = [card]
            
            self.stack.push(group: group, animated: true, completion: nil)
        }
    }
}
