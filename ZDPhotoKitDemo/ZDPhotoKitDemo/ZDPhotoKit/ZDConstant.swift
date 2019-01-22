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
        return isFullScreen ? 88 : 64
    }
    
    static var kBottomSafeHeight: CGFloat {
        return isFullScreen ? 34 : 0
    }
    
    static var isFullScreen: Bool {
        if #available(iOS 11, *) {
            guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
                return false
            }
            
            if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
                return true
            }
        }
        return false
    }
}


/// ZDPhoto.bundle
let ZDPhotoBundle: Bundle? = {
    let bundle = Bundle(path: Bundle(for: ZDPhotoPickerController.classForCoder()).resourcePath! + "/ZDPhoto.bundle")
    return bundle
}()
