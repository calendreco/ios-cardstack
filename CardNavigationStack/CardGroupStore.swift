//
//  CardStackDataSource.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/15/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

class CardGroupStore {
    
    var hasLoadedAllCards: Bool = false
    var isLoading: Bool = false
    var didFinishLoading: (() -> Void)?
    var simulatedDelay: Int = 26
    var fixedColor: UIColor = UIColor.random()
    var loadCounter: Int = 3
    
    func load(withCompletion completion: (([CardViewController]) -> Void)?) {
        print("Loading more cards...")
        
        isLoading = true
        
        let cards = (0..<Int.random(from: 4, to: 9)).map { _ -> CardViewController in
            let card = VenueView(background: fixedColor)
            return CardViewController(child: card, state: .stack)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            self?.isLoading = false
            
            completion?(cards)
            
            self?.didFinishLoading?()
            self?.loadCounter -= 1
            self?.hasLoadedAllCards = (self?.loadCounter == 0)
            
            print("Finished loading \(cards.count) more cards!")
        }
    }
}
