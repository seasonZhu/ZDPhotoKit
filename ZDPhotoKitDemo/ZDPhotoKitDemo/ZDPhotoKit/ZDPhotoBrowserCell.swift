//
//  ZDPhotoBrowserCell.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/1.
//  Copyright © 2018年 season. All rights reserved.
//


import UIKit
import Photos
import PhotosUI

/// 图片预览的cell
class ZDPhotoBrowserCell: UICollectionViewCell {
    //MARK:- 属性设置
    
    //  滚动视图
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: contentView.bounds)
        scrollView.delegate = self
        
        //  scrollView缩放范围 1~3
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        return scrollView
    }()
    
    //  懒加载一般的imageView
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = scrollView.bounds
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    //  懒加载livePhote
    private lazy var livePhoteView: PHLivePhotoView = {
        let livePhoteView = PHLivePhotoView()
        livePhoteView.frame = scrollView.bounds
        livePhoteView.isUserInteractionEnabled = true
        livePhoteView.contentMode = .scaleAspectFit
        livePhoteView.clipsToBounds = true
        livePhoteView.isHidden = true
        return livePhoteView
    }()
    
    //  还需要一个播放器的图层
    private lazy var videoView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = scrollView.bounds
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()
    
    //  控制器消失的回调
    var dismissCallback: (() -> Void)?
    
    /// asset模型
    private var newAsset = ZDAssetModel()
    
    var asset: ZDAssetModel {
        set {
            newAsset = newValue
            
            autoreleasepool {
                mediaSetting(model: newValue)
            }
            
        }get {
            return newAsset
        }
    }
    
    /// 播放层
    private var player: AVPlayer?
    
    private var playerLayer: AVPlayerLayer?
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(livePhoteView)
        contentView.addSubview(videoView)
        
        //  单击监听
        let tapSingle = UITapGestureRecognizer(target: self, action: #selector(tapSingleDid(_:)))
        tapSingle.numberOfTapsRequired = 1
        tapSingle.numberOfTouchesRequired = 1
        
        //  双击监听
        let tapDouble = UITapGestureRecognizer(target: self, action: #selector(tapDoubleDid(_:)))
        tapDouble.numberOfTapsRequired = 2
        tapDouble.numberOfTouchesRequired = 1
        
        //  声明点击事件需要双击事件检测失败后才会执行
        tapSingle.require(toFail: tapDouble)
        
        contentView.addGestureRecognizer(tapSingle)
        contentView.addGestureRecognizer(tapDouble)
        
//        imageView.addGestureRecognizer(tapSingle)
//        imageView.addGestureRecognizer(tapDouble)
//
//        livePhoteView.addGestureRecognizer(tapSingle)
//        livePhoteView.addGestureRecognizer(tapDouble)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //  重置单元格内元素尺寸
    func resetSize(){
        //  scrollView重置，不缩放
        scrollView.zoomScale = 1.0
        //  imageView重置
        if let image = imageView.image {
            //  设置imageView的尺寸确保一屏能显示的下
            imageView.frame.size = scaleSize(size: image.size)
            //  imageView居中
            imageView.center = scrollView.center
        }
        
        //  livePhoteView重置
        if let livePhoto = livePhoteView.livePhoto {
            //  设置imageView的尺寸确保一屏能显示的下
            livePhoteView.frame.size = scaleSize(size: livePhoto.size)
            //  imageView居中
            livePhoteView.center = scrollView.center
        }
        
        //  视频层的封面图重置
        if let coverImage = videoView.image {
            videoView.frame.size = scaleSize(size: coverImage.size)
            //  imageView居中
            videoView.center = contentView.center
        }
    }
    
    //  获取imageView的缩放尺寸（确保首次显示是可以完整显示整张图片）
    private func scaleSize(size: CGSize) -> CGSize {
        let width = size.width
        let height = size.height
        let widthRatio = width / UIScreen.main.bounds.width
        let heightRatio = height / UIScreen.main.bounds.height
        let ratio = max(heightRatio, widthRatio)
        return CGSize(width: width / ratio, height: height / ratio)
    }
    
    //  图片单击事件响应
    @objc private func tapSingleDid(_ tap: UITapGestureRecognizer) {
        dismissCallback?()
    }
    
    //  图片双击事件响应
    @objc private func tapDoubleDid(_ tap: UITapGestureRecognizer){
        //  缩放视图（带有动画效果）
        UIView.animate(withDuration: 0.5, animations: {
            //如果当前不缩放，则放大到3倍。否则就还原
            if self.scrollView.zoomScale == 1.0 {
                self.scrollView.zoomScale = 3.0
            }else{
                self.scrollView.zoomScale = 1.0
            }
        })
    }
    
    /// 设置GIF/LivePhoto/Video的播放
    private func mediaSetting(model: ZDAssetModel) {
        
        //  对内容进行设置
        
        //  移除手势
        if let gestures = imageView.gestureRecognizers {
            for gesture in gestures {
                if gesture is UILongPressGestureRecognizer {
                    imageView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        if let gestures = livePhoteView.gestureRecognizers {
            for gesture in gestures {
                if gesture is UILongPressGestureRecognizer {
                    livePhoteView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        imageView.image = nil
        livePhoteView.livePhoto = nil
        videoView.image = nil
        
        imageView.isHidden = false
        livePhoteView.isHidden = true
        videoView.isHidden = true
        
        if model.type == .video {
            
            imageView.isHidden = true
            livePhoteView.isHidden = true
            videoView.isHidden = false
            
            if player != nil {
                playerLayer?.removeFromSuperlayer()
                playerLayer = nil
                player?.pause()
                player = nil
            }
            
            ZDPhotoManager.default.getVideo(asset: model.asset) { (url, image) in
                self.videoView.image = image
                guard let videoUrl = url else { return }
                
                let playItem = AVPlayerItem(url: videoUrl)
                self.player = AVPlayer(playerItem: playItem)
                self.playerLayer = AVPlayerLayer(player: self.player)
                self.playerLayer?.frame = self.bounds
                self.videoView.layer.addSublayer(self.playerLayer!)
                self.player?.play()
                
            }
        }else {
            
            imageView.isHidden = false
            livePhoteView.isHidden = true
            videoView.isHidden = true
            
            if model.subType == .gif {
                
                ZDPhotoManager.default.getGif(asset: model.asset) { (data, image) in
                    self.imageView.image = image
                }
            }else if model.subType == .live {
                
                imageView.isHidden = true
                livePhoteView.isHidden = false
                
                //  添加长按手势
                let longTap = UILongPressGestureRecognizer(target: self, action: #selector(livePhotoStart(_ :)))
                livePhoteView.addGestureRecognizer(longTap)
                
                ZDPhotoManager.default.getLivePhoto(asset: model.asset, targetSize: bounds.size) { (livePhoto, image, url) in
                    self.livePhoteView.livePhoto = livePhoto
                    self.livePhoteView.isMuted = true
                    self.livePhoteView.startPlayback(with: .full)
                }
            }else {
                ZDPhotoManager.default.getPhoto(asset: model.asset, targetSize: bounds.size) { (image, dict) in
                    self.imageView.image = image
                }
            }
        }
    }
    
    /// 长按展示LivePhoto
    ///
    /// - Parameter longPress: 长按手势
    @objc private func livePhotoStart(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            livePhoteView.startPlayback(with: .hint)
        }else if longPress.state == .ended {
            livePhoteView.stopPlayback()
        }
    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDPhotoBrowserCell销毁了")
    }
}

//  ImagePreviewCell的UIScrollViewDelegate代理实现
extension ZDPhotoBrowserCell: UIScrollViewDelegate {
    
    //  缩放视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if !imageView.isHidden && livePhoteView.isHidden {
            return imageView
        }else if imageView.isHidden && !livePhoteView.isHidden {
            return livePhoteView
        }else {
            return nil
        }
        
    }
    
    //  缩放响应，设置imageView的中心位置
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerX = scrollView.center.x
        var centerY = scrollView.center.y
        centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2 : centerX
        centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2 : centerY
        print("\(centerX,centerY)")
        
        if !imageView.isHidden && livePhoteView.isHidden {
            imageView.center = CGPoint(x: centerX, y: centerY)
        }else {
            livePhoteView.center = CGPoint(x: centerX, y: centerY)
        }
    }
}

