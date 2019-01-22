//
//  ZDPhotoEnum.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/29.
//  Copyright © 2018年 season. All rights reserved.
//

import Foundation
import Photos

/// 多媒体的两大类
///
/// - photo: 相片
/// - video: 相片
public enum ZDAssetType {
    case photo
    case video
}

/// 多媒体的子类
///
/// - normal: 普通照片
/// - live: 实况照片
/// - gif: 动图
/// - HDR: HDR
/// - panorama: 全景
/// - screenshot: 截屏
public enum ZDAssetSubType {
    case normal
    case live
    case gif
    case HDR
    case panorama
    case screenshot
    
    /// 获取子类型
    ///
    /// - Parameter asset: 资源
    /// - Returns: 子类型
    public static func getSubType(asset: PHAsset) -> ZDAssetSubType {
        guard let fileName = asset.value(forKey: "filename") as? NSString else {
            return normal
        }
        
        let extStr = fileName.pathExtension as String
        if extStr == "GIF" {
            print("是GIF")
            return gif
        }
        return normal
    }
}
