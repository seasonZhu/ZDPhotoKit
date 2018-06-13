//
//  ImageManager.swift
//  JiuRongCarERP
//
//  Created by HSGH on 2018/2/9.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import Photos
import PhotosUI

class ImageManager {
    
    //  单例
    static let `default` = ImageManager()
    private init() {}
    
    //  带缓存的图片管理对象
    private var imageManager = PHCachingImageManager.default()
    
    func getAllAlbums(includVideo: Bool = true,
                      callback: @escaping (_ : [ImageAlbumItem]) -> ()) {
        
        PHPhotoLibrary.requestAuthorization({ (status) in
            if status != .authorized {
                return
            }
            
            //  列出所有系统的智能相册
            let smartOptions = PHFetchOptions()
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                      subtype: .albumRegular,
                                                                      options:smartOptions)
            let smartAlbumsItems = self.convertCollection(collections: smartAlbums, includVideo: includVideo)
            
            //  列出所有用户创建的相册
            let userAlbums = PHCollectionList.fetchTopLevelUserCollections(with: nil)
            let userAlbumsItems = self.convertCollection(collections: userAlbums
                as! PHFetchResult<PHAssetCollection>, includVideo: includVideo)
            
            //  合并所有相册
            var items = smartAlbumsItems + userAlbumsItems
            
            //  相册按包含的照片数量排序（降序）
            items = items.sorted { (item1, item2) -> Bool in
                return item1.fetchResult.count > item2.fetchResult.count
            }
            
            DispatchQueue.main.async {
                callback(items)
            }
        })
    }
    
    /// 获取普通照片
    ///
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - targetSize: 图片大小
    ///   - callback: 回调
    func getPhoto(asset: PHAsset,
                      targetSize: CGSize,
                      callback: @escaping (_ image: UIImage?)-> ()) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: option) { (image, dict) in
            DispatchQueue.main.async {
                callback(image)
            }
        }
    }
    
    /// 获取LivePhoto
    ///
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - targetSize: 图片大小
    ///   - callback: 回调
    func getLivePhoto(asset: PHAsset,
                      targetSize: CGSize,
                      callback: @escaping (_ livePhoto: PHLivePhoto?, _ image: UIImage?)-> ()) {
        let option = PHLivePhotoRequestOptions()
        option.isNetworkAccessAllowed = true
        imageManager.requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .default, options: option) { (livePhoto, dict) in
            if livePhoto != nil && dict != nil {
                let image = livePhoto!.value(forKey: "image") as! UIImage
                DispatchQueue.main.async {
                    callback(livePhoto!, image)
                }
            }else {
                DispatchQueue.main.async {
                    callback(nil, nil)
                }
            }
        }
    }
    
    /// 是否是GIF
    ///
    /// - Parameter asset: PHAsset
    /// - Returns: Bool值
    func isGIF(asset: PHAsset) -> Bool {
        let fileName = asset.value(forKey: "filename") as! NSString
        let extStr = fileName.pathExtension as String
        if extStr == "GIF" {
            print("是GIF")
            return true
        }
        return false
    }
    
    /// 获取GIF 数据
    ///
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - callback: 回调
    func getGIF(asset: PHAsset,
                callback: @escaping (_ data: Data?, _ image: UIImage?)-> ()) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        imageManager.requestImageData(for: asset, options: option) { (data, dataUTI, orientation, dict) in
            
            guard let data = data/*, let dict = dict*/ else {return callback(nil, nil)}
            /*
            dump(dict["PHImageFileURLKey"] as! URL)
            let url = dict["PHImageFileURLKey"] as! URL
            let urlString = url.absoluteString
            */
            let image = UIImage.gif(data: data)
            DispatchQueue.main.async {
                callback(data, image)
            }
            
        }
    }
    
    /// 获取video
    ///
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - progressHandler: 进度回调
    ///   - callback: 回调
    func getVideo(asset: PHAsset,
                  progressHandler: ((_ progress: Double?, _ error: Error?, _ stop: UnsafeMutablePointer<ObjCBool>, _ info: [AnyHashable: Any]?) -> ())? = nil,
                  callback: @escaping (_ playItem: AVPlayerItem?, _ info: [AnyHashable: Any]?) -> ()) {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { progress, error, stop, info in
            DispatchQueue.main.async {
                progressHandler?(progress, error, stop, info)
            }
        }
        
        imageManager.requestPlayerItem(forVideo: asset, options: option) { (playItem, info) in
            DispatchQueue.main.async {
                callback(playItem, info)
            }
        }
    }
    
    /// 由于系统返回的相册集名称为英文转换为中文
    ///
    /// - Parameter title: 英文
    /// - Returns: 中文
    func titleOfAlbumForChinse(title: String?) -> String? {
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
        } else if title == "Bursts" {
            return "连拍"
        }
        return title
    }
    
    
    /// 获取相册合集的内部方法
    ///
    /// - Parameters:
    ///   - collections: PHFetchResult<PHAssetCollection>的集合
    ///   - includVideo: 是否包含视频
    /// - Returns: ImageAlbumItem的数据集合
    private func convertCollection(collections: PHFetchResult<PHAssetCollection>,
                                   includVideo: Bool) -> [ImageAlbumItem] {
        
        var items = [ImageAlbumItem]()
        
        for i in 0..<collections.count{
            //  获取出当前相簿内的图片
            //  这段正则是只筛选出照片 options改为 resultsOptions即可
            let resultsOptions = PHFetchOptions()
            
            resultsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                               ascending: false)]
            resultsOptions.predicate = NSPredicate(format: "mediaType = %d",
                                                   PHAssetMediaType.image.rawValue)
            
            let options = includVideo == true ? nil : resultsOptions
            
            let collection = collections[i]
            let assetsFetchResult = PHAsset.fetchAssets(in: collection , options: options)
            
            //  没有图片的空相簿不显示 最近删除的相薄不显示
            if assetsFetchResult.count > 0
                && collection.localizedTitle != "Recently Deleted"{
                
                let title = titleOfAlbumForChinse(title: collection.localizedTitle)
                
                var itemImage: UIImage?
                
                self.getPhoto(asset: assetsFetchResult.firstObject!, targetSize: CGSize(width: 60, height: 60), callback: { (image) in
                    guard let image = image else { return }
                    guard image.size.width > 45 && image.size.height > 45 else { return }
                    itemImage = image
                    print(image.size.width,image.size.height)
                    items.append(ImageAlbumItem(title: title,
                                                fetchResult: assetsFetchResult,
                                                image: itemImage))
                })
            }
        }
        
        return items
    }
    
    deinit {
        print("ImageManager销毁了")
    }
}

