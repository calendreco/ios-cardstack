//
//  UIView+Snapshot.swift
//  Live
//
//  Created by Stephen Silber on 4/14/17.
//  Copyright © 2017 Calendre. All rights reserved.
//

import UIKit

extension UIView {
    
    func snapshot(of rect: CGRect? = nil) -> UIImage? {
        // snapshot entire view
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let wholeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // if no `rect` provided, return image of whole view
        guard let image = wholeImage, let rect = rect else {
            return wholeImage
        }
        
        // otherwise, crop image to given rect
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
