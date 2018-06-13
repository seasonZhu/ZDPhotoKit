//
//  ZDRecordButton.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 录制按钮 用于TakePhotoCamera控制器
class ZDRecordButton: UIButton {
    
    //MARK:- 属性设置
    
    //  最大的录制秒数
    var maxSecond: CGFloat = 30
    
    //  最小的录制秒数
    var minSecond: CGFloat = 0
    
    //  进度
    private var newProgress: CGFloat = 0
    
    var progress: CGFloat {
        set {
            newProgress = newValue
            setNeedsDisplay()
        }get {
            return newProgress
        }
    }
    
    //  开始的回调
    var startCallback: (() -> ())?
    
    //  相机使用的回调
    var photoCallback: (() -> ())?
    
    //  完成的回调
    var finishCallback: ((_ totalSecond: CGFloat) -> ())?
    
    //  全局时间
    private var second: CGFloat = 0
    
    //  定时器
    private var timer: Timer?
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK:- 对外方法 重置
    func reset() {
        second = 0
        progress = 0
        timer?.invalidate()
        timer = nil
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        addGestureRecognizer(tap)
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTapAction(_:)))
        
        //  只有允许拍摄 才添加长按手势
        if ZDPhotoManager.default.isAllowCaputreVideo {
            addGestureRecognizer(longTap)
        }
    }
    
    //MARK:- 手势的点击事件
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        photoCallback?()
    }
    
    @objc private func longTapAction(_ longTap: UITapGestureRecognizer) {
        if longTap.state == .began {
            print("长按开始")
            startCallback?()
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(startProgress), userInfo: nil, repeats: true)
        }else if longTap.state == .ended {
            print("长按结束")
            timer?.invalidate()
            timer = nil
            finishCallback?(second)
        }
    }
    
    //MARK:- 定时器方法
    @objc private func startProgress() {
        if second > maxSecond {
            finishCallback?(second)
            reset()
        }else {
            second += 0.05
            progress = second
        }
    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDRecordButton销毁了")
    }
    
}

extension ZDRecordButton {
    //MARK:- 重写方法
    override func draw(_ rect: CGRect) {
        let radius = rect.width * 0.5
        let centerX = rect.width * 0.5
        let centerY = rect.height * 0.5
        let center = CGPoint(x: centerX, y: centerY)
        
        drawBackdrop(rect: rect, center: center, radius: radius)
        drawMinMark(rect: rect, center: center, radius: radius)
        drawButton(rect: rect, center: center, radius: radius)
        drawProgress(rect: rect, center: center, radius: radius, progress: progress)
    }
    
    //MARK:- 绘图
    
    //  绘制底图
    private func drawBackdrop(rect: CGRect, center: CGPoint, radius: CGFloat) {
        UIColor.gray.withAlphaComponent(0.6).set()
        let aPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
        aPath.fill()
    }
    
    //  绘制小标志
    private func drawMinMark(rect: CGRect, center: CGPoint, radius: CGFloat) {
        let progressRadius = radius * 0.9
        UIColor.white.set()
        let aPath = UIBezierPath(arcCenter: center,
                                 radius: progressRadius,
                                 startAngle: CGFloat(-Double.pi / 2.0),
                                 endAngle: CGFloat(2.0 * Double.pi) * (minSecond / maxSecond) - CGFloat(Double.pi / 2.0), clockwise: true)
        aPath.lineWidth = radius * 0.1
        aPath.stroke()
    }
    
    //  绘制按钮
    private func drawButton(rect: CGRect, center: CGPoint, radius: CGFloat) {
        let buttonRadius = radius * 0.618
        UIColor.white.withAlphaComponent(1).set()
        let aPath = UIBezierPath(arcCenter: center, radius: buttonRadius, startAngle: 0, endAngle: CGFloat(2.0 * Double.pi), clockwise: true)
        aPath.fill()
    }
    
    //  绘制进度
    private func drawProgress(rect: CGRect, center: CGPoint, radius: CGFloat, progress: CGFloat) {
        let progressRadius = radius * 0.95
        UIColor.lightGreen.set()
        let aPath = UIBezierPath(arcCenter: center,
                                 radius: progressRadius,
                                 startAngle: CGFloat(-Double.pi / 2.0),
                                 endAngle: CGFloat(2.0 * Double.pi) * (progress / maxSecond) - CGFloat(Double.pi / 2.0), clockwise: true)
        aPath.lineWidth = radius * 0.05
        aPath.stroke()
    }
}
