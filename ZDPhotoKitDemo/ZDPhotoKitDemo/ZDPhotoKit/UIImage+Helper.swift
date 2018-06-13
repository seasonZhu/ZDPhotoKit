//
//  UIImage+Helper.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/2/23.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

// MARK: - UIImage分类
extension UIImage {
    /// 图片的最大的大小 1KB = 8bit, 1M = 1024KB
    static let maxDataSizeKBytes = Int(1.5 * 1024 * 8)
    
    /// for循环压缩图片
    ///
    /// - Parameters:
    ///   - originalImage: 原始图片
    ///   - maxDataSizeKBytes: 最大的KB数
    ///   - callback: 闭包
    class func compress(originalImage: UIImage,
                        maxDataSizeKBytes: Int,
                        callback: @escaping (_ data: Data, _ image: UIImage) -> ()) {
        DispatchQueue.global().async {
            var data = UIImageJPEGRepresentation(originalImage, 1.0)
            guard var dataKBytes = data?.count else { return }
            print("原始的数据大小: \(dataKBytes)")
            var maxQuality: CGFloat = 0.99
            while dataKBytes > maxDataSizeKBytes && maxQuality > 0.02 {
                maxQuality = maxQuality - 0.02
                data = UIImageJPEGRepresentation(originalImage, maxQuality)
                dataKBytes = (data?.count)!
                print("压缩的数据大小: \(dataKBytes)")
                print("压缩质量: \(maxQuality)")
            }
            DispatchQueue.main.async {
                guard let finalData = data else { return }
                guard let image = UIImage(data: finalData) else { return }
                callback(finalData, image)
            }
        }
    }
    
    /// 二分法压缩图片
    ///
    /// - Parameters:
    ///   - image: 原图
    ///   - maxLength: 压缩的byte大小
    /// - Returns: 返回 压缩后的图片 压缩后图片的数据
    class func compressImage(image: UIImage,
                             maxDataSizeKBytes: Int) -> (image: UIImage, imageData: Data) {
        var compression: CGFloat = 1
        var data = UIImageJPEGRepresentation(image, compression)
        var dataBytes = data!.count
        if dataBytes < maxDataSizeKBytes { return (image, data!) }
        
        // Compress by size
        var max: CGFloat = 1
        var min: CGFloat = 0
        for i in 0..<6 {
            compression = (max + min) / 2
            data = UIImageJPEGRepresentation(image, compression)!
            dataBytes = data!.count
            print("第\(i)次压缩,系数=\(compression),图片大小\(dataBytes/1024)kb")
            if(dataBytes<maxDataSizeKBytes){ break }
            
            if dataBytes < Int(Double(maxDataSizeKBytes) * 0.9) {
                min = compression
            } else if dataBytes > maxDataSizeKBytes {
                max = compression
            } else {
                break
            }
        }
        let resultImage: UIImage = UIImage(data: data!)!
        return (resultImage, data!)
    }
    
    /// 压缩图片
    func compressImage(maxDataSizeKB: CGFloat) -> Data{
        var resData:Data = UIImageJPEGRepresentation(self, 1)!
        let resDataSizeKB:CGFloat=CGFloat(resData.count/1024)
        if(resDataSizeKB<maxDataSizeKB){ return resData }
        
        let rate=resDataSizeKB/maxDataSizeKB
        var compression=1-0.05*rate
        for i in 0...10{
            resData = UIImageJPEGRepresentation(self, compression)!
            if(CGFloat(resData.count/1024) < maxDataSizeKB){return resData}
            if(compression <= 0.45) {return resData}
            compression -= (rate-CGFloat(i+1))*0.025
        }
        return resData
    }
    
    /// 自动缩放到指定大小
    ///
    /// - Parameters:
    ///   - image: 需要处理的图片
    ///   - size: 制定尺寸
    /// - Returns: 返回新生成的图片
    class func thumbnailImage(_ image: UIImage?, size: CGSize) -> UIImage? {
        if  image == nil {
            return nil
        }else {
            UIGraphicsBeginImageContext(size)
            image!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
    }
    
    /// 图片按比例缩放
    ///
    /// - Parameters:
    ///   - image: 需要处理的图片
    ///   - scale: 系数
    /// - Returns: 返回新生成的图片
    class func scaleImage(_ image: UIImage?, scale: CGFloat) -> UIImage? {
        if  image == nil {
            return nil
        }else {
            let size = image?.size
            UIGraphicsBeginImageContext(size!)
            image!.draw(in: CGRect(x: 0, y: 0, width: size!.width * scale, height: size!.height * scale))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }
    }
    
    /// 切割图片
    ///
    /// - Parameters:
    ///   - rect: 切割的范围
    /// - Returns: 切割后的图片
    func clipImage(rect: CGRect) -> UIImage {
        let imageRef = cgImage!.cropping(to: rect)
        let thumbScale = UIImage(cgImage: imageRef!)
        return thumbScale
    }
    
    /// 根据比例切割图片
    ///
    /// - Parameter scale: 缩放比例
    func clipSquareImage(scale: CGFloat) -> UIImage {
        let width = size.width
        let height = self.size.height
        let rect = CGRect(x: (width - width / scale) / 2,
                          y: height / 2 - width / scale / 2,
                          width: width / scale,
                          height: width / scale)
        let imagePartRef = cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imagePartRef!)
        return image
    }
    
    /// 获取视频第一帧图片
    ///
    /// - Parameter videoURL: 视频URL
    /// - Returns: 返回第一帧图片
    class func getFirstPicture(frome videoURL: String) -> UIImage? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: videoURL), options: nil)
        let root = AVAssetImageGenerator(asset: asset)
        root.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(0.0, 600)
        var actualTime = CMTime()
        var thumb: UIImage?
        do {
            let image = try root.copyCGImage(at: time, actualTime: &actualTime)
            thumb = UIImage(cgImage: image)
        }catch {
            
        }
        return thumb
    }
    
    /// 规范化图片
    ///
    /// - Parameter image: 原图片
    /// - Returns: 新图片
    class func normalizedImage(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage!
    }
    
    /// 通过颜色生成图片
    ///
    /// - Parameters:
    ///   - color: 颜色
    ///   - size: 宽高
    /// - Returns: 新图片
    class func getImageFromeColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor);
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    /// 打水印
    ///
    /// - Parameters:
    ///   - logo: 水印图片
    ///   - originImage: 原图片
    /// - Returns: 新图片
    class func waterMark(logo: UIImage, originImage: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(originImage.size, false, 0.0)
        originImage.draw(in: CGRect(x: 0, y: 0, width: originImage.size.width, height: originImage.size.height))
        
        let scale: CGFloat = 1.5;
        let margin: CGFloat = 10;
        let waterW = logo.size.width * scale;
        let waterH = logo.size.height * scale;
        let waterX = originImage.size.width - waterW - margin;
        let waterY = originImage.size.height - waterH - margin;
        logo.draw(in: CGRect(x: waterX, y: waterY, width: waterW, height: waterH))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        
        return newImage!
    }
}

extension UIImage {
    
    /// 图片画圆角
    ///
    /// - Parameter radius: 圆角长度
    /// - Returns: 新图片
    func drawCornerRadius(_ radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        UIGraphicsGetCurrentContext()!.addPath(path)
        UIGraphicsGetCurrentContext()!.clip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension UIImage{
    
    /// 高斯模糊
    ///
    /// - Parameter ratio: 模糊系数
    /// - Returns: 返回模糊图片
    func blur(ratio: Int = 50) -> UIImage {
        let inputImage =  CIImage(image: self)
        let context = CIContext(options: nil)
        //使用高斯模糊滤镜
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(inputImage, forKey:kCIInputImageKey)
        //设置模糊半径值（越大越模糊）
        filter.setValue(ratio, forKey: kCIInputRadiusKey)
        let outputCIImage = filter.outputImage!
        let rect = CGRect(origin: CGPoint.zero, size: self.size)
        let cgImage = context.createCGImage(outputCIImage, from: rect)
        //显示生成的模糊图片
        return UIImage(cgImage: cgImage!)
    }
    
}

extension UIImage{
    
    //  水印位置枚举
    enum WaterMarkCorner{
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    //  添加水印方法
    func waterMarkedImage(waterMarkText:String, corner:WaterMarkCorner = .bottomRight,
                          margin:CGPoint = CGPoint(x: 20, y: 20),
                          waterMarkTextColor:UIColor = UIColor.white,
                          waterMarkTextFont:UIFont = UIFont.systemFont(ofSize: 20),
                          backgroundColor:UIColor = UIColor.clear) -> UIImage {
        
        let textAttributes = [NSAttributedStringKey.foregroundColor:waterMarkTextColor,
                              NSAttributedStringKey.font:waterMarkTextFont,
                              NSAttributedStringKey.backgroundColor:backgroundColor]
        let textSize = NSString(string: waterMarkText).size(withAttributes: textAttributes)
        var textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        
        let imageSize = self.size
        switch corner{
        case .topLeft:
            textFrame.origin = margin
        case .topRight:
            textFrame.origin = CGPoint(x: imageSize.width - textSize.width - margin.x, y: margin.y)
        case .bottomLeft:
            textFrame.origin = CGPoint(x: margin.x, y: imageSize.height - textSize.height - margin.y)
        case .bottomRight:
            textFrame.origin = CGPoint(x: imageSize.width - textSize.width - margin.x,
                                       y: imageSize.height - textSize.height - margin.y)
        }
        
        // 开始给图片添加文字水印
        UIGraphicsBeginImageContext(imageSize)
        self.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        NSString(string: waterMarkText).draw(in: textFrame, withAttributes: textAttributes)
        
        let waterMarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return waterMarkedImage!
    }
}

extension UIImage {
    
    /// 将文字绘制为图片
    ///
    /// - Parameters:
    ///   - text: 需要绘制的文本
    ///   - textColor: 文本颜色
    ///   - textFont: 文本的字号
    ///   - backgroundColor: 文本的背景颜色
    /// - Returns: 返回图片
    class func stringDrawToImage(string: String,
                                 textColor:UIColor = UIColor.black,
                                 textFont:UIFont = UIFont.systemFont(ofSize: 15),
                                 lineSapcing: CGFloat = 0,
                                 backgroundColor: UIColor = UIColor.clear) -> UIImage {
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSapcing
        
        let textAttributes = [NSAttributedStringKey.foregroundColor:textColor,
                              NSAttributedStringKey.font:textFont,
                              NSAttributedStringKey.backgroundColor:backgroundColor,
                              NSAttributedStringKey.paragraphStyle: paragraph]
        
        let textSize = NSString(string: string).size(withAttributes: textAttributes)
        let textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        let stringImage = UIImage()
        
        UIGraphicsBeginImageContextWithOptions(textSize, false, UIScreen.main.scale)
        stringImage.draw(in: CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height))
        NSString(string: string).draw(in: textFrame, withAttributes: textAttributes)
        
        let drawImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return drawImage!
    }
    
    /// 将富文本绘制为图片,该API暂时功能有问题
    ///
    /// - Parameters:
    ///   - text: 需要绘制的文本
    ///   - textColor: 文本颜色
    ///   - textFont: 文本的字号
    ///   - backgroundColor: 文本的背景颜色
    /// - Returns: 返回图片
    class func attrStringDrawToImage(attrStr: NSMutableAttributedString,
                                     textColor:UIColor = UIColor.black,
                                     textFont:UIFont = UIFont.systemFont(ofSize: 17),
                                     lineSapcing: CGFloat = 0,
                                     backgroundColor: UIColor = UIColor.clear) -> UIImage {
        
        let paragraph = NSMutableParagraphStyle()
        //paragraph.lineSpacing = attrStr.yy_lineSpacing
        
        let textAttributes = [NSAttributedStringKey.foregroundColor:textColor,
                              NSAttributedStringKey.font:textFont,
                              NSAttributedStringKey.backgroundColor:backgroundColor,
                              NSAttributedStringKey.paragraphStyle: paragraph]
        
        attrStr.addAttributes(textAttributes, range: NSRange.init(location: 0, length: attrStr.length))
        
        let textSize = attrStr.size()
        let textFrame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        let stringImage = UIImage()
        
        
        UIGraphicsBeginImageContextWithOptions(textSize, false, UIScreen.main.scale)
        stringImage.draw(in: CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height))
        attrStr.draw(with: textFrame, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        
        let drawImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return drawImage!
    }
}

extension UIImage {
    
    /// 将图层绘制为图片
    ///
    /// - Parameter view: 图层
    /// - Returns: image
    class func viewDrawToImage(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let drawImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return drawImage
    }
    
    /// scrollView绘制为图片
    ///
    /// - Parameter scrollView: scrollView
    /// - Returns: image
    class func scrollViewDrawToImage(scrollView: UIScrollView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, false, UIScreen.main.scale)
        let savedContentOffset = scrollView.contentOffset
        let savedFrame = scrollView.frame
        
        scrollView.contentOffset = CGPoint.zero
        scrollView.frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        
        scrollView.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        
        scrollView.contentOffset = savedContentOffset;
        scrollView.frame = savedFrame;
        
        UIGraphicsEndImageContext()
        return image
    }
}

