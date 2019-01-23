//
//  ZDPhotoCameraCell.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import AVKit

/// 拍照的cell
class ZDPhotoCameraCell: UICollectionViewCell {
    //MARK:- 属性设置
    
    private var imageView: UIImageView?
    private var session: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var videoLayer: AVCaptureVideoPreviewLayer!
    
    private lazy var photoIcon = UIImageView(image: UIImage(namedInBundle: "compose_photo_photograph_highlighted"))
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
        configCamera()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        let imageView = UIImageView(frame: bounds)
        contentView.addSubview(imageView)
        self.imageView = imageView
        
        contentView.addSubview(photoIcon)
        
        photoIcon.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: photoIcon,
                                         attribute: .centerX,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .centerX,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: photoIcon,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: contentView,
                                         attribute: .centerY,
                                         multiplier: 1,
                                         constant: 0))
        
        addConstraint(NSLayoutConstraint(item: photoIcon,
                                         attribute: .width,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .width,
                                         multiplier: 1,
                                         constant: 60))
        
        addConstraint(NSLayoutConstraint(item: photoIcon,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .height,
                                         multiplier: 1,
                                         constant: 60))
    }
    
    //MARK:- 配置相机
    private  func configCamera() {
        device = camera(position: .back)
        
        guard let device = device else { return }
        do {
            input = try AVCaptureDeviceInput(device: device)
        }catch {
            return
        }
        
        session = AVCaptureSession()
        
        guard let session = session, let input = input else { return }
        
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = bounds
        videoLayer.videoGravity = .resizeAspectFill
        imageView?.layer.addSublayer(videoLayer)
        
        session.startRunning()
    }
    
    /// 获取摄像头设备
    ///
    /// - Parameter position: 摄像头的位置
    /// - Returns: 设备
    private func camera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices where device.position == position  {
            return device
        }
        return nil
    }
    
    //MARK:- 析构函数
    deinit {
        session?.stopRunning()
        input = nil
        session = nil
        print("ZDPhotoCameraCell销毁了")
    }

}
