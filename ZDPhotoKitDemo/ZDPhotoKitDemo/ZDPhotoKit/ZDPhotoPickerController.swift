//
//  ZDPhotoPickerController.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/31.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit
import Photos

/// 选择控制器
public class ZDPhotoPickerController: UIViewController {
    
    //MARK:- 属性设置
    
    //MARK:- 选项设置
    
    /// 允许选择视频
    public var isAllowVideo = false
    
    /// 允许选择gif
    public var isAllowGif = false
    
    /// 允许选择live
    public var isAllowLive = false
    
    /// 允许拍摄视频
    public var isAllowCaputreVideo = false
    
    /// 允许拍摄照片
    public var isAllowTakePhoto = false
    
    /// 允许进行剪裁
    public var isAllowCropper = false
    
    /// 相册页面允许展示Live图效果
    public var isAllowShowLive = false
    
    /// 相册页面允许展示Gif图效果
    public var isAllowShowGif = false
    
    /// 允许展示资源的顺序数字
    public var isShowSelectCount = true
    
    /// 最大的相片选择数量
    public var maxSelected = 9
    
    /// 一行展示图片的数量
    public var rowImageCount = 4
    
    /// 通过视频时间筛选视频 默认大于2分钟的视频不要
    public var maxVideoTime = 120
    
    /// 剪裁的大小
    public var cropFrame = CGRect(x: 0, y: ZDConstant.kScreenHeight / 2.0 - ZDConstant.kScreenWidth / 2.0, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenWidth)
    
    /// 控制器
    var cropPopToVC: UIViewController?
    
    //MARK:- 闭包回调
    
    /// 选择照片的闭包
    public var selectPhotoCallback: ((UIImage) -> ())?
    
    /// 选择需要剪裁的闭包
    public var selectCropImageCallback: ((UIImage?) -> ())?
    
    /// 拍照的闭包
    public var takePhotoCallback: ((UIImage) -> ())?
    
    /// 选择的视频
    public var takeVideoCallback: ((UIImage?, String) -> ())?
    
    /// livePhoto
    public var selectLivePhotoCallback: ((UIImage, PHLivePhoto, String) -> ())?
    
    /// 静态的livePhoto
    public var selectStaticLivePhotoCallback: ((UIImage) -> ())?
    
    /// 选择的Gif
    public var selectGifCallback: ((Data, CGSize) -> ())?
    
    /// 选择的视频
    public var selectVideoCallback: ((UIImage?, String) -> ())?
    
    /// 选择的模型闭包
    public var selectAssetsCallback: (([ZDAssetModel], Set<ZDAssetType>, Bool) -> ())?
    
    //MARK:- 私有属性
    
    /// 管理器
    private let manager = ZDPhotoManager.default
    
    /// 自定义导航栏
    private lazy var naviBar: ZDPhotoNaviBar = {
        let naviBar = ZDPhotoNaviBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: ZDConstant.kNavigationBarHeight))
        naviBar.backgroundColor = .main
        naviBar.rightButton.setTitle("剪裁", for: .normal)
        naviBar.rightButton.isHidden = true
        return naviBar
    }()
    
    ///  collectionView layout
    private lazy var layout: UICollectionViewFlowLayout = {
        
        //  如果一行的显示数量大于6 那么使用默认的4个
        if rowImageCount > 6 {
            rowImageCount = 4
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.size.width / CGFloat(rowImageCount) - UIScreen.main.scale, height: UIScreen.main.bounds.size.width / CGFloat(rowImageCount) - UIScreen.main.scale)
        layout.minimumLineSpacing = 1 * UIScreen.main.scale
        layout.minimumInteritemSpacing = 1 * UIScreen.main.scale
        return layout
    }()
    
    ///  collectionView
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: ZDConstant.kNavigationBarHeight, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenHeight - ZDConstant.toolbarHeight - ZDConstant.kNavigationBarHeight - ZDConstant.kBottomSafeHeight) , collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.allowsMultipleSelection = true
        collectionView.register(ZDPhotoCell.self, forCellWithReuseIdentifier: "ZDPhotoCell")
        collectionView.register(ZDPhotoCameraCell.self, forCellWithReuseIdentifier: "ZDPhotoCameraCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    ///  toolbar 别使用UIToolBar这个控件,坑爹
    private lazy var toolbar: UIView = {
        let toolbar = UIView(frame: CGRect(x: 0,
                                           y: ZDConstant.kScreenHeight - ZDConstant.toolbarHeight - ZDConstant.kBottomSafeHeight,
                                           width: ZDConstant.kScreenWidth,
                                           height: ZDConstant.toolbarHeight))
        toolbar.addSubview(imageCompleteButton)
        toolbar.addSubview(toolbarLine)
        toolbar.addSubview(previewButton)
        toolbar.addSubview(originalImageButton)
        toolbar.addSubview(imagesSizeLabel)
        return toolbar
    }()
    
    /// toolbar 顶部的分界线
    private lazy var toolbarLine: UIView = {
        let view = UIView(frame: CGRect(x: 0,
                                        y: 1 / UIScreen.main.scale / 2,
                                        width: ZDConstant.kScreenWidth,
                                        height: 1 / UIScreen.main.scale))
        view.backgroundColor = .lightGray
        return view
    }()
    
    /// toolbar 上面的预览按钮 有勾选的时候才进行
    private lazy var previewButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        button.isEnabled = false
        button.center = CGPoint(x: 30, y: 22)
        button.addTarget(self, action: #selector(previewButtonAction), for: .touchUpInside)
        button.setTitle("预览", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setTitleColor(UIColor.lightGreen, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        return button
    }()
    
    /// toolbar 上面的原图按钮
    private lazy var originalImageButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
        button.center = CGPoint(x: 100, y: 22)
        button.addTarget(self, action: #selector(originalImageButtonAction(_:)), for: .touchUpInside)
        button.setTitle("原图", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.setTitleColor(.gray, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.setImage(UIImage(namedInBundle: "photo_original_normal"), for: .normal)
        button.setImage(UIImage(namedInBundle: "photo_original_select"), for: .selected)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        return button
    }()
    
    /// toolbar 原图大小的Label
    private lazy var imagesSizeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        label.numberOfLines = 0
        label.center = CGPoint(x: 180, y: 22)
        label.textColor = .black
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    ///  完成按钮
    private lazy var imageCompleteButton: ZDCompleteButton = {
        let imageCompleteButton = ZDCompleteButton()
        imageCompleteButton.isEnabled = false
        imageCompleteButton.center = CGPoint(x: UIScreen.main.bounds.size.width - 50, y: 22)
        imageCompleteButton.addTarget(target: self, action: #selector(selectImageComplete))
        return imageCompleteButton
    }()
    
    ///  缩略图大小
    private var assetGridThumbnailSize: CGSize = {
        let scale = UIScreen.main.scale
        let width =  (UIScreen.main.bounds.size.width / 3 - UIScreen.main.scale) * scale
        return CGSize(width: width, height: width)
    }()
    
    ///  相薄view的背景
    private lazy var albumBackgroundView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: naviBar.frame.height, width: ZDConstant.kScreenWidth, height: ZDConstant.kScreenHeight - naviBar.frame.height))
        view.isHidden = true
        view.alpha = 0
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                         action: #selector(albumBackgroundViewAction)))
        return view
    }()
    
    ///  相薄view
    private lazy var albumView: ZDAlbumListView = {
        let albumView = ZDAlbumListView(frame: CGRect(x: 0, y: -360, width: UIScreen.main.bounds.size.width, height: 360))
        albumView.delegate = self
        return albumView
    }()
    
    /// 资源模型数组
    private lazy var assets = [ZDAssetModel]()
    
    /// 没有视频的资源数组
    private lazy var noVideoAssets = [ZDAssetModel]()
    
    /// 相册模型数组
    private lazy var albums = [ZDAlbumModel]()
    
    /// 被选中的资源模型数组, 预览做准备
    private lazy var selectAssets = [ZDAssetModel]()
    
    /// 选择类型
    private var assetTypeSet: Set<ZDAssetType> = Set()
    
    /// 是否仅仅刷新cell上的num
    private var onlyRefreshSelectNum = false

    //MARK:- viewDidLoad
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        resetCachedAssets()
        setUpUI()
        onInitData()
        onInitEvent()
    }
    
    //MARK:- viewWillAppear
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        //navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    //MARK:- viewWillDisappear
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        //navigationController?.setNavigationBarHidden(false, animated: false)
    }

    //MARK:- 内存告警
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        resetCachedAssets()
    }
    
    //MARK:- 缓存重置
    private func resetCachedAssets() {
        PHCachingImageManager().stopCachingImagesForAllAssets()
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        view.backgroundColor = UIColor.white
        navigationController?.navigationBar.isHidden = true
        
        view.addSubview(collectionView)
        view.addSubview(toolbar)
        view.addSubview(albumBackgroundView)
        view.addSubview(albumView)
        view.addSubview(naviBar)
        view.bringSubview(toFront: naviBar)
    }
    
    //MARK:- 初始化数据
    private func onInitData() {
        
        manager.isAllowGif = isAllowGif
        manager.isAllowLive = isAllowLive
        manager.isAllowVideo = isAllowVideo
        manager.isAllowTakePhoto = isAllowTakePhoto
        manager.isAllowCaputreVideo = isAllowCaputreVideo
        manager.isAllowCropper = isAllowCropper
        manager.isAllowShowLive = isAllowShowLive
        manager.isAllowShowGif = isAllowShowGif
        manager.isShowSelectCount = isShowSelectCount
        manager.rowImageCount = rowImageCount
        manager.cropFrame = cropFrame
        maxSelected = isAllowCropper ? 1 : maxSelected
        manager.maxSelected = maxSelected
        manager.maxVideoTime = maxVideoTime
        
        //  判断是否授权
        ZDPhotoManager.default.authorizationStatus { (isOK) in
            if isOK {
                ZDPhotoManager.default.getAllAlbums(allowPickingVideo: self.isAllowVideo, allowPickingImage: true, callback: { (albums) in
                    self.albums = albums
                    guard let model = albums.first else { return }
                    self.naviBar.setTitle(model.name)
                    
                    //  获取既有视频又有图片的资源数组
                    ZDPhotoManager.default.getAllAssetOfAlbum(model: model, allowPickingVideo: self.isAllowVideo, allowPickingImage: true, callback: { (assets) in
                        self.refreshCollectionView(assets: assets)
                    })
                    
                    //  获取只有图片的资源数组
                    ZDPhotoManager.default.getAllAssetOfAlbum(model: model, allowPickingVideo: false, allowPickingImage: true, callback: { (assets) in
                        self.noVideoAssets = assets
                    })
                    
                })
            }else {
                
            }
        }
    }
    
    //MARK:- 初始化事件
    private func onInitEvent() {
        
        naviBar.backButtonCallback = { [weak self] backButton in
            self?.backAction()
        }
        
        naviBar.titleButtonCallback = { [weak self] titleButton in
            self?.titleButtonAction(titleButton)
        }
        
        naviBar.rightButtonCallback = { [weak self] rightbutton in
            self?.pushToPhotoCropController()
        }
        
    }
    
    //MARK:- 点击事件
    
    //  返回事件
    @objc private func backAction() {
        
        //  不知道为啥 这个相册在dissmiss的时候回在最顶层 然后再消失 这里先隐藏处理
        albumView.isHidden = true
        
        if let viewControllers = navigationController?.viewControllers, let count = navigationController?.viewControllers.count, count > 1, viewControllers[count - 1] == self {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    //  点击了完成按钮
    @objc private func selectImageComplete() {
        print("从完成按钮这里进行点击事件")
        selectAssetsCallback?(selectAssets, assetTypeSet, originalImageButton.isSelected)
        dismiss(animated: true)
    }
    
    //  相薄的背景点击事件
    @objc private func albumBackgroundViewAction() {
        titleButtonAction(naviBar.titleButton)
    }
    
    //  中间按钮的点击事件
    @objc private func titleButtonAction(_ button: ZDPhotoTitleButton) {
        button.isSelected = !button.isSelected
        button.isUserInteractionEnabled = false
        
        var albumViewHeight = albumView.frame.height
        let showHeight = CGFloat(albums.count) * 60.0
        
        albumViewHeight = showHeight > albumViewHeight ? albumViewHeight : showHeight
        
        if (button.isSelected) {
            albumView.items = albums
            albumBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.albumView.frame = CGRect(x: 0, y: self.naviBar.frame.height, width: self.view.frame.width, height: albumViewHeight)
                self.albumView.tableView.frame = CGRect(x: 0, y: 15, width: self.view.frame.width, height: albumViewHeight)
                button.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            }, completion: { (finish) in
                UIView.animate(withDuration: 0.25, animations: {
                    self.albumView.tableView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: albumViewHeight)
                }, completion: { (finish) in
                    button.isUserInteractionEnabled = true
                })
            })
            
            UIView.animate(withDuration: 0.45, animations: {
                self.albumBackgroundView.alpha = 1.0
            })
        }else {
            UIView.animate(withDuration: 0.45, animations: {
                self.albumBackgroundView.alpha = 0.0
            }, completion: { (finish) in
                self.albumBackgroundView.isHidden = true
                button.isUserInteractionEnabled = true
            })
            
            UIView.animate(withDuration: 0.25, animations: {
                self.albumView.tableView.frame = CGRect(x: 0, y: 15, width: self.view.frame.width, height: albumViewHeight)
                button.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(2.0 * Double.pi))
            }, completion: { (finish) in
                self.albumView.tableView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 360)
                self.albumView.frame = CGRect(x: 0, y: -360, width: self.view.bounds.size.width, height: 360)
            })
        }
    }
    
    //MARK:- 预览按钮的点击事件
    @objc private func previewButtonAction() {
        let indexPath = IndexPath(item: 0, section: 0)
        pushToPhotoBrowserController(assets: selectAssets, indexPath: indexPath, selectAssets: selectAssets)
    }
    
    //MARK:- 原图按钮的点击事件
    @objc private func originalImageButtonAction(_ button: UIButton) {
        button.isSelected = !button.isSelected
    }
    
    //MARK:- 滑动到最底部
    private func scrollToCollectionViewBottom() {
        let indexPath = IndexPath(item: collectionView.numberOfItems(inSection: 0) - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
    }
    
    //MARK:- 点击cell的选择按钮来改变cell与底部栏的状态
    /// 点击cell的选择按钮来改变cell与底部栏的状态
    ///
    /// - Parameters:
    ///   - cell: ImageCollectionViewCell
    ///   - isSelected: 是否被选中
    ///   - indexPath: 行列
    private func cellAndToolbarStatusChange(cell: ZDPhotoCell, isSelected: Bool, indexPath: IndexPath) {
        if isSelected {
            
            //  如果选择的数量大于限制的规定数量,弹窗拦截并返回
            if selectAssets.count >= maxSelected {
                cell.selectCellButton.isSelected = false
                
                if isAllowCropper {
                    ZDPhotoManager.default.showAlert(controller: self, message: "剪裁图片只能选择1张照片!")
                }else {
                    ZDPhotoManager.default.showAlert(controller: self)
                }
                
                return
            }
            
            //  如果保持的类型与当前的类型不一致,弹窗拦截并返回
            if let assetType = assetTypeSet.first, assetType != cell.asset.type {
                cell.selectCellButton.isSelected = false
                ZDPhotoManager.default.showAlert(controller: self, message: "照片与视频不可同时选择!")
                return
            }
            
            //  如果保持的类型与当前的类型一致,并且都是视频,弹窗拦截并返回
            if let assetType = assetTypeSet.first, assetType == cell.asset.type, assetType == .video {
                cell.selectCellButton.isSelected = false
                ZDPhotoManager.default.showAlert(controller: self, message: "视频只能选择一个!")
                return
            }
            
            //  正常状态
            
            //  模型状态更改
            cell.asset.isSelect = true
            
            //  数组添加
            selectAssets.append(cell.asset)

            //  改变完成按钮数字
            imageCompleteButton.number = selectAssets.count
            if selectAssets.count > 0 && !imageCompleteButton.isEnabled && !previewButton.isEnabled{
                imageCompleteButton.isEnabled = true
                previewButton.isEnabled = true
                
                //  添加选择的类型
                assetTypeSet.insert(cell.asset.type)
            }
            
        }else {
            //  模型状态更改
            cell.asset.isSelect = false

            //  数组移除
            selectAssets.removeZDAssetModel(cell.asset)
            
            //  改变完成按钮数字
            imageCompleteButton.number = self.selectAssets.count
            if selectAssets.count == 0 {
                imageCompleteButton.isEnabled = false
                previewButton.isEnabled = false
                
                //  移除类型
                assetTypeSet.removeAll()
            }
        }
        
        albumView.selectAssets = selectAssets
        
        //  剪切按钮是否显示 被选择的资源数组大于0 并且允许剪裁 资源类型set大于0 而且为照片类型
        naviBar.rightButton.isHidden = !(selectAssets.count > 0 && isAllowCropper && assetTypeSet.count > 0 && assetTypeSet.first! == .photo)
        
        //  刷新原图大小
        refreshImagesSizeLabel(assets: selectAssets)
        
        //  如果显示编号 需要刷新
        if isShowSelectCount {
            UIView.performWithoutAnimation {
                self.collectionView.reloadData()
                //self.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    //MARK:- 刷新选择图片的大小的Label
    private func refreshImagesSizeLabel(assets: [ZDAssetModel]) {
        if selectAssets.count == 0 {
            self.imagesSizeLabel.text = nil
            return
        }
        
        ZDPhotoManager.default.getPhotosSize(models: selectAssets) { (sizeString, size) in
            self.imagesSizeLabel.text = sizeString
        }
    }
    
    
    //MARK:- 刷新collectioView
    private func refreshCollectionView(assets: [ZDAssetModel]) {
        self.assets = assets
        collectionView.reloadData()
        scrollToCollectionViewBottom()
    }
    
    //MARK:- 去预览界面
    private func pushToPhotoBrowserController(assets: [ZDAssetModel], indexPath: IndexPath, selectAssets: [ZDAssetModel]) {
        let browserController = ZDPhotoBrowserController(assets: assets,
                                                         indexPath: indexPath,
                                                         selectAssets: selectAssets,
                                                         assetTypeSet: assetTypeSet,
                                                         isSelected: originalImageButton.isSelected)
        browserController.pickerVC = self
        navigationController?.pushViewController(browserController, animated: true)
        
        browserController.selectAssetsCallback = { selectAssets, assetTypeSet, isSelected in
            self.assetTypeSet = assetTypeSet
            self.selectAssets = selectAssets
            self.albumView.selectAssets = selectAssets
            self.imageCompleteButton.number = selectAssets.count
            self.imageCompleteButton.isEnabled = selectAssets.count > 0
            self.previewButton.isEnabled = selectAssets.count > 0
            self.originalImageButton.isSelected = isSelected
            self.collectionView.reloadData()
            
            //  刷新原图大小
            self.refreshImagesSizeLabel(assets: selectAssets)
        }
    }
    
    //MARK:- 去剪裁界面
    private func pushToPhotoCropController() {
        
        //  前面保证了selectAssets.count > 0 的判断才显示剪裁按钮 所以这里可以first!
        let photoCropController = ZDPhotoCropController(asset: selectAssets.first!, cropFrame: cropFrame)
        photoCropController.pickerVC = self
        navigationController?.pushViewController(photoCropController, animated: true)
    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDPhotoPickerController销毁了")
    }
}

extension ZDPhotoPickerController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        
        if isAllowTakePhoto || isAllowCaputreVideo {
            return assets.count + 1
        } else {
            return assets.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == assets.count && (isAllowTakePhoto || isAllowCaputreVideo ) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZDPhotoCameraCell",for: indexPath) as! ZDPhotoCameraCell
            return cell
        }else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZDPhotoCell",for: indexPath) as! ZDPhotoCell
            
            //  倒叙排列
            //let index = indexPath.row == 0 ? 0 : assets.count - indexPath.item
            
            let asset = assets[indexPath.item]
            asset.isSelect = false
            asset.selectNum = 0
            
            //  保证在滑动的过程中 被选中的cell被正确的找到
            for (index,selectAsset) in selectAssets.enumerated() {
                if asset.asset == selectAsset.asset {
                    print("selectAsset: \(selectAsset.asset.localIdentifier), asset: \(asset.asset.localIdentifier)")
                    
                    selectAsset.isSelect = true
                    selectAsset.selectNum = index + 1
                    
                    asset.isSelect = true
                    asset.selectNum = index + 1
                }
            }
            
            cell.asset = asset
            
            //  回调闭包 多个weak避免了循环引用的问题
            cell.selectCallback = { [weak self, weak cell] isSelected in
                guard let unwrapCell = cell else { return }
                self?.cellAndToolbarStatusChange(cell: unwrapCell, isSelected: isSelected, indexPath: indexPath)
            }
            
            return cell
        }
        
    }
}

extension ZDPhotoPickerController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == assets.count {
            
            //  拦截模拟器
            if Platform.isSimulator {
                ZDPhotoManager.default.showAlert(controller: self, message: "模拟器无法调用摄像头!")
                return
            }
            let cameraController = ZDPhotoCameraController()
            cameraController.pickerVC = self
            navigationController?.pushViewController(cameraController, animated: true)
        }else {
            
            /*
             这里预览逻辑仿照了新浪微博的逻辑:
             如果点击的cell类型为图片 那么预览控制器进入的就是非视频资源的预览
             如果点击的cell类型为视频 那么预览控制器进入的就是仅有改视频资源的预览
             */
            
            let cell = collectionView.cellForItem(at: indexPath) as! ZDPhotoCell
            
            //  倒叙的问题
            //let index = indexPath.row == 0 ? 0 : assets.count - indexPath.item
            //let newIndexPath = IndexPath(item: index, section: 0)
            
            var newIndexPath = IndexPath(item: 0, section: 0)
            var newAssets: [ZDAssetModel]
            if cell.asset.type == .photo {
                for (index, asset) in noVideoAssets.enumerated() {
                    if asset.asset == cell.asset.asset {
                        newIndexPath = IndexPath(item: index, section: 0)
                    }
                }
                newAssets = noVideoAssets
            }else {
                newAssets = [cell.asset]
            }
            
            pushToPhotoBrowserController(assets: newAssets, indexPath: newIndexPath, selectAssets: selectAssets)
        }
        
    }
}

extension ZDPhotoPickerController: ZDAlbumListViewDelegate {
    func tableView(_ tableView: UITableView, cellClick item: ZDAlbumModel, isAnimated: Bool) {
        albumBackgroundViewAction()
        naviBar.setTitle(item.name)
        
        ZDPhotoManager.default.getAllAssetOfAlbum(model: item, allowPickingVideo: isAllowVideo, allowPickingImage: true, callback: { (assets) in
            self.refreshCollectionView(assets: assets)
        })
        
        ZDPhotoManager.default.getAllAssetOfAlbum(model: item, allowPickingVideo: false, allowPickingImage: true, callback: { (assets) in
            self.noVideoAssets = assets
        })

    }
}
