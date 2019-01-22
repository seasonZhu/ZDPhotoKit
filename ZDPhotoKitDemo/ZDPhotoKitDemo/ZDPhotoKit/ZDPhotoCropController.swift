//
//  ZDPhotoCropController.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/9.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 照片剪裁控制器
class ZDPhotoCropController: UIViewController {
    
    //MARK:- 属性设置
    
    /// pickerVC
    var pickerVC = ZDPhotoPickerController()
    
    /// 自定义导航栏
    private lazy var naviBar: ZDPhotoNaviBar = {
        let naviBar = ZDPhotoNaviBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: ZDConstant.kNavigationBarHeight))
        naviBar.backgroundColor = .main
        naviBar.setTitle("剪裁")
        naviBar.titleButton.setImage(nil, for: .normal)
        naviBar.rightButton.setTitle("完成", for: .normal)
        return naviBar
    }()
    
    /// 显示的图片
    private lazy var showImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: ZDConstant.kNavigationBarHeight, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenHeight - ZDConstant.kNavigationBarHeight - ZDConstant.kBottomSafeHeight))
        imageView.isMultipleTouchEnabled = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    /// 遮罩层
    private lazy var overlayView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenHeight))
        view.alpha = 0.5
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()
    
    /// 剪裁层
    private lazy var ratioView = UIView()
    
    /// 原始图片
    private lazy var originalImage: UIImage = UIImage()
    
    /// 剪裁的Frame
    private var cropFrame: CGRect
    
    /// 资源模型
    private var asset: ZDAssetModel
    
    /// 放大系数
    private var limitScaleRatio: CGFloat
    
    /// 旧的frame
    private var oldFrame = CGRect.zero
    
    /// 最近的frame
    private var lastestFrame = CGRect.zero
    
    /// 最大的frame
    private var largeFrame = CGRect.zero
    
    //MARK:- 初始化
    init(asset: ZDAssetModel, cropFrame: CGRect, limitScaleRatio: CGFloat = 3) {
        self.asset = asset
        self.cropFrame = cropFrame
        self.limitScaleRatio = limitScaleRatio
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        onInitEvent()
    }
    
    //MARK:- viewWillAppear && viewWillDisappear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        view.backgroundColor = .black
        automaticallyAdjustsScrollViewInsets = false
        navigationController?.navigationBar.isHidden = true
        
        view.addSubview(naviBar)
        
        originalImageSetting()
        view.addSubview(showImageView)
        
        view.addSubview(overlayView)
        
        if (cropFrame.size.width == cropFrame.size.height) {
            ratioView = ZDMaskCornerView(frame: cropFrame)

        }else {
            ratioView = UIView(frame: cropFrame)
            ratioView.layer.borderColor = UIColor.white.cgColor
            ratioView.layer.borderWidth = 1.0
        }
        view.addSubview(ratioView)
        
        view.bringSubviewToFront(naviBar)
        
        drawOverlayViewClipping()
        
        addGestureRecognizers()
    }
    
    //MARK:- 初始化事件
    private func onInitEvent() {
        naviBar.backButtonCallback = { [weak self] backButton in
            self?.backAction()
        }
        
        naviBar.rightButtonCallback = { [weak self] rightbutton in
            self?.dismiss(animated: true)
            self?.pickerVC.selectCropImageCallback?(self?.getCropImage())
        }
    }
    
    //MARK:- 绘制剪切框
    private func drawOverlayViewClipping() {
        let maskLayer = CAShapeLayer()
        
        let path = CGMutablePath()
        
        path.addRect(CGRect(x: 0, y: 0, width: ratioView.frame.minX, height: overlayView.frame.height))
        path.addRect(CGRect(x: ratioView.frame.maxX, y: 0, width: overlayView.frame.size.width - ratioView.frame.minX - ratioView.frame.width, height: overlayView.frame.height))
        path.addRect(CGRect(x: 0, y: 0, width: overlayView.frame.width, height: ratioView.frame.minY))
        path.addRect(CGRect(x: 0, y: ratioView.frame.maxY, width: overlayView.frame.width, height: overlayView.frame.height - ratioView.frame.minY + ratioView.frame.height))
        
        maskLayer.path = path
        overlayView.layer.mask = maskLayer
    }
    
    //MARK:- 原始图片的设置
    private func originalImageSetting() {
        
        //  这个回调会调用两次 第一次拿的模糊的图 第二次拿的是高清图 其实我们要拿第二次的
        ZDPhotoManager.default.getPhoto(asset: asset.asset, targetSize: CGSize(width: asset.pixW, height: asset.pixH)) { (image, _) in
            guard let originalImage = image, originalImage.size.width > 0 && originalImage.size.height > 0 else {
                return
            }
            
            var originWidth: CGFloat = 0
            var originHeight: CGFloat = 0
            var originX: CGFloat = 0
            var originY: CGFloat = 0
            
            let cropWidth = self.cropFrame.size.width
            let cropHeight = self.cropFrame.size.height
            let scaleHeight = originalImage.size.height * (cropWidth / originalImage.size.width)
            let scaleWidth = originalImage.size.width * (cropHeight / originalImage.size.height)
            if scaleHeight >= cropHeight {
                // 直接裁剪
                originX = 0
                originY = self.cropFrame.origin.y - (scaleHeight - cropHeight) / 2.0
                originWidth = cropWidth
                originHeight = scaleHeight
            }else{
                originX = self.cropFrame.origin.x - (scaleWidth - cropWidth) / 2.0
                originY = self.cropFrame.origin.y
                originWidth = scaleWidth
                originHeight = cropHeight
            }
            self.oldFrame = CGRect(x: originX, y: originY, width: originWidth, height: originHeight)
            self.lastestFrame = self.oldFrame
            self.showImageView.frame = self.oldFrame
            self.originalImage = originalImage
            self.showImageView.image = originalImage
            
            self.largeFrame = CGRect(x: 0, y: 0, width: self.limitScaleRatio * self.oldFrame.size.width, height: self.limitScaleRatio * self.oldFrame.size.height);
        }
    }
    
    //MARK:- 添加手势
    private func addGestureRecognizers() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_ :)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(pan)
    }
    
    //MARK:- 点击事件
    
    //  返回事件
    @objc private func backAction() {
        
        if let viewControllers = navigationController?.viewControllers, let count = navigationController?.viewControllers.count, count > 1, viewControllers[count - 1] == self {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    //  捏合手势
    @objc private func pinchAction(_ pinch: UIPinchGestureRecognizer) {
        let imageView = showImageView
        if pinch.state == .began || pinch.state == .changed {
            imageView.transform = imageView.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1
        }else if pinch.state == .ended {
            var newFrame = showImageView.frame
            newFrame = handleScaleOverflow(frame: newFrame)
            newFrame = handleBorderOverflow(frame: newFrame)
            UIView.animate(withDuration: 0.3) {
                self.showImageView.frame = newFrame
                self.lastestFrame = newFrame
            }
        }
    }
    
    //  滑动手势
    @objc private func panAction(_ pan: UIPanGestureRecognizer) {
        let imageView = showImageView
        if pan.state == .began || pan.state == .changed {
            let absCenterX = cropFrame.midX
            let absCenterY = cropFrame.midY
            let scaleRatio = showImageView.frame.width / cropFrame.width
            let acceleratorX = 1 - abs(absCenterX - view.center.x) / (scaleRatio * absCenterX)
            let acceleratorY = 1 - abs(absCenterY - view.center.y) / (scaleRatio * absCenterY)
            let translation = pan.translation(in: imageView.superview)
            imageView.center = CGPoint(x: imageView.center.x + translation.x * acceleratorX, y: imageView.center.y + translation.y * acceleratorY)
            pan.setTranslation(CGPoint.zero, in: imageView.superview)
        }else if pan.state == .ended {
            var newFrame = showImageView.frame
            newFrame = handleBorderOverflow(frame: newFrame)
            UIView.animate(withDuration: 0.3) {
                self.showImageView.frame = newFrame
                self.lastestFrame = newFrame
            }
        }
    }
    
    //MARK:- 计算frame的方法
    private func handleScaleOverflow(frame: CGRect) -> CGRect {
        var newFrame = frame
        let center = CGPoint(x: frame.midX, y: frame.midY)
        if frame.width < oldFrame.width {
            newFrame = oldFrame
        }
        
        if frame.width > largeFrame.width {
            newFrame = largeFrame
        }
        
        newFrame.origin.x = center.x - newFrame.size.width / 2
        newFrame.origin.y = center.y - newFrame.size.height / 2
        
        return newFrame
    }
    
    private func handleBorderOverflow(frame: CGRect) -> CGRect {
        var newFrame = frame
        
        // horizontally
        if frame.origin.x > cropFrame.origin.x {
            newFrame.origin.x = cropFrame.origin.x
        }
        if frame.maxX < cropFrame.size.width {
            newFrame.origin.x = cropFrame.size.width - frame.size.width
        }
        
        // vertically
        if frame.origin.y > cropFrame.origin.y {
            newFrame.origin.y = cropFrame.origin.y
        }
        if (frame.maxY < cropFrame.origin.y + cropFrame.size.height) {
            newFrame.origin.y = cropFrame.origin.y + cropFrame.size.height - frame.size.height
        }
        
        // adapt horizontally rectangle
        if (showImageView.frame.size.width > showImageView.frame.size.height && frame.size.height <= cropFrame.size.height) {
            newFrame.origin.y = cropFrame.origin.y + (cropFrame.size.height - frame.size.height) / 2;
        }
        return newFrame
    }
    
    //MARK:- 获取剪裁的图片
    private func getCropImage() -> UIImage? {
        //  如果是拍照过来的话 需要做处理 这里还没写
        
        let squareFrame = cropFrame
        let scaleRatio = lastestFrame.size.width / originalImage.size.width
        let x = (squareFrame.origin.x - lastestFrame.origin.x) / scaleRatio
        let y = (squareFrame.origin.y - lastestFrame.origin.y) / scaleRatio
        let width = squareFrame.size.width / scaleRatio
        let height = squareFrame.size.height / scaleRatio
        
        let myImageRect = CGRect(x: x, y: y, width: width, height: height)
        let imageRef = originalImage.cgImage
        guard let subImageRef = imageRef?.cropping(to: myImageRect) else { return nil }
        
        let size = CGSize(width: myImageRect.size.width, height: myImageRect.size.height)
        UIGraphicsBeginImageContext(size);
        let context = UIGraphicsGetCurrentContext()
        context?.draw(subImageRef, in: myImageRect)
        let smallImage = UIImage(cgImage: subImageRef)
        UIGraphicsEndImageContext()
        return smallImage
    }

    //MARK:- 析构函数
    deinit {
        print("ZDPhotoCropController被销毁了")
    }

}
