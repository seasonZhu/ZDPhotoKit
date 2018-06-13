//
//  ImageCollectionViewCell.swift
//  JiuRongCarERP
//
//  Created by dy on 2018/1/16.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class ImageCollectionViewCell: UICollectionViewCell {
    
    //  懒加载一般的imageView
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    //  懒加livePhote
    private var livePhoteView: PHLivePhotoView = {
        let livePhoteView = PHLivePhotoView()
        livePhoteView.isUserInteractionEnabled = true
        livePhoteView.contentMode = .scaleAspectFill
        livePhoteView.clipsToBounds = true
        livePhoteView.isHidden = true
        return livePhoteView
    }()
    
    //  选择
    lazy var selectCellButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "image_not_selected"), for: .normal)
        button.setImage(UIImage(named: "image_selected"), for: .selected)
        button.addTarget(self, action: #selector(selectCellButtonAction(_ :)), for: .touchUpInside)
        return button
    }()
    
    //  左上角 显示是GIF图 还是 Live图片 还是普通的图片 还是视频
    private lazy var upLeftStatusIcon = UIImageView()
    
    //  右下角
    private lazy var bottomRightTimeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 13)
        label.isHidden = true
        return label
    }()
    
    
    /// asset模型
    private var newAsset = PHAsset()
    
    var asset: PHAsset {
        set {
            newAsset = newValue
            
            autoreleasepool {
                statusIconAndTimeLabelSetting(asset: newValue)
                gifAndLivePhotoPlaySetting(asset: newValue)
            }
            
        }get {
            return newAsset
        }
    }
    
    //  gifImage
    private var gifImage: UIImage?
    
    //  点击选择按钮的回调
    var selectCallback: ((_ isSelected: Bool) -> ())?
    
    //MARK: 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 搭建界面
    private func setupUI() {
        //  imageView的布局
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(item: imageView,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: imageView,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .top,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: imageView,
                                         attribute: .trailing,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: imageView,
                                         attribute: .bottom,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .bottom,
                                         multiplier: 1,
                                         constant: 0))
        
        //  imageView的布局
        contentView.addSubview(livePhoteView)
        livePhoteView.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(item: livePhoteView,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: livePhoteView,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .top,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: livePhoteView,
                                         attribute: .trailing,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: livePhoteView,
                                         attribute: .bottom,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .bottom,
                                         multiplier: 1,
                                         constant: 0))
        
        //  selectedView布局
        contentView.addSubview(selectCellButton)
        
        selectCellButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: selectCellButton,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .top,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: selectCellButton,
                                         attribute: .trailing,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: selectCellButton,
                                         attribute: .width,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .width,
                                         multiplier: 1,
                                         constant: 25))
        
        addConstraint(NSLayoutConstraint(item: selectCellButton,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .height,
                                         multiplier: 1,
                                         constant: 25))
        
        //  upLeftStatusIcon布局
        contentView.addSubview(upLeftStatusIcon)
        
        upLeftStatusIcon.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: upLeftStatusIcon,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .top,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: upLeftStatusIcon,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: upLeftStatusIcon,
                                         attribute: .width,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .width,
                                         multiplier: 1,
                                         constant: 25))
        
        addConstraint(NSLayoutConstraint(item: upLeftStatusIcon,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .height,
                                         multiplier: 1,
                                         constant: 25))
        
        //  bottomRightTimeLabel布局
        contentView.addSubview(bottomRightTimeLabel)
        
        bottomRightTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: bottomRightTimeLabel,
                                         attribute: .bottom,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .bottom,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: bottomRightTimeLabel,
                                         attribute: .trailing,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: -3))
        
        addConstraint(NSLayoutConstraint(item: bottomRightTimeLabel,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .height,
                                         multiplier: 1,
                                         constant: 15))
    }
    
    /// 设置左上角的状态与右下角的视频时间
    ///
    /// - Parameter asset: PHAsset
    private func statusIconAndTimeLabelSetting(asset: PHAsset) {
        //  判断是不是视频
        if asset.mediaType == .video {
            upLeftStatusIcon.image = UIImage(named: "photo_mark_video")
            bottomRightTimeLabel.text = getVideoTime(duration: asset.duration)
            bottomRightTimeLabel.isHidden = false
        }else {
            //  不是视频 那么右下角的角标文字隐藏
            bottomRightTimeLabel.text = ""
            bottomRightTimeLabel.isHidden = true
            
            
            if #available(iOS 9.1, *) {
                //  判断是不是GIF
                if ImageManager.default.isGIF(asset: asset) {
                    upLeftStatusIcon.image = UIImage(named: "photo_mark_gif")
                    //  判断是不是LivePhoto
                }else if asset.mediaSubtypes == .photoLive  {
                    upLeftStatusIcon.image = UIImage(named: "photo_mark_live")
                }else {
                    upLeftStatusIcon.image = UIImage()
                }
            } else {
                if ImageManager.default.isGIF(asset: asset) {
                    upLeftStatusIcon.image = UIImage(named: "photo_mark_gif")
                    //  判断是不是LivePhoto
                }else {
                    upLeftStatusIcon.image = UIImage()
                }
            }
        }
    }
    
    /// 设置GIF与LivePhoto的播放
    private func gifAndLivePhotoPlaySetting(asset: PHAsset) {
        if let gestures = imageView.gestureRecognizers {
            for gesture in gestures {
                if gesture.isKind(of: UILongPressGestureRecognizer.self) {
                    imageView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        if let gestures = livePhoteView.gestureRecognizers {
            for gesture in gestures {
                if gesture.isKind(of: UILongPressGestureRecognizer.self) {
                    livePhoteView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        if ImageManager.default.isGIF(asset: asset) {
            imageView.isHidden = false
            livePhoteView.isHidden = true
            gifImage = nil
            
            let longTap = UILongPressGestureRecognizer(target: self, action: #selector(gifStart(_ :)))
            imageView.addGestureRecognizer(longTap)
            
            //  得到GIF的第一帧
            ImageManager.default.getGIF(asset: asset, callback: { (data, image) in
                guard let _ = data, let image = image else { return }
                self.imageView.image = image.images?[0]
                self.gifImage = image
            })
            
        }else if asset.mediaSubtypes == .photoLive  {
            imageView.isHidden = true
            livePhoteView.isHidden = false
            gifImage = nil
            
            //  添加长按手势
            let longTap = UILongPressGestureRecognizer(target: self, action: #selector(livePhotoStart(_ :)))
            livePhoteView.addGestureRecognizer(longTap)
            
            //  得到livePhoto
            ImageManager.default.getLivePhoto(asset: asset, targetSize: bounds.size, callback: { (livePhoto, image) in
                guard let livePhoto = livePhoto, let _ = image  else {return}
                self.livePhoteView.livePhoto = livePhoto
                self.livePhoteView.isMuted = true
                self.livePhoteView.startPlayback(with: .hint)
            })
            
        }else {
            imageView.isHidden = false
            livePhoteView.isHidden = true
            gifImage = nil
            
            ImageManager.default.getPhoto(asset: asset, targetSize: bounds.size, callback: { (image) in
                self.imageView.image = image
            })
        }
    }
    
    
    /// 获取视频时长
    ///
    /// - Parameter duration: 时间
    /// - Returns: 字符串
    private func getVideoTime(duration: TimeInterval) -> String {
        let length = Int(duration)
        let min = length / 60;
        let second = length % 60
        return String(format: "%02ld:%02ld",min,second)
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
    
    /// 长按展示gif
    ///
    /// - Parameter longPress: 长按手势
    @objc private func gifStart(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            imageView.image = gifImage
        }else if longPress.state == .ended {
            imageView.image = nil
            imageView.image = gifImage?.images![0]
            //  这里如果设置为nil的话,那么下次再次长按的话 gifImage为空, 就拿不到数据了,最好的方式是每次按,每次生成,然后每次都进行销毁
            //gifImage = nil
        }
    }
    
    @objc private func selectCellButtonAction(_ button: UIButton) {
        button.isSelected = !button.isSelected
        playAnimation()
        selectCallback?(button.isSelected)
    }
    
    /// 播放动画
    private func playAnimation() {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.selectCellButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                self.selectCellButton.transform = CGAffineTransform.identity
            })
            
        }, completion: nil)
    }
    
    deinit {
        print("ImageCollectionViewCell销毁了")
    }
}
