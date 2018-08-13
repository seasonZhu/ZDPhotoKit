//
//  ZDPhotoCell.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

/// 照片选择cell
class ZDPhotoCell: UICollectionViewCell {
    
    //MARK:- 属性设置
    var onlyRefreshSelectNum: Bool = false
    
    //  懒加载一般的imageView
    private lazy var imageView: UIImageView = {
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
        if ZDPhotoManager.default.isShowSelectCount {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            button.setBackgroundImage(UIImage(namedInBundle: "image_not_selected"), for: .normal)
            
            button.setTitleColor(.white, for: .selected)
            button.setBackgroundImage(UIImage(namedInBundle: "photo_original_select"), for: .selected)
        }else {
            button.setImage(UIImage(namedInBundle: "image_not_selected"), for: .normal)
            button.setImage(UIImage(namedInBundle: "image_selected"), for: .selected)
        }
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
    private var newAsset = ZDAssetModel()
    
    var asset: ZDAssetModel {
        set {
            newAsset = newValue
            
            let asset = newValue.asset
            
            //  对cell的选择按钮 右下 以及左上进行设置
            
            //  选择按钮设置
            selectCellButton.setTitle(nil, for: .selected)
            selectCellButton.isSelected = newValue.isSelect
            if ZDPhotoManager.default.isShowSelectCount {
                selectCellButton.setTitle("\(newValue.selectNum)", for: .selected)
            }
            
            //  右下角设置
            bottomRightTimeLabel.text = getVideoTime(duration: newValue.timeLength)
            bottomRightTimeLabel.isHidden = (newValue.type != .video)
            
            //  左上角设置
            upLeftStatusIcon.image = nil
            
            if newValue.subType == .gif {
                upLeftStatusIcon.image = UIImage(namedInBundle: "photo_mark_gif")
            }else if newValue.subType == .live {
                upLeftStatusIcon.image = UIImage(namedInBundle: "photo_mark_live")
            }else if newValue.type == .video {
                upLeftStatusIcon.image = UIImage(namedInBundle: "photo_mark_video")
            }else if newValue.type == .photo {
                
            }
            
            //  对内容进行设置
            
            //  移除手势
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
            
            imageView.image = nil
            livePhoteView.livePhoto = nil
            livePhoteView.isHidden = true
            
            if newValue.subType == .gif {
                
                //  允许展示Gif 添加长按手势
                if ZDPhotoManager.default.isAllowShowGif {
                    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(gifStart(_ :)))
                    imageView.addGestureRecognizer(longTap)
                }
                
                ZDPhotoManager.default.getGif(asset: asset, callback: { (data, image) in
                    //self.imageView.animatedImage = FLAnimatedImage(gifData: data)
                    //self.imageView.image = image
                    self.imageView.image = image?.images?.first
                })
            }else if newValue.subType == .live {
                
                //  允许展示LivePhoto 添加长按手势
                if ZDPhotoManager.default.isAllowShowLive {
                    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(livePhotoStart(_ :)))
                    livePhoteView.addGestureRecognizer(longTap)
                }
                
                ZDPhotoManager.default.getLivePhoto(asset: asset, targetSize: CGSize(width: 150, height: 150), callback: { (livePhoto, image, url) in
                    if ZDPhotoManager.default.isAllowShowLive {
                        self.livePhoteView.isHidden = false
                        self.livePhoteView.livePhoto = livePhoto
                        self.livePhoteView.isMuted = true
                        self.livePhoteView.startPlayback(with: .full)
                    }else {
                        self.livePhoteView.isHidden = true
                        self.imageView.image = image
                    }

                })
            }else {
                ZDPhotoManager.default.getPhoto(asset: asset, targetSize: CGSize(width: 150, height: 150), callback: { (image, dict) in
                    self.imageView.image = image
                })
            }
            
        }get {
            return newAsset
        }
    }
    
    //  gifImage
    private var gifImage: UIImage?
    
    //  gifData
    private var gifData: Data?
    
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
        
        //  livePhoteView的布局
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
        
        //  selectCellButton布局
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
    
    /// 获取视频时长
    ///
    /// - Parameter duration: 时间
    /// - Returns: 字符串
    private func getVideoTime(duration: String) -> String {
        let length = Int(duration) ?? 0
        let min = length / 60;
        let second = length % 60
        return String(format: "%02ld:%02ld",min,second)
    }
    
    /// 长按展示LivePhoto
    ///
    /// - Parameter longPress: 长按手势
    @objc private func livePhotoStart(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            livePhoteView.startPlayback(with: .full)
        }else if longPress.state == .ended {
            livePhoteView.stopPlayback()
        }
    }
    
    /// 长按展示gif
    ///
    /// - Parameter longPress: 长按手势
    @objc private func gifStart(_ longPress: UILongPressGestureRecognizer) {
        
        //  不使用全局的变量 这样用完了就销毁 内存消耗更少
        
        if longPress.state == .began {
            ZDPhotoManager.default.getGif(asset: asset.asset, callback: { (data, image) in
                //self.imageView.image = nil
                self.imageView.image = image
            })
        }else if longPress.state == .ended {
            ZDPhotoManager.default.getGif(asset: asset.asset, callback: { (data, image) in
                //self.imageView.image = nil
                self.imageView.image = image?.images?.first
            })
        }
    }
    
    /// 选择按钮的点击事件
    ///
    /// - Parameter button: 按钮
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
    
    //MARK:- 析构函数
    deinit {
        print("ZDPhotoCell销毁了")
    }
}
