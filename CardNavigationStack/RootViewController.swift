//
//  RootViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/14/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

class RootViewController: UIViewController {
    
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
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setTitle("< Back", for: .normal)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        return button
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton()
        button.setTitle("+ Add", for: .normal)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleAddButton), for: .touchUpInside)
        
        return button
    }()
    
    let stack: CardStackViewController
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        let loadingView = LoadingCard(frame: .zero)
        let loadingViewContainer = MockCardChild(view: loadingView)
        let loadingCard = CardViewController(child: loadingViewContainer, state: .stack)
        
        let store = CardGroupStore()
        let group = CardGroup(loadingCard: loadingCard, store: store, title: nil)
        
        stack = CardStackViewController(group: group)
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(stack)
        view.addSubview(stack.view)
        
        loadingCard.view.frame = view.bounds
        
        bottomBar.addSubview(backButton)
        bottomBar.addSubview(plusButton)
        view.addSubview(bottomBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.view.frame = view.bounds
        
        bottomBar.frame = CGRect(x: 0, y: view.bounds.height - 44, width: view.bounds.width, height: 44)
        backButton.frame = bottomBar.bounds
        backButton.frame.size.width = 100
        plusButton.frame = bottomBar.bounds
        plusButton.frame.size.width = 100
        plusButton.frame.origin.x = view.bounds.width - plusButton.frame.width
        
    }
    
    @objc private func handleBackButton() {
        stack.popGroup(animated: true, interactive: false, completion: nil)
    }
    
    @objc private func handleAddButton() {
        
        let loadingView = LoadingCard(frame: self.view.bounds)
        let loadingViewContainer = MockCardChild(view: loadingView)
        let loadingCard = CardViewController(child: loadingViewContainer, state: .stack)
        
        let store = CardGroupStore()
        let group = CardGroup(loadingCard: loadingCard, store: store, title: nil)

        stack.push(group: group, animated: true, completion: nil)
    }
}
