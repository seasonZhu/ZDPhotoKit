//
//  ImageConstant.swift
//  JiuRongCarERP
//
//  Created by HSGH on 2018/2/23.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import Foundation

/// 常量设置,这个是为了框架与项目类冲突而设置的 同时也是为了避免重名
struct ImageConstant {
    static let kScreenWidth = UIScreen.main.bounds.size.width
    static let kScreenHeight = UIScreen.main.bounds.size.height
    
    static let toolbarHeight: CGFloat = 44
    
    static var kNavigationBarHeight: CGFloat {
        return kScreenHeight == 812 ? 88 : 64
    }
    
    static var bottomSafeHeight: CGFloat {
        return kScreenHeight == 812 ? 34 : 0
    }
}
