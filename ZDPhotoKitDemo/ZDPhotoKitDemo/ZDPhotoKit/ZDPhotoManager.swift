//
//  ZDPhotoManager.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/29.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 图片管理器
public class ZDPhotoManager {
    //MARK:- 属性设置
    
    /// 允许选择视频
    var isAllowVideo = false
    
    /// 允许选择gif
    var isAllowGif = false
    
    /// 允许选择live
    var isAllowLive = false
    
    /// 允许拍摄视频
    var isAllowCaputreVideo = false
    
    /// 允许拍摄照片
    var isAllowTakePhoto = false
    
    /// 允许进行剪裁
    var isAllowCropper = false
    
    /// 相册页面允许展示Live图效果
    var isAllowShowLive = false
    
    /// 相册页面允许展示Gif图效果
    var isAllowShowGif = false
    
    /// 允许展示资源的顺序数字
    var isShowSelectCount = false
    
    /// 最大的相片选择数量
    var maxSelected = 9
    
    /// 一行展示图片的数量
    var rowImageCount = 4
    
    /// 通过视频时间筛选视频 默认大于2分钟的视频不要
    var maxVideoTime = 120
    
    /// 剪裁的大小
    var cropFrame = CGRect(x: 0, y: ZDConstant.kScreenHeight / 2.0 - ZDConstant.kScreenWidth / 2.0, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenWidth)
    
    //MARK:- 配置化闭包
    
    /// 导航栏的主题颜色
    var mainColorCallback: (() -> UIColor)?
    
    /// 其他控件的颜色
    var widgetColorCallback: (() -> UIColor)?
    
    //MARK:- 单例
    static let `default` = ZDPhotoManager()
    private init() {}
    
    //MARK:- 工具类方法
    
    /// 是否认证过
    ///
    /// - Parameter callback: 回调
    func authorizationStatus(callback: @escaping ((Bool) -> Void)) {
        PHPhotoLibrary.requestAuthorization { (status) in
            callback(status == .authorized)
        }
    }
    
    /// 获取所有的相册
    ///
    /// - Parameters:
    ///   - allowPickingVideo: 是否筛选视频
    ///   - allowPickingImage: 是否筛选图片
    ///   - callback: 回调
    public func getAllAlbums(allowPickingVideo: Bool,
                      allowPickingImage: Bool,
                      callback: @escaping (([ZDAlbumModel]) -> Void)) {
        var albums = [ZDAlbumModel]()
        
        //  列出所有系统的智能相册
        let smartOptions = PHFetchOptions()
        
        //  获取智能相册集合
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options:smartOptions)
        /*smartAlbums不遵守Sequenc协议 所以就不能for in 循环*/
        
        //  处理智能相册 后续应该会换遍历方法
        smartAlbums.enumerateObjects { (collection, index, _) in
            // 有可能是PHCollectionList对象，过滤
            if collection.isKind(of: PHCollectionList.classForCoder()) {return}
            // 从集合中获取相册
            let result:PHFetchResult = PHAsset.fetchAssets(in: collection, options: smartOptions)
            
            // 过滤空相册
            if result.count < 1 {return}
            
            // 过滤删除相册 长时间曝光相册
            if let localizedTitle = collection.localizedTitle,
                localizedTitle == "最近删除"
                    || localizedTitle.contains("Deleted", compareOption: .caseInsensitive)
                    || localizedTitle.contains("Long Exposure", compareOption: .caseInsensitive) {return }
            
            // 过滤视频相册
            if !allowPickingVideo && collection.localizedTitle == "Videos" { return }
            
            // 过滤Gif相册
            if !self.isAllowLive && collection.localizedTitle == "Animated" { return }
            
            // 过滤LivePhoto相册
            if !self.isAllowLive && collection.localizedTitle == "Live Photos" { return }
            
            let album = self.getZDAlbumModel(result: result, name: collection.localizedTitle ?? "相片")
            albums.append(album)
        }
        
        //  列出所有用户创建的相册
        guard let userAlbums = PHCollectionList.fetchTopLevelUserCollections(with: nil) as? PHFetchResult<PHAssetCollection> else {
            DispatchQueue.main.async {
                callback(albums)
            }
            return
        }
        
        userAlbums.enumerateObjects { (collection, index, _) in
            // 有可能是PHCollectionList对象，过滤
            if collection.isKind(of: PHCollectionList.classForCoder()) {return}
            // 从集合中获取相册
            let result:PHFetchResult = PHAsset.fetchAssets(in: collection, options: smartOptions)
            // 过滤空相册
            if result.count < 1 {return}
            
            let album = self.getZDAlbumModel(result: result, name: collection.localizedTitle ?? "相片")
            albums.append(album)
        }
        
        //  相册按包含的照片数量排序（降序）
        albums = albums.sorted { return $0.result.count > $1.result.count }
        
        DispatchQueue.main.async {
            callback(albums)
        }
    }
    
    /// 通过ZDAlbumModel模型获取所有的Asset
    ///
    /// - Parameters:
    ///   - model: ZDAlbumModel
    ///   - allowPickingVideo: 是否筛选视频
    ///   - allowPickingImage: 是否筛选图片
    ///   - callback: 回调
    public func getAllAssetOfAlbum(model: ZDAlbumModel,
                                   allowPickingVideo: Bool,
                                   allowPickingImage: Bool,
                                   callback: @escaping (([ZDAssetModel]) -> Void)) {
        var assets = [ZDAssetModel]()
        let result = model.result
        
        result.enumerateObjects { (asset, index, nil) in
            var type: ZDAssetType = .photo
            var subType: ZDAssetSubType = .normal
            
            //  获取资源类型
            if asset.mediaType == .image {
                type = .photo
            }else if asset.mediaType == .video {
                type = .video
            }
            
            //  获取资源子类型
            if asset.mediaSubtypes == .photoLive {
                subType = .live
            }
            
            let assetModel = ZDAssetModel.creat(asset: asset, type: type, subType: subType)
            
            if !allowPickingVideo && assetModel.type == .video
                || !self.isAllowLive && assetModel.subType == .live
                || !self.isAllowGif && assetModel.subType == .gif
                || allowPickingVideo && Int(assetModel.timeLength) ?? self.maxVideoTime + 1 > self.maxVideoTime
                || assetModel.subType == .gif && (assetModel.pixH < 200 && assetModel.pixW < 200) {
                return
            }
            
            assets.append(assetModel)
        }
        
        DispatchQueue.main.async {
            callback(assets)
        }
    }
    
    /// 获取所有的Asset
    ///
    /// - Parameters:
    ///   - allowPickingVideo: 是否筛选视频
    ///   - allowPickingImage: 是否筛选图片
    ///   - callback: 回调
    public func getAllAssetOfAlbum(allowPickingVideo: Bool,
                                   allowPickingImage: Bool,
                                   callback: @escaping (([ZDAssetModel]) -> Void)) {
        getAllAlbums(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (albums) in
            for album in albums {
                self.getAllAssetOfAlbum(model: album, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (assets) in
                    DispatchQueue.main.async {
                        callback(assets)
                    }
                }
            }
        }
    }
    
    /// 获取照片
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - targetSize: 尺寸
    ///   - callback: 回调
    public func getPhoto(asset: PHAsset,
                         targetSize: CGSize,
                         callback: @escaping (UIImage?, [AnyHashable : Any]?)-> Void) {
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option) { (result, info) in
            
            //  如果字典为空 直接返回
            guard let dict = info else {
                DispatchQueue.main.async {
                    callback(result, nil)
                }
                return
            }
            
            /*
            for (key, value) in dict.enumerated() {
                print("key: \(key)")
                print("value: \(value)")
            }
            */
            
            let downloadFinined = (dict[PHImageCancelledKey] != nil) && ((dict[PHImageCancelledKey] as! NSNumber) != 1) && (dict[PHImageErrorKey] != nil) && (dict[PHImageResultIsDegradedKey] as! NSNumber != 1)
            
            //  如果CancelKey存在且为false 并且error不为空 返回闭包
            if downloadFinined {
                DispatchQueue.main.async {
                    callback(result, dict)
                }
            //  如果iCloud有值,同时result为空 那么需要从iCloud进行下载
            }else if let _ = dict[PHImageResultIsInCloudKey], result == nil {
                option.isNetworkAccessAllowed = true
                PHImageManager.default().requestImageData(for: asset, options: option, resultHandler: { (data, dataUTI, orientation, infomation) in
                    guard let imageData = data, let iCouldImage = UIImage(data: imageData, scale: 0.05)  else {
                        DispatchQueue.main.async {
                            callback(nil, infomation)
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        callback(iCouldImage, infomation)
                    }

                })
            }else {
                DispatchQueue.main.async {
                    callback(result, info)
                }
            }
        }
    }
    
    /// 获取Gif
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - callback: 回调
    public func getGif(asset: PHAsset, callback: @escaping ((Data?, UIImage?) -> Void)) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        
        PHImageManager.default().requestImageData(for: asset, options: option) { (data, dataUTI, orientation, dict) in
            if let imageData = data {
                let image = UIImage.gif(data: imageData)
                DispatchQueue.main.async {
                    callback(imageData, image)
                }

            }else {
                DispatchQueue.main.async {
                    callback(data, nil)
                }
            }
        }
    }
    
    /// 获取视频
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - callback: 回调
    public func getVideo(asset: PHAsset, callback: @escaping ((URL?, UIImage?) -> Void)) {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: option) { (asset, audioMix, info) in
            guard let avAsset = asset else {
                DispatchQueue.main.async {
                    callback(nil, nil)
                }
                return
            }
            
            let assetImageGenerator = AVAssetImageGenerator(asset: avAsset)
            assetImageGenerator.appliesPreferredTrackTransform = true
            let time = CMTimeMakeWithSeconds(0, preferredTimescale: 1)
            var actualTime = CMTime()
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: &actualTime)
                let image = UIImage(cgImage: cgImage)
                self.compressVideoOrLivePhoto(asset: avAsset, callback: { (path) in
                    DispatchQueue.main.async {
                        callback(path, image)
                    }
                })
            }catch let error {
                print(error)
                DispatchQueue.main.async {
                    callback(nil, nil)
                }
            }
            
        }
    }
    
    /// 获取livePhoto, 回调的url有问题 为空
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - targetSize: 尺寸
    ///   - callback: 回调
    public func getLivePhoto(asset: PHAsset,
                             targetSize: CGSize,
                             callback: @escaping (PHLivePhoto?, UIImage?, URL?)-> Void) {
        let option = PHLivePhotoRequestOptions()
        option.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .default, options: option) { (livePhoto, dict) in

            /*
             dict的信息 (key: AnyHashable("PHImageResultIsDegradedKey"), value: 1)
             */
            
            /// 这个回调的url有的为空,有的不为空,为空可能是因为livePhoto中并没有视频
            DispatchQueue.main.async {
                callback(livePhoto, livePhoto?.value(forKey: "image") as? UIImage, (livePhoto?.value(forKey: "videoAsset") as? AVURLAsset)?.url)
            }
        }
    }
    
    /// 压缩视频与livePhoto
    ///
    /// - Parameters:
    ///   - asset: 资源
    ///   - isVideo: 是否是视频 默认是视频
    ///   - callback: 回调
    public func compressVideoOrLivePhoto(asset: AVAsset,
                                         isVideo: Bool = true,
                                         callback: @escaping ((URL?) -> Void)) {
        let lastPath = isVideo ? "/outAssetVideo.mp4" : "/outAssetLivePhoto.mp4"
        
        let outPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + lastPath
        let outVideoUrl = URL(fileURLWithPath: outPath)
        
        //MARK:- UnsafePointer<Int8>是一个C字符串 String -> NSString -> UnsafePointer
        //  删除旧文件
        let cOutPath = (outPath as NSString).utf8String
        let buffer = UnsafePointer<Int8>(cOutPath)
        unlink(buffer)
        
        let start = CMTimeMakeWithSeconds(0, preferredTimescale: asset.duration.timescale)
        let range = CMTimeRangeMake(start: start, duration: asset.duration)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            callback(nil)
            return
        }
        exportSession.outputURL = outVideoUrl
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .failed, .cancelled:
                callback(nil)
            case .completed:
                callback(outVideoUrl)
            default:
                callback(nil)
            }
        }
    }
    
    /// 获得一组照片的大小
    ///
    /// - Parameters:
    ///   - models: 照片模型
    ///   - callback: 回调
    public func getPhotosSize(models: [ZDAssetModel], callback: @escaping (String, Int) -> Void) {
        
        let imageOption = PHImageRequestOptions()
        imageOption.resizeMode = .fast
        
        let videoOption = PHVideoRequestOptions()
        videoOption.isNetworkAccessAllowed = true
        
        var dataCount: Int = 0
        
        for model in models {
            if model.type == .photo {
                PHImageManager.default().requestImageData(for: model.asset, options: imageOption) { (data, dataUTI, orientation, dict) in
                    if let imageData = data {
                        dataCount += imageData.count
                    }
                    let dataString = self.getBytes(dataCount: dataCount)
                    
                    DispatchQueue.main.async {
                        callback(dataString, dataCount)
                    }
                }
            }else {
                PHImageManager.default().requestAVAsset(forVideo: model.asset, options: videoOption) { (asset, audioMix, info) in
                    guard let avAsset = asset, let avUrlAsset = avAsset as? AVURLAsset else {
                        DispatchQueue.main.async {
                            callback("", 0)
                        }
                        return
                    }
                    
                    do {
                        let videoData = try Data(contentsOf: avUrlAsset.url)
                        dataCount += videoData.count
                        let dataString = self.getBytes(dataCount: dataCount)
                        DispatchQueue.main.async {
                            callback(dataString, dataCount)
                        }
                    }catch {
                        DispatchQueue.main.async {
                            callback("", 0)
                        }
                    }
                }
            }
        }
    }
    
    func showAlert(controller: UIViewController, message: String? = nil) {
        //弹出提示
        let title = message ?? "你最多只能选择\(maxSelected)张照片"
        
        // 原生UIAlertController 我这个并没有使用第三方是为了避免耦合 当然这里可以搞个闭包 让用户自定义
        let alertController = UIAlertController(title: title, message: nil,
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title:"我知道了", style: .cancel,
                                         handler:nil)
        alertController.addAction(cancelAction)
        controller.present(alertController, animated: true, completion: nil)
    }
}

extension ZDPhotoManager {
    
    /// 获取ZDAlbumModel
    ///
    /// - Parameters:
    ///   - result: 资源数组
    ///   - name: 相册名
    /// - Returns: ZDAlbumModel
    private func getZDAlbumModel(result: PHFetchResult<PHAsset>, name: String) -> ZDAlbumModel {
        
        let model = ZDAlbumModel()
        model.result = result
        model.name = titleOfAlbumForChinese(title: name)
        
        var count = 0
        result.enumerateObjects { (asset, index, nil) in
            var type: ZDAssetType = .photo
            var subType: ZDAssetSubType = .normal
            
            //  获取资源类型
            if asset.mediaType == .image {
                type = .photo
            }else if asset.mediaType == .video {
                type = .video
            }
            
            //  获取资源子类型
            if asset.mediaSubtypes == .photoLive {
                subType = .live
            }
            
            let assetModel = ZDAssetModel.creat(asset: asset, type: type, subType: subType)
            
            if !self.isAllowVideo && assetModel.type == .video
                || !self.isAllowLive && assetModel.subType == .live
                || !self.isAllowGif && assetModel.subType == .gif {
                return
            }
            count = count + 1
        }
        model.count = count
        
        return model
    }
    
    /// 由于系统返回的相册集名称为英文转换为中文
    ///
    /// - Parameter title: 英文
    /// - Returns: 中文
    private func titleOfAlbumForChinese(title: String) -> String {
        if title == "Slo-mo" {
            return "慢动作"
        } else if title == "Recently Added" {
            return "最近添加"
        } else if title == "Favorites" {
            return "个人收藏"
        } else if title == "Recently Deleted" {
            return "最近删除"
        } else if title == "Videos" {
            return "视频"
        } else if title == "All Photos" {
            return "所有照片"
        } else if title == "Selfies" {
            return "自拍"
        } else if title == "Screenshots" {
            return "屏幕快照"
        } else if title == "Camera Roll" {
            return "相机胶卷"
        } else if title == "Animated" {
            return "GIF"
        } else if title == "Live Photos" {
            return "实况照片"
        } else if title == "Panoramas" {
            return "全景照片"
        } else if title == "Long Exposure" {
            return "过曝"
        } else if title == "Bursts" {
            
        } else {
            
        }
        return title
    }
    
    /// 将获取的数据长度转为字符串
    ///
    /// - Parameter dataCount: 数据长度
    /// - Returns: 数据字符串
    private func getBytes(dataCount: Int) -> String {
        let bytes: String
        if dataCount >= Int(0.1 * 1024 * 1024) {
            bytes = String(format: "%0.1fM",Double(dataCount) / 1024 / 1024.0)
        }else if dataCount >= 1024 {
            bytes = String(format: "%0.0fK",Double(dataCount)/1024.0)
        }else {
            bytes = String(format: "%zdB", dataCount)
        }
        return bytes
    }
}
