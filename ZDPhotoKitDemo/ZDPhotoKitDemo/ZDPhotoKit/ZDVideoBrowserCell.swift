//
//  ZDVideoBrowserCell.swift
//  JiuRongCarERP
//
//  Created by qinbo on 2018/6/5.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit

/// 预览控制器 视频预览cell
class ZDVideoBrowserCell: UICollectionViewCell {
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
    var dismissCallback: (() -> ()) = { }
    
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
        scrollView.addSubview(videoView)
        
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //  重置单元格内元素尺寸
    func resetSize(){
        //  scrollView重置，不缩放
        scrollView.zoomScale = 1.0
        if let image = videoView.image {
            videoView.frame.size = scaleSize(size: image.size)
            videoView.center = scrollView.center
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
        dismissCallback()
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
//        if player != nil {
//            playerLayer?.removeFromSuperlayer()
//            playerLayer = nil
//            player?.pause()
//            player = nil
//        }
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        ZDPhotoManager.default.getVideo(asset: model.asset) { (url, image) in
            self.videoView.isHidden = false
            self.videoView.image = image
            guard let videoUrl = url else { return }
            
            let playItem = AVPlayerItem(url: videoUrl)
            ZDPlayerManager.default.player = AVPlayer(playerItem: playItem)
            self.playerLayer = AVPlayerLayer(player: ZDPlayerManager.default.player)
            self.playerLayer?.frame = self.bounds
            self.videoView.layer.addSublayer(self.playerLayer!)
            self.player?.play()
            
        }
    }
    
    //MARK:- 准备复用前的工作
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player?.pause()
        player = nil
    }
    
    
    deinit {
        print("ZDVideoBrowserCell销毁了")
    }
}

//  ImagePreviewCell的UIScrollViewDelegate代理实现
extension ZDVideoBrowserCell: UIScrollViewDelegate {
    
    //  缩放视图
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return videoView
    }
    
    //  缩放响应，设置imageView的中心位置
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var centerX = scrollView.center.x
        var centerY = scrollView.center.y
        centerX = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2 : centerX
        centerY = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2 : centerY
        JRLog("\(centerX,centerY)")
        
        videoView.center = CGPoint(x: centerX, y: centerY)
    }
}


