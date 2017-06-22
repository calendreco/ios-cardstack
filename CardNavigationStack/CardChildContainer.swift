//
//  CardChildContainer.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/22/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

class CardChildContainer: UIView, CardChild {
    var scrollView: UIScrollView {
        return _scrollView
    }
    
    let _scrollView = UIScrollView(frame: .zero)
    let container: UIView
    
    var updateSnapshot: (() -> Void)?
    var scrollDelegate: CardChildScrollDelegate?
    
    
    init(view: UIView) {
        container = view
        
        super.init(frame: view.frame)
        
        _scrollView.addSubview(view)
        _scrollView.delegate = self
        _scrollView.alwaysBounceVertical = true
        
        addSubview(_scrollView)
        
        updateSnapshot?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        _scrollView.frame = bounds
        container.frame = _scrollView.bounds
    }
}

extension CardChildContainer: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.scrollViewWillBeginDragging(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.scrollViewDidScroll(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollDelegate?.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
}
