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
    
    // TODO: Generic?
    func load(withCompletion completion: (([CardViewController]) -> Void)?) {
        print("Loading more cards...")
        isLoading = true
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
//        DispatchQueue.main.async {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
            self?.isLoading = false
            self?.hasLoadedAllCards = true
            completion?(cards)
            self?.didFinishLoading?()
            print("Finished loading \(cards.count) more cards!")
        }
    }
}
