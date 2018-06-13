//
//  ZDAlbumListViewCell.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 相册列表cell
class ZDAlbumListViewCell: UITableViewCell {
    
    //MARK:- 属性设置
    
    var selectAssets = [ZDAssetModel]()
    
    private let kSelectedLabel = 999
    
    /// 相册封面图
    private lazy var photoView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    /// 相册名称
    private lazy var photoName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    /// 相册的相册数量
    private lazy var photoNum: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    /// 相册 啥?
    private lazy var numIcon = UIImageView()
    
    /// 被选择的Label
    private lazy var selectedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.backgroundColor = UIColor.lightGreen
        label.tag = kSelectedLabel
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.font = UIFont.systemFont(ofSize: 15)
        label.layer.masksToBounds = true
        return label
    }()
    
    /// 模型
    private var newModel = ZDAlbumModel()
    
    var model: ZDAlbumModel {
        set {
            
            if newValue.asset == nil {
                newValue.asset = newValue.result.lastObject
                newValue.albumImage = nil
            }
            
            if newValue.albumImage != nil {
                photoView.image = newValue.albumImage
            }else {
                ZDPhotoManager.default.getPhoto(asset: newValue.asset ?? PHAsset(), targetSize: CGSize(width: 60, height: 60), callback: { (image, dict) in
                    self.photoView.image = image
                    newValue.albumImage = image
                })
            }
            
            self.selectedLabel.text = "\(newValue.selectCount)"
            self.selectedLabel.isHidden = newValue.selectCount == 0
            
            photoName.text = newValue.name
            
            photoNum.text = "\(newValue.count)"
            
            numIcon.isHighlighted = newValue.count > 0 ? false : true
            
            newModel = newValue
        }get {
            return newModel
        }
    }
    
    //MARK:- 初始化
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        contentView.addSubview(photoView)
        contentView.addSubview(photoName)
        contentView.addSubview(photoNum)
        photoView.addSubview(numIcon)
        contentView.addSubview(selectedLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = frame.size.width
        let height = frame.size.height
        
        photoView.frame = CGRect(x: 10, y: 5, width: 50, height: 50)
        
        let photoNameX = self.photoView.frame.maxX + 10;
        var photoNameWith: CGFloat = 100
        if photoNameWith > width - photoNameX - 50 {
            photoNameWith = width - photoNameX - 50
        }
        photoName.frame = CGRect(x: photoNameX, y: 0, width: photoNameWith, height: 18)
        photoName.center = CGPoint(x: photoName.center.x, y: height / 2)
        
        let photoNumX = photoName.frame.maxX + 5;
        let photoNumWidth = frame.width - photoName.frame.maxX + 5 - 20
        photoNum.frame = CGRect(x: photoNumX, y: 0, width: photoNumWidth, height: 15)
        photoNum.center = CGPoint(x: self.photoNum.center.x, y: height / 2 + 2)
        
        let numIconX = 50 - 2 - 13
        let numIconY = 2
        let numIconW = 13
        let numIconH = 13
        numIcon.frame = CGRect(x: numIconX, y: numIconY, width: numIconW, height: numIconH);
        
        let selectLabelX = photoNum.frame.maxX - 15
        
        selectedLabel.frame = CGRect(x: selectLabelX, y: 0, width: 20, height: 20)
        selectedLabel.center.y = photoView.frame.midY

    }
   
    //MARK:- 重写select方法
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        for subView in contentView.subviews {
            if subView is UILabel, subView.tag == kSelectedLabel {
                subView.backgroundColor = UIColor.lightGreen
            }
        }

    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDAlbumListViewCell销毁了")
    }
}
