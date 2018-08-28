//
//  ZDAssetModel.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/29.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 自定义的Asset模型
public class ZDAssetModel: NSObject {
    
    /// 图片资源
    public var asset = PHAsset()
    
    /// 资源类型
    public var type: ZDAssetType = .photo
    
    /// 资源子类
    var subType: ZDAssetSubType = .normal
    
    /// 图片宽
    public var pixW: Int = 0
    
    /// 图片高
    public var pixH: Int = 0
    
    /// 是否被选中
    public var isSelect = false
    
    /// 被选择的序列
    public var selectNum = 0
    
    /// 视频时长
    public var timeLength = ""
    
    /// 生成ZDAssetModel模型
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - type: 类型
    ///   - subType: 子类型
    /// - Returns: ZDAssetModel
    class func creat(asset: PHAsset, type: ZDAssetType, subType: ZDAssetSubType) -> ZDAssetModel {
        let model = ZDAssetModel()
        model.asset = asset
        model.type = type
        model.subType = subType == .live ? .live : ZDAssetSubType.getSubType(asset: asset)
        model.isSelect = false
        model.pixW = asset.pixelWidth
        model.pixH = asset.pixelHeight
        model.timeLength = String.init(format: "%.0lf",asset.duration)
        return model
    }
}
