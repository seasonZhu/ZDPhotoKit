//
//  ImageSelectController.swift
//  JiuRongCarERP
//
//  Created by dy on 2018/1/17.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit
import Photos

class ImageSelectController: UIViewController {
    //MARK: 属性设置
    
    //  layout
    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.size.width / 3 - UIScreen.main.scale, height: UIScreen.main.bounds.size.width / 3 - UIScreen.main.scale)
        layout.minimumLineSpacing = 1 * UIScreen.main.scale
        layout.minimumInteritemSpacing = 1 * UIScreen.main.scale
        return layout
    }()
    
    //  collectionView
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: ImageConstant.kNavigationBarHeight, width: ImageConstant.kScreenWidth, height: ImageConstant.kScreenHeight - ImageConstant.toolbarHeight - ImageConstant.kNavigationBarHeight - ImageConstant.bottomSafeHeight) , collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.allowsMultipleSelection = true
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCollectionViewCell")
        collectionView.register(PhotoCameraCell.self, forCellWithReuseIdentifier: "PhotoCameraCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    //  toolbar 别使用UIToolBar这个控件,坑爹
    private lazy var toolbar: UIView = {
        let toolbar = UIView(frame: CGRect(x: 0,
                                           y: ImageConstant.kScreenHeight - ImageConstant.toolbarHeight - ImageConstant.bottomSafeHeight,
                                           width: ImageConstant.kScreenWidth,
                                           height: ImageConstant.toolbarHeight))
        toolbar.addSubview(imageCompleteButton)
        return toolbar
    }()
    
    //  完成按钮
    fileprivate lazy var imageCompleteButton: ImageCompleteButton = {
        let imageCompleteButton = ImageCompleteButton()
        imageCompleteButton.isEnabled = false
        imageCompleteButton.center = CGPoint(x: UIScreen.main.bounds.size.width - 50, y: 22)
        imageCompleteButton.addTarget(target: self, action: #selector(selectImageComplete))
        return imageCompleteButton
    }()
    
    //  右侧按钮
    private lazy var rightBarItem = UIBarButtonItem(title: "取消", style: .plain,
                                       target: self, action: #selector(cancel))
    
    //  缩略图大小
    private var assetGridThumbnailSize: CGSize = {
        let scale = UIScreen.main.scale
        let width =  (UIScreen.main.bounds.size.width / 3 - UIScreen.main.scale) * scale
        return CGSize(width: width, height: width)
    }()
    
    //  navi上的中间按钮
    private lazy var headerButton: HeaderButton = {
        let button = HeaderButton()
        button.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 17)
        button.setTitle(items.first?.title, for: .normal)
        button.setTitleColor(UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), for: .normal)
        button.setImage(UIImage(named:"headlines_icon_arrow"), for: .normal)
        button.addTarget(self, action: #selector(headerButtonAction(_ :)), for: .touchUpInside)
        //button.bounds.size = CGSize(width: ImageConstant.kScreenWidth - 100, height: 44)
        return button
    }()
    
    //  相薄view的背景
    private lazy var albumBackgroundView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: ImageConstant.kNavigationBarHeight, width: ImageConstant.kScreenWidth, height: ImageConstant.kScreenHeight - ImageConstant.kNavigationBarHeight))
        view.isHidden = true
        view.alpha = 0
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                         action: #selector(albumBackgroundViewAction)))
        return view
    }()
    
    //  相薄view
    private lazy var albumView: ImageAlbumView = {
        let albumView = ImageAlbumView(frame: CGRect(x: 0, y: -360, width: UIScreen.main.bounds.size.width, height: 360))
        return albumView
    }()
    
    //  每次最多可选择的照片数量
    var maxSelected: Int = 9
    
    //  取得的资源结果，用了存放的PHAsset
    var assetsFetchResults = PHFetchResult<PHAsset>()
    
    //  照片选择完毕后的回调
    var completeCallback: (_ assets: [PHAsset]) -> () = { _ in }
    
    //  indexPath数组
    private var selectIndexPaths = [IndexPath]()
    
    var items = [ImageAlbumItem]()

    //MARK:- 初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
        
        view.backgroundColor = UIColor.white
        view.addSubview(collectionView)
        view.addSubview(toolbar)
        
        view.addSubview(albumBackgroundView)
        view.addSubview(albumView)
        albumView.delegate = self
        
        navigationItem.rightBarButtonItem = rightBarItem
        navigationItem.titleView = headerButton
        
        scrollToCollectionViewBottom()
    }

    //MARK:- 内存告警
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        resetCachedAssets()
    }
    
    //  重置缓存
    private func resetCachedAssets(){
        PHCachingImageManager().stopCachingImagesForAllAssets()
    }
    
    //  点击了完成按钮
    @objc private func selectImageComplete() {
        print("从完成按钮这里进行点击事件")
        //  取出已选择的图片资源
        var assets = [PHAsset]()
        for indexPath in selectIndexPaths {
            assets.append(assetsFetchResults[indexPath.row] )
        }
        
        //  调用回调函数
        navigationController?.dismiss(animated: true, completion: {
            self.completeCallback(assets)
        })
    }
    
    //  相薄的背景点击事件
    @objc private func albumBackgroundViewAction() {
        headerButtonAction(headerButton)
    }
    
    //  中间按钮的点击事件
    @objc private func headerButtonAction(_ button: HeaderButton) {
        button.isSelected = !button.isSelected
        button.isUserInteractionEnabled = false
        
        let albumViewHeight = CGFloat(items.count) * 60.0 > self.view.frame.size.height - ImageConstant.kNavigationBarHeight ? self.view.frame.size.height - ImageConstant.kNavigationBarHeight : CGFloat(items.count) * 60.0
        
        if (button.isSelected) {
            albumView.items = items
            albumBackgroundView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.albumView.frame = CGRect(x: 0, y: ImageConstant.kNavigationBarHeight, width: self.view.bounds.size.width, height: albumViewHeight)
                self.albumView.tableView.frame = CGRect(x: 0, y: 15, width: self.view.bounds.size.width, height: albumViewHeight)
                button.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            }, completion: { (finish) in
                UIView.animate(withDuration: 0.25, animations: {
                    self.albumView.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: albumViewHeight)
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
                self.albumView.tableView.frame = CGRect(x: 0, y: 15, width: self.view.bounds.size.width, height: albumViewHeight)
                //self.albumView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 0)
                button.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(2.0 * Double.pi))
            }, completion: { (finish) in
                self.albumView.tableView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 360)
                self.albumView.frame = CGRect(x: 0, y: -360, width: self.view.bounds.size.width, height: 360)
            })
        }
    }
    
    //  取消按钮点击
    @objc private func cancel() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    //  获取已选择个数
    fileprivate func selectedCount() -> Int {
        return collectionView.indexPathsForSelectedItems?.count ?? 0
    }
    
    //  滑动到最底部
    private func scrollToCollectionViewBottom() {
        let indexPath = IndexPath(item: assetsFetchResults.count, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }

    //  弹框设置
    fileprivate func showAlert() {
        //弹出提示
        let title = "你最多只能选择\(maxSelected)张照片"
        let alertController = UIAlertController(title: title, message: nil,
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title:"我知道了", style: .cancel,
                                         handler:nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    /// 点击cell的选择按钮来改变cell与底部栏的状态
    ///
    /// - Parameters:
    ///   - cell: ImageCollectionViewCell
    ///   - isSelected: 是否被选中
    ///   - indexPath: 行列
    private func cellAndImageCompleteButtonStatusChange(cell: ImageCollectionViewCell, isSelected: Bool, indexPath: IndexPath) {
        if isSelected {
            if selectIndexPaths.count >= maxSelected {
                cell.selectCellButton.isSelected = false
                showAlert()
            }else {
                selectIndexPaths.append(indexPath)
                //  改变完成按钮数字
                imageCompleteButton.number = selectIndexPaths.count
                if selectIndexPaths.count > 0 && !imageCompleteButton.isEnabled{
                    imageCompleteButton.isEnabled = true
                }
            }
        }else {
            for (index,selectIndexPath) in selectIndexPaths.enumerated() {
                if selectIndexPath == indexPath {
                    selectIndexPaths.remove(at: index)
                }
            }
            imageCompleteButton.number = selectIndexPaths.count
            //改变完成按钮数字
            if selectIndexPaths.count == 0{
                imageCompleteButton.isEnabled = false
            }
        }
    }
    
    deinit {
        print("ImageSelectController销毁了")
    }
}

extension ImageSelectController: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return assetsFetchResults.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == assetsFetchResults.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCameraCell",for: indexPath) as! PhotoCameraCell
            return cell
        }else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell",for: indexPath) as! ImageCollectionViewCell
            //  倒叙排列
            //let index = indexPath.row == 0 ? 0 : assetsFetchResults.count - indexPath.item
            let asset = assetsFetchResults[indexPath.item]
            cell.asset = asset
            cell.selectCellButton.isSelected = false
            
            //  保证在滑动的过程中 被选中的cell被正确的找到
            for selectIndexPath in selectIndexPaths {
                if selectIndexPath == indexPath {
                    print("selectIndexPath: \(selectIndexPath), indexPath: \(indexPath)")
                    cell.selectCellButton.isSelected = true
                }
            }
            
            //  回调闭包 多个weak避免了循环引用的问题
            cell.selectCallback = { [weak self, weak cell] isSelected in
                self?.cellAndImageCompleteButtonStatusChange(cell: cell!, isSelected: isSelected, indexPath: indexPath)
            }
            /*print(asset.mediaType.rawValue, asset.mediaSubtypes.rawValue)*/
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == assetsFetchResults.count {
            navigationController?.pushViewController(TakePhotoVideoController(), animated: true)
        }else {
            let _ = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
            let imagePreviewController = ImagePreviewController(assetsFetchResults: assetsFetchResults, indexPath: indexPath)
            navigationController?.pushViewController(imagePreviewController, animated: true)
        }

    }
}

extension ImageSelectController: ImageAlbumViewDelegate {
    func tableView(_ tableView: UITableView, cellClick item: ImageAlbumItem, isAnimated: Bool) {
        albumBackgroundViewAction()
        headerButton.setTitle(item.title, for: .normal)
        assetsFetchResults = item.fetchResult
        collectionView.reloadData()
        scrollToCollectionViewBottom()
    }
    
    
}

class HeaderButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleY = titleLabel?.frame.origin.y
        let titleH = titleLabel?.frame.size.height
        let titleW = titleLabel?.frame.size.width
        
        let imageY = imageView?.frame.origin.y
        let imageW = imageView?.frame.size.width
        let imageH = imageView?.frame.size.height
        
        let width = frame.size.width;
        
        titleLabel?.frame = CGRect(x: (width - (titleW! + imageW! + 5)) / 2, y: titleY!, width: titleW!, height: titleH!);
        
        imageView?.frame = CGRect(x: titleLabel!.frame.maxX + 5, y: imageY!, width: imageW!, height: imageH!)
    }
}
