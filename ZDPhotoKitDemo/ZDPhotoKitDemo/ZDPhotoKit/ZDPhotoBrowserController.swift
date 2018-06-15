//
//  ZDPhotoBrowserController.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/1.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 预览控制器
class ZDPhotoBrowserController: UIViewController {
    //MARK:- 属性设置
    
    ///  返回闭包
    var selectAssetsCallback: (([ZDAssetModel], Set<ZDAssetType>, Bool) -> ())?
    
    ///  pickerVC
    var pickerVC = ZDPhotoPickerController()
    
    ///  是否是原图
    private var isSelected: Bool
    
    ///  存储图片数组
    private var assets: [ZDAssetModel]
    
    ///  默认显示的图片索引
    private var indexPath: IndexPath
    
    ///  被选择过的模型数组
    private var selectAssets: [ZDAssetModel]
    
    /// 选择类型
    var assetTypeSet: Set<ZDAssetType>
    
    /// 自定义导航栏
    private lazy var naviBar: ZDPhotoNaviBar = {
        let naviBar = ZDPhotoNaviBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: ZDConstant.kNavigationBarHeight))
        naviBar.backgroundColor = UIColor(red: 34/255.0, green: 34/255.0, blue: 34/255.0, alpha: 0.7)
        
        naviBar.titleButton.setImage(nil, for: .normal)
        naviBar.titleButton.setTitleColor(.white, for: .normal)
        naviBar.titleButton.setTitleColor(.white, for: .highlighted)
        naviBar.titleButton.isHidden = assets.count < 2
        
        if ZDPhotoManager.default.isShowSelectCount {
            naviBar.rightButton.setTitle(nil, for: .normal)
            naviBar.rightButton.frame = CGRect(x: naviBar.rightButton.frame.minX, y: naviBar.rightButton.frame.minY, width: 32, height: 32)
            naviBar.rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            naviBar.rightButton.setBackgroundImage(UIImage(namedInbundle: "image_not_selected"), for: .normal)
            
            naviBar.rightButton.setTitleColor(.white, for: .selected)
            naviBar.rightButton.setBackgroundImage(UIImage(namedInbundle: "photo_original_select"), for: .selected)
        }else {
            naviBar.rightButton.setTitle(nil, for: .normal)
            naviBar.rightButton.setImage(UIImage(namedInbundle: "image_not_selected"), for: .normal)
            naviBar.rightButton.setImage(UIImage(namedInbundle: "image_selected"), for: .selected)
        }
        
        
        
        return naviBar
    }()
    
    ///  用来放置各个图片单元
    private lazy var collectionView: UICollectionView = {
        
        //  collectionView尺寸样式设置
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = view.bounds.size
        layout.scrollDirection = .horizontal
        automaticallyAdjustsScrollViewInsets = false
        
        //  collectionView初始化
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(ZDPhotoBrowserCell.self, forCellWithReuseIdentifier: "ZDPhotoBrowserCell")
        //collectionView.register(ZDVideoBrowserCell.self, forCellWithReuseIdentifier: "ZDVideoBrowserCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        //  滚动到点击的图片页面
        collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
        
        return collectionView
    }()
    
    ///  pageControl
    private lazy var pageControl: UIPageControl = {
        //  设置页控制器
        let pageControl = UIPageControl()
        pageControl.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 20 - ZDConstant.kBottomSafeHeight)
        pageControl.numberOfPages = assets.count
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPage = indexPath.item
        pageControl.isHidden = assets.count > 9 || assets.count < 2 ? true : false
        return pageControl
    }()
    
    ///  下载按钮,目前不添加上
    private lazy var downloanButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: ZDConstant.kScreenWidth - 20 - 44, y: ZDConstant.kScreenHeight - 20 - 44, width: 44, height: 44)
        button.setImage(UIImage(namedInbundle: "image_download"), for: .normal)
        button.addTarget(self, action: #selector(downloadAction(_ :)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    ///  toolbar 别使用UIToolBar这个控件,坑爹
    private lazy var toolbar: UIView = {
        let toolbar = UIView(frame: CGRect(x: 0,
                                           y: ZDConstant.kScreenHeight - ZDConstant.toolbarHeight - ZDConstant.kBottomSafeHeight,
                                           width: ZDConstant.kScreenWidth,
                                           height: ZDConstant.toolbarHeight))
        toolbar.backgroundColor = UIColor(red: 34/255.0, green: 34/255.0, blue: 34/255.0, alpha: 0.7)
        toolbar.addSubview(imageCompleteButton)
        toolbar.addSubview(originalImageButton)
        toolbar.addSubview(imagesSizeLabel)
        return toolbar
    }()
    
    /// toolbar 上面的原图按钮
    private lazy var originalImageButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        button.center = CGPoint(x: 40, y: 22)
        button.addTarget(self, action: #selector(originalImageButtonAction(_:)), for: .touchUpInside)
        button.setTitle("原图", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.gray, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.setImage(UIImage(namedInbundle: "photo_original_normal"), for: .normal)
        button.setImage(UIImage(namedInbundle: "photo_original_select"), for: .selected)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        return button
    }()
    
    /// toolbar 原图大小的Label
    private lazy var imagesSizeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        label.numberOfLines = 0
        label.center = CGPoint(x: 120, y: 22)
        label.textAlignment = .left
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    ///  完成按钮
    private lazy var imageCompleteButton: ZDCompleteButton = {
        let imageCompleteButton = ZDCompleteButton()
        imageCompleteButton.center = CGPoint(x: UIScreen.main.bounds.size.width - 50, y: 22)
        imageCompleteButton.addTarget(target: self, action: #selector(selectImageComplete))
        return imageCompleteButton
    }()
    
    ///  全局的图片 用于保存到相册使用
    private var asset = ZDAssetModel()
    
    ///  隐藏状态栏,目前不隐藏
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK:- 初始化
    init(assets: [ZDAssetModel], indexPath: IndexPath, selectAssets: [ZDAssetModel], assetTypeSet: Set<ZDAssetType>, isSelected: Bool) {
        self.assets = assets
        self.indexPath = indexPath
        self.selectAssets = selectAssets
        self.assetTypeSet = assetTypeSet
        self.isSelected = isSelected
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
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
        //  背景设为黑色
        view.backgroundColor = UIColor.black
        navigationController?.navigationBar.isHidden = true
        
        //  设置modal的展现方式
        //modalPresentationStyle = .custom
        //modalTransitionStyle = .crossDissolve
        
        //  collectionView
        view.addSubview(collectionView)
        
        //  naviBar
        view.addSubview(naviBar)
        view.bringSubview(toFront: naviBar)
        
        //  toolbar
        view.addSubview(toolbar)
        
        //  pageControl
        view.addSubview(pageControl)
        
        //  下载按钮
        view.addSubview(downloanButton)
        view.bringSubview(toFront: downloanButton)
        
        //  事件
        onInitEvent()
        
        //  赋值
        imageCompleteButton.number = selectAssets.count
        originalImageButton.isSelected = isSelected
    }
    
    //MARK:- 初始化事件
    private func onInitEvent() {
        
        naviBar.backButtonCallback = { [weak self] backButton in
            self?.backAction()
        }
        
        naviBar.rightButtonCallback = { [weak self] rightbutton in
            rightbutton.isSelected = !rightbutton.isSelected
            
            let asset = self?.assets[rightbutton.tag] ?? ZDAssetModel()
            if rightbutton.isSelected /*&& !(self?.selectIndexPaths.contains(indexPath))!*/ {
                if self?.selectAssets.count ?? ZDPhotoManager.default.maxSelected >= ZDPhotoManager.default.maxSelected {
                    rightbutton.isSelected = false
                    
                    if ZDPhotoManager.default.isAllowCropper {
                        ZDPhotoManager.default.showAlert(controller: self!, message: "剪裁图片只能选择1张照片!")
                    }else {
                        ZDPhotoManager.default.showAlert(controller: self!)
                    }
                    
                    return
                }
                
                //  添加到数组中
                self?.selectAssets.append(asset)
                
                //  添加类型
                if let count = self?.selectAssets.count, count > 0 {
                    self?.assetTypeSet.insert(asset.type)
                }
                
                //  播放动画
                self?.playAnimation()
                
            }else {
                //  从数组中移除
                self?.selectAssets.removeZDAssetModel(asset)
                
                //  移除类型类型
                if let count = self?.selectAssets.count, count == 0 {
                    self?.assetTypeSet.removeAll()
                }
            }
            
            asset.isSelect = rightbutton.isSelected
            
            self?.imageCompleteButton.number = self?.selectAssets.count ?? 0
            
            //  如果显示选择序列 那么刷新选择数字
            if ZDPhotoManager.default.isShowSelectCount, let selectAssets = self?.selectAssets {
                for (index, selectAsset) in selectAssets.enumerated() {
                    selectAsset.selectNum = index + 1
                    if selectAsset.asset == asset.asset {
                        self?.naviBar.rightButton.setTitle("\(selectAsset.selectNum)", for: .selected)
                    }
                }
            }
        }
        
    }
    
    //MARK:- 点击事件
    
    //  返回事件
    @objc private func backAction() {
        
        if let viewControllers = navigationController?.viewControllers, let count = navigationController?.viewControllers.count, count > 1, viewControllers[count - 1] == self {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
        
        selectAssetsCallback?(selectAssets, assetTypeSet, originalImageButton.isSelected)
    }
    
    //  下载按钮的点击事件
    @objc private func downloadAction(_ button: UIButton) {
        
        ZDPhotoManager.default.getPhoto(asset: asset.asset, targetSize: CGSize(width: asset.pixW, height: asset.pixH)) { (image, info) in
            
            //  守护图片有值
            guard let saveImage = image else {
                SwiftProgressHUD.showOnlyText("获取图片失败!")
                return
            }
            
            //  保存图片
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: saveImage)
            }) { (isSuccess, error) in
                let message = isSuccess ? "图片保存成功！" : "图片保存失败！"
                DispatchQueue.main.async {
                    SwiftProgressHUD.showOnlyText(message)
                }
            }
        }
    }
    
    //  点击了完成按钮
    @objc private func selectImageComplete() {
        print("从完成按钮这里进行点击事件")
        dismiss(animated: true)
        pickerVC.selectAssetsCallback?(selectAssets, assetTypeSet, originalImageButton.isSelected)
    }
    
    //MARK:- 原图按钮的点击事件
    @objc private func originalImageButtonAction(_ button: UIButton) {
        button.isSelected = !button.isSelected
    }
    
    /// 播放动画
    private func playAnimation() {
        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .allowUserInteraction, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2, animations: {
                self.naviBar.rightButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4, animations: {
                self.naviBar.rightButton.transform = CGAffineTransform.identity
            })
            
        }, completion: nil)
    }
    
    deinit {
        print("ZDPhotoBrowserController销毁了")
    }
}

//MARK:- ImagePreviewVC的CollectionView相关协议方法实现
extension ZDPhotoBrowserController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    //  collectionView单元区域数量
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //  collectionView单元格数量
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    //  collectionView单元格创建
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = assets[indexPath.row]
        self.asset = asset
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZDPhotoBrowserCell", for: indexPath) as! ZDPhotoBrowserCell
        cell.asset = asset
        
        cell.dismissCallback = { [weak self] in
            //self?.dismiss(animated: false, completion: nil)
            self?.navigationController?.popViewController(animated: true)
        }
        return cell
    }
    
    //  collectionView将要显示
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ZDPhotoBrowserCell{
            //  由于单元格是复用的，所以要重置内部元素尺寸
            cell.resetSize()
            
            //  设置页控制器当前页
            pageControl.currentPage = indexPath.item
            
            //  设置导航栏标题
            //title = "\(indexPath.item + 1)/\(assets.count)"
            naviBar.setTitle("\(indexPath.item + 1)/\(assets.count)")
            
            //  设置导航栏的选择按钮
            naviBar.rightButton.isSelected = selectAssets.contains(where: { [weak self] (selectAsset) -> Bool in
                let isSame = selectAsset.asset == cell.asset.asset
                if isSame && ZDPhotoManager.default.isShowSelectCount {
                    self?.naviBar.rightButton.setTitle("\(selectAsset.selectNum)", for: .selected)
                }
                return isSame
            })
            naviBar.rightButton.tag = indexPath.item
            
            //  现实当前图片的大小
            ZDPhotoManager.default.getPhotosSize(models: [cell.asset]) { (sizeString, size) in
                self.imagesSizeLabel.text = sizeString
            }
        }
    }
}

