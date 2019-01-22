//
//  ZDExtension.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import Foundation
import Photos

// MARK: - 字符串分类
extension String {
    ///  判断字符串是否包含某些字符串
    func contains(_ find: String, compareOption: NSString.CompareOptions) -> Bool {
        return self.range(of: find, options: compareOption) != nil
    }
}

// MARK: - 数组移除的分类
extension Array where Element: Equatable {
    
    /// 移除数组的某一项
    ///
    /// - Parameter item: 元素
    mutating func removeObject(_ item: Element) {
        self = filter { $0 != item }
    }
}

// MARK: - 针对性移除
extension Array where Element: ZDAssetModel {
    
    /// 针对ZDAssetModel的移除
    ///
    /// - Parameter item: ZDAssetModel
    mutating func removeZDAssetModel(_ item: Element) {
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
    static var lightGreen: UIColor {
        return UIColor(red: 0x09/255, green: 0xbb/255, blue: 0x07/255, alpha: 1)
    }
    
    static var main: UIColor {
        return UIColor(red: 0/255, green: 121/255, blue: 231/255, alpha:1.00)
    }
}

// MARK: - 从ZDPhotoBundle中获取图片
extension UIImage {
    convenience init?(namedInBundle name: String) {
        self.init(named: name, in: ZDPhotoBundle, compatibleWith: nil)
    }
    
    /// 获取视频第一帧图片
    ///
    /// - Parameter videoURL: 视频URL
    /// - Returns: 返回第一帧图片
    static func getFirstPicture(frome videoURL: String) -> UIImage? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: videoURL), options: nil)
        let root = AVAssetImageGenerator(asset: asset)
        root.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        var actualTime = CMTime()
        var thumb: UIImage?
        do {
            let image = try root.copyCGImage(at: time, actualTime: &actualTime)
            thumb = UIImage(cgImage: image)
        }catch {
            
        }
        return thumb
    }
    
    /// 修正图片
    var fixOrientation: UIImage? {
        
        if imageOrientation == .up {
            return self
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = .identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        
        //这里需要注意下CGImageGetBitmapInfo，它的类型是Int32的，CGImageGetBitmapInfo(aImage.CGImage).rawValue，这样写才不会报错
        guard let ctx = CGContext(data: nil,
                                  width: Int(size.width),
                                  height: Int(size.height),
                                  bitsPerComponent: cgImage.bitsPerComponent,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: cgImage.bitmapInfo.rawValue) else {
                                    return nil
        }
        ctx.concatenate(transform)
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            draw(in: CGRect(x: 0, y: 0,  width: self.size.height, height: self.size.width))
        default:
            draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let cgimg = ctx.makeImage() else { return nil }
        let img = UIImage(cgImage: cgimg)
        return img
    }
}
