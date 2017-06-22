//
//  CardGroup.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/15/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

class HistoryCardGroupStore: CardGroupStore {
    override func load(withCompletion completion: (([UIColor]) -> Void)?) {
        completion?([])
        hasLoadedAllCards = true
        isLoading = false
    }
}

class CardGroup {
    
    var currentCard: CardViewController {
        return cards[currentIndex]
    }
    
    var nextCard: CardViewController {
        return cards[currentIndex + 1]
    }
    
    var previousCard: CardViewController? {
        guard currentIndex > 0 else { return nil }
        return cards[currentIndex - 1]
    }
    
    var isLastCard: Bool {
        // We are on the last card, we aren't loading any more and don't need to load any more
        return currentIndex == cards.count - 1 && store.hasLoadedAllCards && !store.isLoading
    }
    
    var shouldShowLoadingCard: Bool {
        return (store.isLoading && currentIndex - 1 <= cards.count)
    }
    
    private var swipeDirections: [PanDirection] = []
    
    // Manages paging + network requests for loading cards
    let store: CardGroupStore
    
    var currentIndex: Int = 0
    
    var cards: [CardViewController] = []
    
    var loadingCard: CardViewController
    
    var title: String?
    
    init(loadingCard: CardViewController, store: CardGroupStore, title: String?) {
        self.loadingCard = loadingCard
        self.title = title
        self.store = store
        
        fetchNext()
    }
    
    func swipeDirection(for card: CardViewController) -> PanDirection? {
        guard let index = cards.index(of: card), swipeDirections.count > index else {
            return nil
            
        }
        
        return swipeDirections[index]
    }
    
    func willBeginSwiping() {
        //
    }
    
    func didSwipe(card: CardViewController, inDirection direction: PanDirection) {
        currentIndex += 1
        if cards.count - currentIndex < 3 && !store.isLoading && !store.hasLoadedAllCards {
            fetchNext()
        }
        swipeDirections.append(direction)
    }
    
    func didUndoSwipe(card: CardViewController) {
        currentIndex -= 1
        swipeDirections.removeLast()
    }
    
    func fetchNext() {
        store.load { [weak self] colors in
            guard let `self` = self else { return }
            
            let cards = colors.map({ (color) -> CardViewController in
                let card = VenueView(background: color)
                return CardViewController(child: card, state: .stack)
            })
            
            self.cards.append(contentsOf: cards.reversed())
        }
    }
}
