//
//  ImagePreviewController.swift
//  JiuRongCarERP
//
//  Created by HSGH on 2018/2/12.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit
import Photos

/// 图片浏览控制器
class ImagePreviewController: UIViewController {
    //MARK:- 属性设置
    
    //  存储图片数组
    private var assetsFetchResults: PHFetchResult<PHAsset>
    
    //  默认显示的图片索引
    private var indexPath: IndexPath
    
    //  隐藏状态栏,目前不隐藏
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    //  用来放置各个图片单元
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
        collectionView.register(ImagePreviewCell.self, forCellWithReuseIdentifier: "ImagePreviewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        //  滚动到点击的图片页面
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        
        return collectionView
    }()
    
    //  pageControl,目前不添加上
    fileprivate lazy var pageControl: UIPageControl = {
        //  设置页控制器
        let pageControl = UIPageControl()
        pageControl.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 20)
        pageControl.numberOfPages = assetsFetchResults.count
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPage = indexPath.item
        pageControl.isHidden = assetsFetchResults.count == 1 ? true : false
        return pageControl
    }()
    
    //  下载按钮,目前不添加上
    private lazy var downloanButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: kScreenWidth - 20 - 44, y: kScreenHeight - 20 - 44, width: 44, height: 44)
        button.setImage(UIImage(named: "image_download"), for: .normal)
        button.addTarget(self, action: #selector(downloadAction(_ :)), for: .touchUpInside)
        return button
    }()
    
    //  全局的图片 用于保存到相册使用
    fileprivate var asset = PHAsset()
    
    //MARK:- 初始化
    init(assetsFetchResults: PHFetchResult<PHAsset>, indexPath: IndexPath){
        self.assetsFetchResults = assetsFetchResults
        self.indexPath = indexPath
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
    
    //MARK:- 预览页面还是需要使用自定义的导航栏呀
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
        
        //  设置modal的展现方式
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        
        //  collectionView
        view.addSubview(collectionView)
        
        //  pageControl
        //view.addSubview(pageControl)
        
        //  下载按钮
        //view.addSubview(downloanButton)
        //view.bringSubview(toFront: downloanButton)
    }
    
    //MARK:- 下载按钮的点击事件
    @objc private func downloadAction(_ button: UIButton) {
        /*
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: self.asset)
        }) { (isSuccess, error) in
            let message = isSuccess ? "图片保存成功！" : "图片保存失败！"
            DispatchQueue.main.async {
                Hub.show(view: self.view, message: message)
            }
        }
        */
    }
    
    deinit {
        print("ImagePreviewController销毁了")
    }
}

//MARK:- ImagePreviewVC的CollectionView相关协议方法实现
extension ImagePreviewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    //  collectionView单元区域数量
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //  collectionView单元格数量
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetsFetchResults.count
    }
    
    //  collectionView单元格创建
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePreviewCell", for: indexPath) as! ImagePreviewCell
        
        cell.dismissCallback = { [weak self] in
            self?.dismiss(animated: false, completion: nil)
        }
        
        if assetsFetchResults.count >= indexPath.row {
            let asset = self.assetsFetchResults[indexPath.row]
            cell.asset = asset
            self.asset = asset
        }
        
        return cell
    }
    
    //  collectionView将要显示
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ImagePreviewCell{
            //  由于单元格是复用的，所以要重置内部元素尺寸
            cell.resetSize()
            
            //  设置页控制器当前页
            pageControl.currentPage = indexPath.item
            title = "\(indexPath.item + 1)/\(assetsFetchResults.count)"
        }
    }
}
