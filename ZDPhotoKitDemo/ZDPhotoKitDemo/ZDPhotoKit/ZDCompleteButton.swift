//
//  ZDCompleteButton.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/1.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 图片选择完成,点击下方的完成按钮
class ZDCompleteButton: UIView {
    
    //MARK: 属性设置
    
    //  已选照片数量的Label
    private lazy var numberLabel: UILabel = {
        let label = UILabel(frame:CGRect(x: 0 , y: 0 , width: 20, height: 20))
        label.backgroundColor = UIColor.lightGreen
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.white
        label.isHidden = true
        return label
    }()
    
    //  完成的Label
    private lazy var completeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: 50, height: 20))
        label.text = "完成"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.lightGreen
        return label
    }()
    
    //  点击手势
    private lazy var tap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        return tap
    }()
    
    //  设置数量
    var number: Int = 0 {
        didSet {
            if number == 0 {
                numberLabel.isHighlighted = true
                numberLabel.isHidden = true
            }else {
                numberLabel.isHighlighted = false
                numberLabel.isHidden = false
                numberLabel.text = "\(number)"
                playAnimation()
            }
        }
    }
    
    //  是否可用
    var isEnabled: Bool = true {
        didSet {
            tap.isEnabled = isEnabled
            completeLabel.textColor = isEnabled ? UIColor.lightGreen : UIColor.gray
        }
    }
    
    //MARK: 初始化
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 70, height: 20))
        addSubview(numberLabel)
        addSubview(completeLabel)
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: 动画效果
    private func playAnimation() {
        numberLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
            self.numberLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    //MARK: 添加view的点击事件
    func addTarget(target: Any, action: Selector) {
        tap.addTarget(target, action: action)
    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDCompleteButton销毁了")
    }
}

