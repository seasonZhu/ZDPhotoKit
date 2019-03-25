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
public class ZDAssetModel {
    
    /// 图片资源
    public var asset = PHAsset() {
        didSet {
            let option = PHImageRequestOptions()
            option.resizeMode = .fast
            option.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImageData(for: asset, options: option) { (data, dataUTI, orientation, infomation) in
                guard let imageData = data, let url = infomation?["PHImageFileURLKey"] as? URL  else {
                    return
                }
                DispatchQueue.main.async {
                    self.image = UIImage(data: imageData)
                    self.imageURL = url
                }
            }
        }
    }
    
    /// 图片
    public var image: UIImage?
    
    /// 图片沙盒地址
    public var imageURL: URL?
    
    /// 资源类型
    public var type: ZDAssetType = .photo
    
    /// 资源子类
    public var subType: ZDAssetSubType = .normal
    
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
    static func creat(asset: PHAsset, type: ZDAssetType, subType: ZDAssetSubType) -> ZDAssetModel {
        let model = ZDAssetModel()
        model.asset = asset
        model.type = type
        model.subType = subType == .live ? .live : ZDAssetSubType.getSubType(asset: asset)
        model.isSelect = false
        model.pixW = asset.pixelWidth
        model.pixH = asset.pixelHeight
        model.timeLength = String(format: "%.0lf",asset.duration)
        return model
    }
}
