//
//  LoadingCard.swift
//  Live
//
//  Created by Stephen Silber on 3/28/17.
//  Copyright © 2017 Calendre. All rights reserved.
//

import Foundation
import UIKit

class LoadingCard: UIView {
    
    private let highlightReel: UIView
    private let topText: UIView
    private let bottomText: UIView
    
    override init(frame: CGRect) {
        highlightReel   = LoadingCard.generateLoadingView()
        topText         = LoadingCard.generateLoadingView()
        bottomText      = LoadingCard.generateLoadingView()
        
        super.init(frame: frame)
        backgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.00)
        layer.cornerRadius = 3
        
        addSubview(highlightReel)
        addSubview(topText)
        addSubview(bottomText)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        highlightReel.frame = CGRect(x: 10, y: 10, width: bounds.width - 20, height: 260)
        topText.frame = CGRect(x: 10, y: highlightReel.frame.maxY + 10, width: bounds.width - 20, height: 20)
        bottomText.frame = CGRect(x: 10, y: topText.frame.maxY + 10, width: bounds.width - 20, height: 20)
        
        addShimmerEffectToView(highlightReel)
        addShimmerEffectToView(topText)
        addShimmerEffectToView(bottomText)
        
    }
    
    private static func generateLoadingView(withSize size: CGSize = .zero) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }
    
    private func addShimmerEffectToView(_ view: UIView) {
        let light = UIColor.white.withAlphaComponent(0.1).cgColor
        let alpha = UIColor.white.withAlphaComponent(0.5).cgColor
        
        let gradientMask = CAGradientLayer()
        gradientMask.frame = bounds
        gradientMask.colors = [alpha, light, alpha]
        
        let gradientSize = 0.25
        
        let startLocations = [0, gradientSize/2, gradientSize]
        let endLocations = [(1 - gradientSize), (1 - gradientSize/2), 1]
        
        let animation = CABasicAnimation(keyPath: "locations")
        
        gradientMask.locations = startLocations as [NSNumber]?
        gradientMask.startPoint = CGPoint(x:0 - (gradientSize * 6), y: 0.5)
        gradientMask.endPoint = CGPoint(x:1 + (gradientSize * 6), y: 0.7)
        
        view.layer.mask = gradientMask
        
        animation.fromValue = startLocations
        animation.toValue = endLocations
        animation.repeatCount = HUGE
        animation.duration = 2.25
        
        gradientMask.add(animation, forKey: nil)
    }
    
    func stopShimmering() {
        highlightReel.layer.removeAllAnimations()
        topText.layer.removeAllAnimations()
        bottomText.layer.removeAllAnimations()
        
        highlightReel.layer.mask = nil
        topText.layer.mask = nil
        bottomText.layer.mask = nil
    }
}
