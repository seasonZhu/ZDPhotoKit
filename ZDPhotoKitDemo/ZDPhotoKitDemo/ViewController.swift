//
//  ViewController.swift
//  ZDPhotoKitDemo
//
//  Created by dy on 2018/6/7.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ZDPhotoKitDemo"
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 22))
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.setTitle("进入相册", for: .normal)
        button.setTitleColor(.black, for: .normal)
        view.addSubview(button)
        button.center = view.center
        
    }
    
    @objc
    private func buttonAction() {
        //  首次进来后直接进入第一个相册图片展示页面（相机胶卷）
        let picker = ZDPhotoPickerController()
        picker.isAllowGif = true
        picker.isAllowLive = true
        picker.isAllowVideo = true
        picker.isAllowCropper = true
        picker.isAllowCaputreVideo = true
        picker.isAllowTakePhoto = true
        picker.isAllowShowLive = false 
        picker.isAllowShowGif = true
        picker.isShowSelectCount = true
        picker.maxSelected = 5
        picker.rowImageCount = 7
//        picker.mainColorCallback = {
//            return UIColor.lightGray
//        }
//        picker.widgetColorCallback = {
//            return UIColor.black
//        }
        
//        let navi = UINavigationController(rootViewController: picker)
//        present(navi, animated: true, completion: nil)
        navigationController?.pushViewController(picker, animated: true)
        
        //  选择资源的回调
        picker.selectAssetsCallback = { selectAssets, assetTypeSet, isOriginal in
            for asset in selectAssets {
                print(asset)
            }
            print(assetTypeSet.first.debugDescription)
            print(isOriginal)
        }
        
        //  拍照的回调
        picker.takePhotoCallback = { image in
            print(image)
        }
        
        //  拍摄的回调
        picker.takeVideoCallback = { image, url in
            print(image)
            print(url)
        }
        
        //  剪裁的回调
        picker.selectCropImageCallback = { image in
            print(image)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
