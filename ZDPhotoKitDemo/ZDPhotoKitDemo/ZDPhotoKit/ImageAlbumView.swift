//
//  ImageAlbumView.swift
//  JiuRongCarERP
//
//  Created by HSGH on 2018/2/22.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit

/// ImageAlbumView的代理方法
protocol ImageAlbumViewDelegate: class {
    func tableView(_ tableView: UITableView, cellClick item: ImageAlbumItem, isAnimated: Bool)
}

/// 相册选择视图
class ImageAlbumView: UIView {
    
    //  tableView
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), style: .plain)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.lightGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ImageAlbumViewCell")
        return tableView
    }()
    
    //  代理
    weak var delegate: ImageAlbumViewDelegate?
    
    //  相册的缩略图
    fileprivate var cellImages = [UIImage]()
    
    //  相薄列表数组
    private var newItems = [ImageAlbumItem]()
    
    var items: [ImageAlbumItem] {
        set {
            newItems = newValue
            
            tableView.reloadData()
            
            if currentIndex < newItems.count {
                tableView.selectRow(at: IndexPath(row: currentIndex, section: 0), animated: false, scrollPosition: .middle)
            }

        }get {
            return newItems
        }
    }
    
    //  当前选中的
    var currentIndex = 0
    
    //MARK:- 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- 搭建界面
    private func setUpUI() {
        backgroundColor = UIColor.lightGray
        addSubview(tableView)
    }
    
    deinit {
        print("ImageAlbumView销毁了")
    }
}

//相簿列表页控制器UITableViewDelegate,UITableViewDataSource协议方法的实现
extension ImageAlbumView: UITableViewDelegate,UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //  表格单元格数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    //  设置单元格内容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            //  同一形式的单元格重复使用，在声明时已注册

            let cell = UITableViewCell(style: .value1, reuseIdentifier: "ImageAlbumViewCell")
            let item = items[indexPath.row]
            cell.textLabel?.text = "\(item.title ?? "") "
            cell.detailTextLabel?.text = "\(item.fetchResult.count)"
            cell.imageView?.image = item.image
            
            return cell
    }
    
    //  表格单元格选中
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentIndex = indexPath.row
        delegate?.tableView(tableView, cellClick: items[indexPath.row], isAnimated: true)
    }
}
