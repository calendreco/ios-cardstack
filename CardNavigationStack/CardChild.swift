//
//  CardChild.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/15/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

protocol CardChild: class {
    // ContentView is the view wrapping the inner `UIScrollView`
    var scrollView: UIScrollView { get }
    
    var updateSnapshot: (() -> Void)? { get set }
    
    // Needs to be manually called within the `UIScrollViewDelegate`
    weak var scrollDelegate: CardChildScrollDelegate? { get set }
}
