//
//  ImagePickerController.swift
//  JiuRongCarERP
//
//  Created by dy on 2018/1/18.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit
import Photos

/// 相簿列表页控制器
class ImagePickerController: UIViewController {
    //MARK: 属性设置
    
    //  tableView
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: ImageConstant.kScreenWidth, height: ImageConstant.kScreenHeight), style: .plain)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ImagePickerControllerCell")
        return tableView
    }()
    
    //  相簿列表项集合
    var items = [ImageAlbumItem]()
    
    //  每次最多可选择的照片数量
    var maxSelected: Int = 9
    
    //  照片选择完毕后的回调
    var completeCallback:((_ assets: [PHAsset])->()) = { _ in }
    
    //MARK:- <##>viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        //  设置标题
        title = "相簿"
        //  添加导航栏右侧的取消按钮
        let rightBarItem = UIBarButtonItem(title: "取消", style: .plain, target: self,
                                           action:#selector(cancel) )
        navigationItem.rightBarButtonItem = rightBarItem
        
        //  获取所有的相册
        ImageManager.default.getAllAlbums(includVideo: false) { (items) in
            self.items = items
            self.backToMainThreadPush()
        }
    }
        
    private func backToMainThreadPush() {
        //  异步加载表格数据,需要在主线程中调用reloadData() 方法
        DispatchQueue.main.async{
            self.tableView.reloadData()
            
            //  首次进来后直接进入第一个相册图片展示页面（相机胶卷）
            let imageSelectController = ImageSelectController()
            imageSelectController.title = self.items.first?.title
            imageSelectController.assetsFetchResults = self.items.first?.fetchResult ?? PHFetchResult<PHAsset>()
            imageSelectController.items = self.items
            imageSelectController.completeCallback = self.completeCallback
            imageSelectController.maxSelected = self.maxSelected
            self.navigationController?.pushViewController(imageSelectController,
                                                          animated: false)
        }
    }
    
    //  取消按钮点击
    @objc func cancel() {
        //退出当前视图控制器
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        print("ImagePickerController销毁了")
    }
}

//相簿列表页控制器UITableViewDelegate,UITableViewDataSource协议方法的实现
extension ImagePickerController: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //  表格单元格数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    //设置单元格内容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            //  同一形式的单元格重复使用，在声明时已注册
            //let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePickerControllerCell", for: indexPath)
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "ImagePickerControllerCell")
            let item = items[indexPath.row]
            cell.textLabel?.text = "\(item.title ?? "") "
            cell.detailTextLabel?.text = "\(item.fetchResult.count)"
            cell.imageView?.image = item.image
            
            return cell
    }
    
    //表格单元格选中
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let imageSelectController = ImageSelectController()
        imageSelectController.title = items[indexPath.row].title
        imageSelectController.assetsFetchResults = items[indexPath.row].fetchResult
        imageSelectController.completeCallback = completeCallback
        imageSelectController.maxSelected = maxSelected
        imageSelectController.items = items
        self.navigationController?.pushViewController(imageSelectController,
                                                      animated: true)
    }
}

extension UIViewController {
    //HGImagePicker提供给外部调用的接口，同于显示图片选择页面
    func presentImagePicker(maxSelected:Int = 9,
                            completeCallback: @escaping ((_ assets: [PHAsset])->()))
        -> ImagePickerController {
            //获取图片选择视图控制器
        let vc = ImagePickerController()
        //设置选择完毕后的回调
        vc.completeCallback = completeCallback
        //设置图片最多选择的数量
        vc.maxSelected = maxSelected
        //将图片选择视图控制器外添加个导航控制器，并显示
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
        return vc
    }
}
