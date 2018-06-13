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
enum ZDAssetType {
    case photo, //  相片
         video  //  视频
}

/// 多媒体的子类
enum ZDAssetSubType {
    case normal,  //  普通照片
         live,  //  实况照片
         gif,   //  动图
         HDR,   //
         panorama,    //  全景
         screenshot  //  截屏
    
    /// 获取子类型
    ///
    /// - Parameter asset: 资源
    /// - Returns: 子类型
    static func getSubType(asset: PHAsset) -> ZDAssetSubType {
        let fileName = asset.value(forKey: "filename") as! NSString
        let extStr = fileName.pathExtension as String
        if extStr == "GIF" {
            print("是GIF")
            return gif
        }
        return normal
    }
}
