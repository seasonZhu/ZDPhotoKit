//
//  ImageAlbumItem.swift
//  JiuRongCarERP
//
//  Created by HSGH on 2018/2/22.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import Photos

/// 相簿列表项
struct ImageAlbumItem {
    //  相簿名称
    var title: String?
    //  相簿内的资源
    var fetchResult: PHFetchResult<PHAsset>
    //  相薄的最新图片的缩略图
    var image: UIImage?
}
