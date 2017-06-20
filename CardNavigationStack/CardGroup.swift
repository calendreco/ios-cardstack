//
//  CardGroup.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/15/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

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
    
    func willBeginSwiping() {
        //
    }
    
    func didSwipe(card: CardViewController, inDirection direction: PanDirection) {
        currentIndex += 1
        if cards.count - currentIndex < 3 && !store.isLoading && !store.hasLoadedAllCards {
            fetchNext()
        }
    }
    
    func fetchNext() {
        store.load { [weak self] cards in
            guard let `self` = self else { return }
            self.cards.append(contentsOf: cards.reversed())
        }
    }
}
