//
//  ZDPhotoTitleButton.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 自定义的NaviBar的中间按钮
class ZDPhotoTitleButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleY = titleLabel?.frame.origin.y
        let titleH = titleLabel?.frame.size.height
        let titleW = titleLabel?.frame.size.width
        
        let imageY = imageView?.frame.origin.y
        let imageW = imageView?.frame.size.width
        let imageH = imageView?.frame.size.height
        
        let width = frame.size.width;
        
        titleLabel?.frame = CGRect(x: (width - (titleW! + imageW! + 5)) / 2, y: titleY!, width: titleW!, height: titleH!);
        
        imageView?.frame = CGRect(x: titleLabel!.frame.maxX + 5, y: imageY!, width: imageW!, height: imageH!)
    }

}
