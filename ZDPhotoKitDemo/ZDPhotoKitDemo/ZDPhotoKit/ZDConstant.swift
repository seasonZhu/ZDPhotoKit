//
//  ZDConstant.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/7.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 常量设置,这个是为了框架与项目类冲突而设置的 同时也是为了避免重名
struct ZDConstant {
    static let kScreenWidth = UIScreen.main.bounds.size.width
    static let kScreenHeight = UIScreen.main.bounds.size.height
    
    static let toolbarHeight: CGFloat = 44
    
    static var kNavigationBarHeight: CGFloat {
        return kScreenHeight == 812 ? 88 : 64
    }
    
    static var kBottomSafeHeight: CGFloat {
        return kScreenHeight == 812 ? 34 : 0
    }
}


/// ZDPhoto.bundle
let path = Bundle.main.path(forResource: "ZPhoto", ofType: "bundle")
let ZDPhotoBundle = Bundle(path: path!)
