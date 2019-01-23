//
//  ZDAlbumListView.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/5/30.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// ZDAlbumListView的代理方法
protocol ZDAlbumListViewDelegate: class {
    func tableView(_ tableView: UITableView, cellClick item: ZDAlbumModel, isAnimated: Bool)
}


/// 相册列表
class ZDAlbumListView: UIView {
    
    var selectAssets = [ZDAssetModel]()
    
    /// 复用字符串
    private let cellIdentifier = "ZDAlbumListViewCell"
    
    //  tableView
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), style: .plain)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.register(ZDAlbumListViewCell.self, forCellReuseIdentifier: cellIdentifier)
        return tableView
    }()
    
    //  代理
    weak var delegate: ZDAlbumListViewDelegate?
    
    //  相册的缩略图
    fileprivate var cellImages = [UIImage]()
    
    //  相薄列表数组
    private var newItems = [ZDAlbumModel]()
    
    var items: [ZDAlbumModel] {
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
        backgroundColor = UIColor.white
        addSubview(tableView)
    }
    
    //MARK:- 析构函数
    deinit {
        print("ZDAlbumListView销毁了")
    }
}

//相簿列表页控制器UITableViewDelegate,UITableViewDataSource协议方法的实现
extension ZDAlbumListView: UITableViewDataSource {
    
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
            
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ZDAlbumListViewCell
        let model = items[indexPath.row]
        model.selectAssets = selectAssets
        cell.model = model
        return cell
    }
}

extension ZDAlbumListView: UITableViewDelegate {
    
    //  表格单元格选中
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentIndex = indexPath.row
        delegate?.tableView(tableView, cellClick: items[indexPath.row], isAnimated: true)
    }
}
