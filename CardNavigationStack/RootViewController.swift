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
        view.text = "Next 3 hours"
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
        
        let card = VenueView(background: .red)
        let cardContainer = CardViewController(child: card, state: .stack)
        let group = CardGroup(cards: [cardContainer], title: nil)
        
        stack = CardStackViewController(group: group)
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(stack)
        view.addSubview(stack.view)
        
        bottomBar.addSubview(backButton)
        bottomBar.addSubview(plusButton)
        view.addSubview(bottomBar)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.handleAddButton()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            self.handleBackButton()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            self.handleAddButton()
        }

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
        var previousColor = UIColor.random()
        let cards = (0..<Int.random(from: 1, to: 5)).map { _ -> CardViewController in
            var color = UIColor.random()
            while color == previousColor {
                color = UIColor.random()
            }
            previousColor = color
            let card = VenueView(background: color)
            return CardViewController(child: card, state: .stack)
        }
        
        let group = CardGroup(cards: cards, title: nil)
        print("Pushing card group of \(cards.count)")
        stack.push(cardGroup: group, animated: true, completion: nil)
    }
}
