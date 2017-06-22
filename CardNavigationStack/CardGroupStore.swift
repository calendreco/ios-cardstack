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
    var simulatedDelay: Int = 1
    var fixedColor: UIColor = UIColor.random()
    var loadCounter: Int = 2
    
    func load(withCompletion completion: (([UIColor]) -> Void)?) {
        print("Loading more cards...")
        
        isLoading = true
        
        let colors = (0..<Int.random(from: 4, to: 9)).map { _ -> UIColor in
            return fixedColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(simulatedDelay)) { [weak self] in
            self?.isLoading = false
            
            completion?(colors)
            
            self?.didFinishLoading?()
            self?.loadCounter -= 1
            self?.hasLoadedAllCards = (self?.loadCounter == 0)
            
            print("Finished loading \(colors.count) more cards!")
        }
    }
}
