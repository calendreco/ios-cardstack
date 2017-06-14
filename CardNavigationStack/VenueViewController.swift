//
//  VenueViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 5/19/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import UIKit

class VenueView: UIView, CardChild {
    var loadingCard: UIView? {
        return nil
    }
    
    var contentView: UIView {
        return self
    }
    
    let scrollView = UIScrollView(frame: .zero)
    let container = UIView(frame: .zero)
    
    var updateSnapshot: (() -> Void)?
    var scrollDelegate: CardChildScrollDelegate?
    
    init(background: UIColor) {
        super.init(frame: .zero)
        container.backgroundColor = background
        container.layer.cornerRadius = 10
        
        scrollView.addSubview(container)
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        
        addSubview(scrollView)
        
        updateSnapshot?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        container.frame = scrollView.bounds
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
