//
//  ZDPhotoNaviBar.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 图片选择的自定义NavigationBar
class ZDPhotoNaviBar: UIView {

    //MARK:- 属性设置
    let backButton: UIButton
    
    let rightButton: UIButton
    
    let titleButton: ZDPhotoTitleButton
    
    var backButtonCallback: ((UIButton) -> Void)?
    
    var rightButtonCallback: ((UIButton) -> Void)?
    
    var titleButtonCallback: ((ZDPhotoTitleButton) -> Void)?
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        
        let height: CGFloat = 33
        let top = frame.height - height
        let backButton = UIButton(frame: CGRect(x: 0, y: top, width: 70, height: height))
        backButton.setImage(UIImage(namedInBundle: "navigationBar_back"), for: .normal)
        backButton.setImage(UIImage(namedInBundle: "navigationBar_back"), for: .highlighted)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 6.5, left: 7, bottom: 6.5, right: 33)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 0)
        self.backButton = backButton
        
        let rightButton = UIButton(frame: CGRect(x: frame.width - 60, y: top, width: 60, height: height))
        rightButton.setTitleColor(.black, for: .normal)
        rightButton.setTitleColor(.black, for: .highlighted)
        rightButton.setTitle("取消", for: .normal)
        self.rightButton = rightButton
        
        let titleButton = ZDPhotoTitleButton(frame: CGRect(x: backButton.frame.maxX, y: top, width: frame.width - 2.0 * backButton.frame.width, height: height))
        titleButton.setTitleColor(.black, for: .normal)
        titleButton.setTitleColor(.black, for: .highlighted)
        titleButton.setTitle("所有照片", for: .normal)
        titleButton.setImage(UIImage(namedInBundle: "headlines_icon_arrow"), for: .normal)
        self.titleButton = titleButton
        
        super.init(frame: frame)
        backgroundColor = UIColor(red: 250.0/255, green: 250.0/255, blue: 250.0/255, alpha: 1)
        
        backButton.addTarget(self, action: #selector(backButtonAction(_ :)), for: .touchUpInside)
        addSubview(backButton)
        
        rightButton.addTarget(self, action: #selector(rightButtonAction(_ :)), for: .touchUpInside)
        addSubview(rightButton)
        
        addSubview(titleButton)
        titleButton.addTarget(self, action: #selector(titleButtonAction(_:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 按钮的点击事件
    @objc
    private func backButtonAction(_ button: UIButton) {
        backButtonCallback?(button)
    }
    
    @objc
    private func rightButtonAction(_ button: UIButton) {
        rightButtonCallback?(button)
    }
    
    @objc
    private func titleButtonAction(_ button: ZDPhotoTitleButton) {
        titleButtonCallback?(button)
    }
    
    
    //MARK:- 对外方法
    func setTitle(_ title: String) {
        titleButton.setTitle(title, for: .normal)
    }
    
    func setRightButtonImage(_ imageName: String) {
        rightButton.setImage(UIImage(namedInBundle: imageName), for: .normal)
    }
}
