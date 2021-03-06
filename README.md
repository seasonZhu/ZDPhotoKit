# ZDPhotoKit

#### 项目介绍
这个是一款Swift编写的图片选择组件  

可以展示普通图片、Gif、LivePhoto以及视频  

可以预览普通图片、Gif、LivePhoto以及视频

可以进行相册切换

可以进行简单的剪裁   

可以进行拍照与拍摄  

可以进行图片多选与视频单选,注意视频与图片不可同时选择  

#### 目前已知的一些Bug
1. 对于Gif预览没有很好优化,使用的原生UIImage进行展示,预览的时候会比较吃内存
2. 角标显示数字的时候,点击的时候,会有闪动,是刷新cell重新获取image导致的问题,目前还没有想到比较好的方法,还请各位指教


#### 添加 ZDPhotoKit 到你的项目

[CocoaPods](http://cocoapods.org/) is the recommended way to add `ZDPhotoKit` to your project.

1.  Add a pod entry for `ZDPhotoKit` to your Podfile 

```
pod 'ZDPhotoKit'
```

2.  Install the pod(s) by running 

```
pod install
```

3.  Include `ZDPhotoKit`once you need it with 

```
import ZDPhotoKit
```

#### 例子

```
//  首次进来后直接进入第一个相册图片展示页面（相机胶卷）
let picker = ZDPhotoPickerController()
picker.isAllowGif = true
picker.isAllowLive = true
picker.isAllowVideo = true
picker.isAllowCropper = true
picker.isAllowCaputreVideo = true
picker.isAllowTakePhoto = true
picker.isAllowShowLive = true
picker.isAllowShowGif = true
picker.isShowSelectCount = false
picker.maxSelected = 5
picker.rowImageCount = 7
let navi = UINavigationController(rootViewController: picker)
present(navi, animated: true, completion: nil)

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

```


#### 说明

俗话说万事开头难,所以与其犹犹豫豫,不如先提交上来再说  

对于iOS平台其实图片选择的组件真的是很多了,然而针对Swift的组件据我了解不多  

如果你有好的组件,请告诉我,我也好好学习一下  

写这个组件,完全是基于自己个人功能需求在进行开发  

在开发过程中,我也不断的去阅读OC中优秀的图片选择组件,尤其是TZImagePickerController组件  

自己个人水平有限,还请各位指点  

我之前也在犹豫有必要加上ZD前缀名,后来想想为了避免冲突,还是加吧

后面会在简书上写一篇文章介绍如何使用这个ZDPhotoKit
  

