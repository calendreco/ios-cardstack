//
//  VenueViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import UIKit

class VenueView: UIView, CardChild {
    
    var scrollView: UIScrollView {
        return _scrollView
    }
    
    let _scrollView = UIScrollView(frame: .zero)
    let container = UIView(frame: .zero)
    
    var updateSnapshot: (() -> Void)?
    var scrollDelegate: CardChildScrollDelegate?
    
    init(background: UIColor) {
        super.init(frame: .zero)
        scrollView.backgroundColor = background
        
        _scrollView.addSubview(container)
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

extension VenueView: UIScrollViewDelegate {
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
