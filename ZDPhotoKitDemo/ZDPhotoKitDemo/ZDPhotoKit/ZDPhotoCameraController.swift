//
//  ZDPhotoCameraController.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/9.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import AVFoundation

/// 照相拍摄控制器
class ZDPhotoCameraController: UIViewController {
    
    //MARK:- 属性设置
    
    ///  对外的两个回调
    
    ///  照相回调
    var photoCallback: ((_ image: UIImage) -> Void)?
    
    ///  视频路径
    var videoPathCallback: ((_ path: String) -> Void)?
    
    ///  pickerVC
    var pickerVC = ZDPhotoPickerController()
    
    ///  对内的私有方法
    
    /// 自定义导航栏
    private lazy var naviBar: ZDPhotoNaviBar = {
        let naviBar = ZDPhotoNaviBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: ZDConstant.kNavigationBarHeight))
        naviBar.backgroundColor = .clear
        let image = UIImage(namedInBundle: "camera_overturn_white")?.withRenderingMode(.alwaysOriginal)
        naviBar.setTitle("")
        naviBar.titleButton.setImage(nil, for: .normal)
        naviBar.rightButton.setImage(image, for: .normal)
        naviBar.rightButton.setImage(image, for: .highlighted)
        naviBar.rightButton.setTitle(nil, for: .normal)
        return naviBar
    }()

    
    ///  视频层
    private lazy var layerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenHeight - ZDConstant.kBottomSafeHeight))
        view.backgroundColor = UIColor.black
        return view
    }()
    
    ///  拍照层
    private lazy var maskView: UIImageView = {
        let imageView = UIImageView(frame: layerView.frame)
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskViewAction(_ :))))
        return imageView
    }()
    
    ///  提示label
    private lazy var remindLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: maskView.bounds.size.height - 20, width: ZDConstant.kScreenWidth, height: 10))
        label.center = view.center
        label.textColor = UIColor.white
        var text: String
        if ZDPhotoManager.default.isAllowCaputreVideo {
            text = "轻触拍照，长按拍摄"
        }else {
            text = "轻触拍照"
        }
        label.text = text
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13)
        //  加阴影的方法 要写一个
        return label
    }()
    
    ///  聚焦
    private lazy var focusingView: UIImageView = {
        let imageView = UIImageView(image: UIImage(namedInBundle:"camera_focusing"))
        imageView.frame = CGRect(x: 0, y: 0, width: imageView.bounds.size.width, height: imageView.bounds.size.height)
        imageView.isHidden = true
        return imageView
    }()
    
    ///  时间label
    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: ZDConstant.kScreenHeight - ZDConstant.kBottomSafeHeight - 150,
                                          width: ZDConstant.kScreenWidth,
                                          height: 20))
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .center
        return label
    }()
    
    ///  正方形按钮,暂时没有使用
    private lazy var squareButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: layerView.frame.origin.y + layerView.frame.size.height + 5, width: 50, height: 50))
        button.isSelected = true
        button.setImage(UIImage(namedInBundle: "photo_camera_square_normal"), for: .normal)
        button.setImage(UIImage(namedInBundle: "photo_camera_square_select"), for: .selected)
        button.addTarget(self, action: #selector(squareButtonAction(_: )), for: .touchUpInside)
        return button
    }()
    
    ///  长方形按钮,暂时没有使用
    private lazy var rectangleButton: UIButton = {
        let button = UIButton(frame: CGRect(x: squareButton.frame.origin.x + squareButton.frame.size.width,
                                            y: squareButton.frame.origin.y,
                                            width: 50, height: 50))
        button.setImage(UIImage(namedInBundle: "photo_camera_shu_normal"), for: .normal)
        button.setImage(UIImage(namedInBundle: "photo_camera_shu_select"), for: .selected)
        button.addTarget(self, action: #selector(rectangleButtonAction(_: )), for: .touchUpInside)
        return button
    }()
    
    ///  拍摄按钮,需要单独的写
    private lazy var recordButton: ZDRecordButton = {
        let button = ZDRecordButton(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        button.center.x = view.center.x
        button.center.y = timeLabel.frame.size.height + timeLabel.frame.origin.y + 40
        
        button.photoCallback = { [weak self] in
            self?.isTakePhoto = true
            self?.takePhoto()
        }
        
        button.startCallback = { [weak self] in
            self?.isTakePhoto = false
            self?.takeVideo()
        }
        
        button.finishCallback = { [weak self] totalSecond in
            self?.endVideo()
        }
        
        return button
    }()
    
    ///  删除按钮
    private lazy var deleteButton: UIButton = {
        let button = UIButton(frame: recordButton.frame)
        button.alpha = 0
        button.setImage(UIImage(namedInBundle: "video_delete_dustbin_white"), for: .normal)
        button.addTarget(self, action: #selector(deleteButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    ///  下一步按钮
    private lazy var nextButton: UIButton = {
        let button = UIButton(frame: recordButton.frame)
        button.alpha = 0
        button.setImage(UIImage(namedInBundle: "video_next_button_white"), for: .normal)
        button.setImage(UIImage(namedInBundle: "video_next_button_highlighted"), for: .highlighted)
        button.setImage(UIImage(namedInBundle: "video_next_button_disabled"), for: .disabled)
        button.addTarget(self, action: #selector(nextButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    ///  导航栏的切换摄像头的按钮
    private lazy var rightBarItem: UIBarButtonItem = {
        let image = UIImage(namedInBundle: "camera_overturn")?.withRenderingMode(.alwaysOriginal)
        let barItem = UIBarButtonItem(image: image ,style: .plain, target: self, action: #selector(changeCamera))
        return barItem
    }()
    
    ///  设备 输入输出流的设置
    private var device: AVCaptureDevice!
    
    private var videoInput: AVCaptureDeviceInput!
    
    private var audioInput: AVCaptureDeviceInput!
    
    private var imageOutput: AVCaptureStillImageOutput!
    
    private var videoOutput: AVCaptureMovieFileOutput!
    
    private var captureSession: AVCaptureSession!
    
    private var captureLayer: AVCaptureVideoPreviewLayer!
    
    private var player: AVPlayer!
    
    private var videoQueue: DispatchQueue!
    
    ///  全局的最终拍摄的照片
    private var finalPhoto: UIImage?
    
    ///  全局的拍摄视频的定时器
    private var videoTimer: Timer?
    
    ///  全局的videoUrl
    private var videoUrl: URL!
    
    ///  全局的是否是拍照
    private var isTakePhoto = false
    
    ///  全局的视频时间
    private var videoLenght: CGFloat = 0
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpCamera()
        onInitEvent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            videoQueue.async {
                self.captureSession.startRunning()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.focus(point: CGPoint(x: self.maskView.bounds.size.width / 2.0, y: self.maskView.bounds.size.height / 2.0))
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            self.remindLabel.isHidden = true
        }
        
        if maskView.image != nil {
            maskView.image = nil
            deleteButtonAction(deleteButton)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            videoQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        view.backgroundColor = UIColor.white
        navigationController?.navigationBar.isHidden = true
        
        view.addSubview(layerView)
        view.addSubview(maskView)
        view.addSubview(naviBar)
        view.addSubview(remindLabel)
        maskView.addSubview(focusingView)
        view.addSubview(timeLabel)
        //view.addSubview(squareButton)
        //view.addSubview(rectangleButton)
        view.addSubview(recordButton)
        view.addSubview(deleteButton)
        view.addSubview(nextButton)
        
        //navigationItem.rightBarButtonItem = rightBarItem
    }
    
    //MARK:- 设置相机
    private func setUpCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .vga640x480
        
        guard let device = camera(position: .back) else {return}
        self.device = device
        
        //  视频输入
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        }catch {
            
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        //  音频输入
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {return}
        do {
            audioInput = try AVCaptureDeviceInput(device: audioDevice)
        }catch {
            
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        //  输入展示
        captureLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureLayer.frame = layerView.bounds
        captureLayer.videoGravity = .resizeAspectFill
        layerView.layer.addSublayer(captureLayer)
        
        //  视频输出
        videoOutput = AVCaptureMovieFileOutput()
        videoOutput.movieFragmentInterval = CMTime.invalid
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        //  拍照输出
        imageOutput = AVCaptureStillImageOutput()
        imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFlashModeSupported(.auto) {
                device.flashMode = .auto
            }
            
            if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                device.whiteBalanceMode = .autoWhiteBalance
            }
            
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            
            device.unlockForConfiguration()
            
        }catch {
            
        }
        
        videoQueue = DispatchQueue(label: "ZDPhotoKit", attributes: .init(rawValue: 0))
    }
    
    //MARK:- 初始化事件
    private func onInitEvent() {
        
        naviBar.backButtonCallback = { [weak self] backButton in
            self?.backAction()
        }
        
        naviBar.rightButtonCallback = { [weak self] rightbutton in
            self?.changeCamera()
        }
        
    }
    
    //MARK:- 按钮的点击事件
    
    //  返回事件
    @objc private func backAction() {
        
        if let viewControllers = navigationController?.viewControllers, let count = navigationController?.viewControllers.count, count > 1, viewControllers[count - 1] == self {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    //  正方形按钮点击事件
    @objc private func squareButtonAction(_ button: UIButton) {
        if button.isSelected { return }
        button.isSelected = !button.isSelected
        rectangleButton.isSelected = !rectangleButton.isSelected
        squareTranfrom()
    }
    
    //  长方形按钮点击事件
    @objc private func rectangleButtonAction(_ button: UIButton) {
        if button.isSelected { return }
        button.isSelected = !button.isSelected
        squareButton.isSelected = !squareButton.isSelected
        rectangleTranfrom()
    }
    
    //  删除按钮点击事件
    @objc private func deleteButtonAction(_ button: UIButton) {
        recordButton.reset()
        squareButton.isHidden = false
        rectangleButton.isHidden = false
        timeLabel.isHidden = true
        timeLabel.text = ""
        maskView.image = nil
        videoLenght = 0.0
        
        if player != nil {
            if player.rate == 1.0 {
                player.pause()
            }
            player = nil
            videoUrl = nil
            
            for layre in maskView.layer.sublayers! {
                if layre .isKind(of: AVPlayerLayer.self) {
                    layre.removeFromSuperlayer()
                }
            }
        }
        
        buttonAnimationClose()
    }
    
    //  下一步按钮的点击事件,回调
    @objc private func nextButtonAction(_ button: UIButton) {
        if isTakePhoto {
            pickerVC.takePhotoCallback?(finalPhoto)
        }else {
            clipVideo(success: {
                //  获取视频封面图
                let image = UIImage.getFirstPicture(frome: self.videoUrl.absoluteString)
                self.pickerVC.takeVideoCallback?(image, self.videoUrl.absoluteString)
            }, fail: {
                
            })
        }
        
        dismiss(animated: true)
    }
    
    //MARK:- 手势的点击事件
    @objc private func maskViewAction(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: maskView)
        focus(point: point)
    }
    
    //MARK:- 焦距
    private func focus(point: CGPoint) {
        let size = maskView.frame.size
        let focusPoint = CGPoint(x: point.y / size.height, y: 1 - point.x / size.width)
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            
            if device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            //  设置对焦动画
            focusingView.center = point
            focusingView.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.focusingView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            }, completion: { (finish) in
                UIView.animate(withDuration: 0.3, animations: {
                    self.focusingView.transform = CGAffineTransform.identity
                }, completion: { (finish) in
                    self.focusingView.isHidden = true
                })
            })
            
        }catch {
            
        }
    }
    
    //MARK:- 相机正方形长方形的变化
    private func squareTranfrom() {
        let offsetH: CGFloat = 640.0 / 480.0 * ZDConstant.kScreenWidth - ZDConstant.kScreenWidth
        UIView.animate(withDuration: 0.25) {
            self.layerView.frame.size.height -= offsetH
            self.maskView.frame.size.height -= offsetH
            self.captureLayer.frame = self.layerView.bounds
            self.remindLabel.transform = CGAffineTransform.identity
            self.timeLabel.transform = CGAffineTransform.identity
            self.squareButton.transform = CGAffineTransform.identity
            self.rectangleButton.transform = CGAffineTransform.identity
            self.recordButton.transform = CGAffineTransform.identity
            self.deleteButton.transform = CGAffineTransform.identity
            self.nextButton.transform = CGAffineTransform.identity
        }
    }
    
    private func rectangleTranfrom() {
        let offsetH: CGFloat = 640.0 / 480.0 * ZDConstant.kScreenWidth - ZDConstant.kScreenWidth

        UIView.animate(withDuration: 0.25) {
            self.layerView.frame.size.height += offsetH
            self.maskView.frame.size.height += offsetH
            self.captureLayer.frame = self.layerView.bounds
            self.remindLabel.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.timeLabel.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.squareButton.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.rectangleButton.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.recordButton.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.deleteButton.transform = CGAffineTransform(translationX: 0, y: offsetH)
            self.nextButton.transform = CGAffineTransform(translationX: 0, y: offsetH)
        }
    }
    
    //MARK:- 拍照
    private func takePhoto() {
        squareButton.isHidden = true
        rectangleButton.isHidden = true
        guard let imageContect = imageOutput.connection(with: .video) else { return }
        if imageContect.isVideoOrientationSupported {
            imageContect.videoOrientation = currentVideoOrientation()
        }
        imageOutput.captureStillImageAsynchronously(from: imageContect) { (imageDataSampleBuffer, error) in
            guard imageDataSampleBuffer != nil, error == nil else { return }
            guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!) else { return }
            guard let image = UIImage(data: data) else { return }
            let fixImage = image.fixOrientation
            DispatchQueue.main.async {
                self.buttonAnimationOpen()
                //self.finalPhoto = self.squareButton.isSelected ? fixImage.clipSquareImage(scale: 1.0) : fixImage
                self.finalPhoto = fixImage
                self.maskView.image = fixImage
            }
        }
    }
    
    //MARK:- 拍摄
    private func takeVideo() {
        squareButton.isHidden = true
        rectangleButton.isHidden = true
        guard let videoContect = videoOutput.connection(with: .video) else { return }
        if videoContect.isVideoOrientationSupported {
            videoContect.videoOrientation = currentVideoOrientation()
        }
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! + "/video.mp4"
        
        let fileUrl = URL(fileURLWithPath: path)
        videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    private func endVideo() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
            buttonAnimationOpen()
        }
        videoTimer?.invalidate()
        videoTimer = nil
    }
    
    //MARK:- 视频的播放与结束
    private func playTheVideo() {
        let item = AVPlayerItem(url: videoUrl)
        player = AVPlayer(playerItem: item)
        let layer = AVPlayerLayer(player: player)
        layer.frame = maskView.bounds
        layer.videoGravity = .resizeAspectFill
        maskView.layer.addSublayer(layer)
        player.play()
        NotificationCenter.default.addObserver(self, selector: #selector(playTheVideoEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func playTheVideoEnd() {
        if player != nil {
            player.seek(to: CMTime.zero)
            player.play()
        }
        //player.pause()
    }
    
    //MARK:- 按钮的相关动画
    private func buttonAnimationOpen() {
        recordButton.isHidden = true
        navigationItem.rightBarButtonItem = nil
        maskView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.deleteButton.alpha = 1.0
            self.nextButton.alpha = 1.0
            self.deleteButton.transform = self.deleteButton.transform.translatedBy(x: -self.deleteButton.frame.origin.x + self.deleteButton.frame.size.width / 2.0, y: 0)
            self.nextButton.transform = self.nextButton.transform.translatedBy(x: self.nextButton.frame.origin.x - self.nextButton.frame.size.width / 2.0, y: 0)
        }
    }
    
    private func buttonAnimationClose() {
        recordButton.isHidden = false
        self.deleteButton.alpha = 0.0
        self.nextButton.alpha = 0.0
        navigationItem.rightBarButtonItem = rightBarItem
        maskView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.deleteButton.transform = self.deleteButton.transform.translatedBy(x: self.deleteButton.frame.origin.x - self.deleteButton.frame.size.width / 2.0, y: 0)
            self.nextButton.transform = self.nextButton.transform.translatedBy(x: -(self.nextButton.frame.origin.x + self.nextButton.frame.size.width / 2.0 - ZDConstant.kScreenWidth / 2.0), y: 0)
        }
    }
    
    //MARK:- 析构函数
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("ZDPhotoCameraController销毁了")
    }
}

//MARK:- 摄像头相关
extension ZDPhotoCameraController {
    
    /// 获取摄像头
    ///
    /// - Parameter position: 位置
    /// - Returns: 设备
    private func camera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device in devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .landscapeRight:
            return .landscapeRight
        case .landscapeLeft:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    /// 切换前后摄像头
    @objc private func changeCamera() {
        let cameraCount = AVCaptureDevice.devices(for: .video).count
        //  只有保证大于1个摄像头才能进行切换
        if cameraCount > 1 {
            let animation = CATransition()
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.type = CATransitionType(rawValue: "oglFlip")
            
            var newCamera: AVCaptureDevice?
            var newInput: AVCaptureDeviceInput?
            
            let position = videoInput.device.position
            
            if position == .front {
                newCamera = camera(position: .back)
                animation.subtype = CATransitionSubtype.fromLeft
            }else {
                newCamera = camera(position: .front)
                animation.subtype = CATransitionSubtype.fromRight
            }
            
            do {
                newInput = try AVCaptureDeviceInput(device: newCamera!)
                layerView.layer.add(animation, forKey: nil)
                guard newInput != nil else { return }
                captureSession.beginConfiguration()
                captureSession.removeInput(videoInput)
                if captureSession.canAddInput(newInput!) {
                    captureSession.addInput(newInput!)
                    videoInput = newInput
                }else {
                    captureSession.addInput(videoInput)
                }
                captureSession.commitConfiguration()
            }catch {
                
            }
            
        }
    }
}

//MARK:- AVCaptureFileOutputRecordingDelegate
extension ZDPhotoCameraController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        timeLabel.isHidden = false
        videoTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(videoTimeChange), userInfo: nil, repeats: true)
        RunLoop.current.add(videoTimer!, forMode: RunLoop.Mode.common)
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        videoUrl = outputFileURL
        playTheVideo()
    }
    
    @objc private func videoTimeChange() {
        videoLenght += 0.2
        if videoLenght >= 30 {
            videoOutput.stopRecording()
            videoTimer?.invalidate()
            videoTimer = nil
        }
        timeLabel.text = String(format: "%.02fs",videoLenght)
    }
}

//MARK:- 压缩视频相关
extension ZDPhotoCameraController {
    private func clipVideo(success: @escaping () -> Void, fail: @escaping () -> Void) {
        let asset = AVAsset(url: videoUrl)
        
        var audioTrack: AVAssetTrack?
        if asset.tracks(withMediaType: .audio).count > 0 {
            audioTrack = asset.tracks(withMediaType: .audio)[0]
        }
        
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            try videoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: CMTime.zero)
            
            if audioTrack != nil {
                let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                
                do {
                    try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: audioTrack!, at: CMTime.zero)
                }catch {
                    
                }
                
            }
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
            
            let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
            
            var videoAssetTrack: AVAssetTrack!
            if asset.tracks(withMediaType: .video).count > 0 {
                videoAssetTrack = asset.tracks(withMediaType: .video)[0]
            }else {
                return
            }
            
            var videoAssetOrientation: UIImage.Orientation = .up
            var isVideoAssetPortrait = false
            
            let videoTransform = videoAssetTrack?.preferredTransform
            
            if videoTransform?.a == 0
                && videoTransform?.b == 1.0
                && videoTransform?.c == -1.0
                && videoTransform?.d == 0 {
                videoAssetOrientation = .right
                isVideoAssetPortrait = true
            }
            if videoTransform?.a == 0
                && videoTransform?.b == -1.0
                && videoTransform?.c == 1.0
                && videoTransform?.d == 0 {
                videoAssetOrientation =  .left
                isVideoAssetPortrait = true
            }
            if videoTransform?.a == 1.0
                && videoTransform?.b == 0
                && videoTransform?.c == 0
                && videoTransform?.d == 1.0 {
                videoAssetOrientation =  .up
            }
            if videoTransform?.a == -1.0
                && videoTransform?.b == 0
                && videoTransform?.c == 0
                && videoTransform?.d == -1.0 {
                videoAssetOrientation = .down
            }
            
            let videoWidth = videoAssetTrack.naturalSize.width
            let videoHeight = videoAssetTrack.naturalSize.height
            
            var t1 = CGAffineTransform()
            var t2 = CGAffineTransform()
            
            if isVideoAssetPortrait {
                if videoAssetOrientation == .right {
                    t1 = (videoTransform?.translatedBy(x:  -(videoWidth / 2 - videoHeight / 2), y: 0))!
                    videolayerInstruction.setTransform(t1, at: CMTime.zero)
                }else if videoAssetOrientation == .left {
                    t1 = (videoTransform?.scaledBy(x: 1, y: 1))!
                    t2 = t1.translatedBy(x: -(videoWidth / 2 - videoHeight - videoHeight / 4), y: 0)
                    videolayerInstruction.setTransform(t2, at: CMTime.zero)
                }
            }else {
                if videoAssetOrientation == .up {
                    t1 = (videoTransform?.scaledBy(x: 1.77778, y: 1.77778))!
                    t2 = t1.translatedBy(x: videoHeight / 2 - videoWidth / 2, y: 0)
                    videolayerInstruction.setTransform(t2, at: CMTime.zero)
                }else {
                    t1 = (videoTransform?.scaledBy(x: 1.77778, y: 1.77778))!
                    t2 = t1.translatedBy(x: videoHeight / 2 - videoWidth / 2, y: -(videoHeight / 16 * 7))
                }
                videolayerInstruction.setTransform(t2, at: CMTime.zero)
            }
            
            videolayerInstruction.setOpacity(0.0, at: asset.duration)
            mainInstruction.layerInstructions = [videolayerInstruction]
            
            let mainCompositionInst = AVMutableVideoComposition()
            
            
            var naturalSize = CGSize.zero
            if isVideoAssetPortrait{
                naturalSize = CGSize(width:   videoAssetTrack.naturalSize.height,
                                     height: videoAssetTrack.naturalSize.width)
            } else {
                naturalSize = videoAssetTrack.naturalSize
            }
            
            let renderWidth = naturalSize.width
            let renderHeight = naturalSize.height
            
            mainCompositionInst.renderSize = CGSize(width: renderWidth, height: renderHeight)
            
            mainCompositionInst.instructions = [mainInstruction]
            mainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
            
            let outPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! + "/outVideo.mp4"
            
            let outVideoUrl = URL(fileURLWithPath: outPath)
            
            //MARK:- UnsafePointer<Int8>是一个C字符串 String -> NSString -> UnsafePointer
            let cOutPath = (outPath as NSString).utf8String
            let buffer = UnsafePointer<Int8>(cOutPath)
            unlink(buffer)
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            
            exporter?.outputURL = outVideoUrl
            exporter?.outputFileType = .mp4
            exporter?.shouldOptimizeForNetworkUse = true
            exporter?.videoComposition = mainCompositionInst
            
            exporter?.exportAsynchronously(completionHandler: {
                switch exporter?.status {
                case .unknown?:
                    break
                case .waiting?:
                    break
                case .exporting?:
                    break
                case .completed?:
                    DispatchQueue.main.async {
                        self.videoUrl = outVideoUrl
                        success()
                    }
                case .failed?:
                    DispatchQueue.main.async {
                        fail()
                    }
                case .cancelled?:
                    DispatchQueue.main.async {
                        fail()
                    }
                case .none:
                    DispatchQueue.main.async {
                        fail()
                    }
                }
            })
            
        }catch {
            DispatchQueue.main.async {
                fail()
            }
        }
    }
}

