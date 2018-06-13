//
//  ZDAlbumModel.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/29.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 自定义的相册模型
class ZDAlbumModel: NSObject {
    
    /// 相册结果集
    var result = PHFetchResult<PHAsset>()
    
    /// 相册名
    var name = ""
    
    /// 相册中照片数量
    var count = 0
    
    /// 封面asset
    var asset: PHAsset?
    
    /// 封面
    var albumImage: UIImage?
    
    /// 相册中选中的照片
    var selectAssets = [ZDAssetModel]() {
        didSet {
            var selectCount = 0
            for selectAsset in selectAssets {
                result.enumerateObjects({ (asset, index, _) in
                    if selectAsset.asset == asset {
                        selectCount += 1
                    }
                })
            }
            self.selectCount = selectCount
        }
    }
    
    /// 相册中选中的个数
    var selectCount = 0
}
