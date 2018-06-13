//
//  ZDMaskCornerView.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/11.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 正方形中内切圆 相框效果
class ZDMaskCornerView: UIView {
    //MARK:- 属性设置
    
    var cornerRadius: CGFloat = 0.0
    
    var superBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    
    //MARK:- 重写绘制
    override func draw(_ rect: CGRect) {
        // Drawing code
        let shortestEdge = min(self.bounds.width, self.bounds.height)//边长稍短的边
        let radius = max(min((shortestEdge / 2.0), cornerRadius), (shortestEdge / 2.0))//默认半径为稍短边的一半，防止负数或者过大的cornerRadius设置
        let context = UIGraphicsGetCurrentContext()
        
        //以坐上角为原点，顺时针画矩形的path
        context?.move(to: CGPoint(x: self.bounds.minX, y: self.bounds.minY))
        context?.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.minY))
        context?.addLine(to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY))
        context?.addLine(to: CGPoint(x: self.bounds.minX, y: self.bounds.maxY))
        context?.addLine(to: CGPoint(x: self.bounds.minX, y: self.bounds.minY))
        context?.closePath()
        
        //以左上角往右偏移一个半径长度的点为原点，顺时针画圆角矩形
        context?.move(to: CGPoint(x: radius, y: self.bounds.minY))
        context?.addLine(to: CGPoint(x: (self.bounds.maxX - radius), y: self.bounds.minY))
        context?.addArc(tangent1End: CGPoint(x: self.bounds.maxX, y: self.bounds.minY), tangent2End: CGPoint(x: self.bounds.maxX, y: self.bounds.minY + radius), radius: radius)
        context?.addLine(to: CGPoint(x: self.bounds.maxX, y: (self.bounds.maxY - radius)))
        context?.addArc(tangent1End: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY), tangent2End: CGPoint(x: self.bounds.maxX - radius, y: self.bounds.maxY), radius: radius)
        context?.addLine(to: CGPoint(x: radius, y: self.bounds.maxY))
        context?.addArc(tangent1End: CGPoint(x: self.bounds.minX, y: self.bounds.maxY), tangent2End: CGPoint(x: self.bounds.minX, y: self.bounds.maxY - radius), radius: radius)
        context?.addLine(to: CGPoint(x: self.bounds.minX, y: radius))
        context?.addArc(tangent1End: CGPoint(x: self.bounds.minX, y: self.bounds.minY), tangent2End: CGPoint(x: radius, y: self.bounds.minY), radius: radius)
        context?.closePath()
        
        context?.setFillColor(superBackgroundColor.cgColor)//设置填充色
        context?.fillPath(using: .evenOdd)//设置使用奇偶填充的方式
    }
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
}

