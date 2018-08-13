//
//  ZDExtension.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import Foundation
import Photos

/* 使用的一些分类*/

// MARK: - 字符串分类
extension String {
    ///  判断字符串是否包含某些字符串
    public func contains(_ find: String, compareOption: NSString.CompareOptions) -> Bool {
        return self.range(of: find, options: compareOption) != nil
    }
}

// MARK: - 数组移除的分类

/// 针对普遍的移除
extension Array where Element: Equatable {
    public mutating func removeObject(_ item: Element) {
        self = filter { $0 != item }
    }
}

/// 针对ZDAssetModel的移除
extension Array where Element: ZDAssetModel {
    internal mutating func removeZDAssetModel(_ item: Element) {
        self = filter { $0.asset.localIdentifier != item.asset.localIdentifier }
    }
}

//MARK: - 重载PHAsset == 号运算符
extension PHAsset {
    static func ==(lhs: PHAsset, rhs: PHAsset) -> Bool {
        return lhs.localIdentifier == rhs.localIdentifier
    }
}

//MARK: - 判断是不是模拟器
struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }()
}


// MARK: - 颜色分类
extension UIColor {
    class var lightGreen: UIColor {
        return UIColor(red: 0x09/255, green: 0xbb/255, blue: 0x07/255, alpha: 1)
    }
    
    class var main: UIColor {
        return UIColor(red: 0/255, green: 121/255, blue: 231/255, alpha:1.00)
    }
}

// MARK: - 从ZDPhotoBundle中获取图片

/// ZDPhoto.bundle
let path = Bundle.main.path(forResource: "ZPhoto", ofType: "bundle")
let ZDPhotoBundle = Bundle(path: path!)

extension UIImage {
    convenience init?(namedInBundle name: String) {
        self.init(named: name, in: ZDPhotoBundle, compatibleWith: nil)
    }
}
