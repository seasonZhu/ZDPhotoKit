//
//  ZDPlayerManager.swift
//  JiuRongCarERP
//
//  Created by qinbo on 2018/6/5.
//  Copyright © 2018年 jiurongcar. All rights reserved.
//

import UIKit

/// 播放器代理
protocol ZDPlayerManagerDelegate : class{
    
    func readyToPlay(_ playerManager: ZDPlayerManager,playItem:AVPlayerItem)
    
    func playerManager(_ playerManager: ZDPlayerManager, totalTime: String, currentTime: String, progress: CGFloat)
    
    func playerManager(_ playerManager: ZDPlayerManager, loadPercent: CGFloat)
    
    func playEnd()
}

extension ZDPlayerManagerDelegate{
    
    func readyToPlay(_ playerManager: ZDPlayerManager,playItem:AVPlayerItem){}
    
    func playerManager(_ playerManager: ZDPlayerManager, totalTime: String, currentTime: String, progress: CGFloat){}
    
    func playerManager(_ playerManager: ZDPlayerManager, loadPercent: CGFloat){}
    
    func playEnd(){}
}


/// 播放器管理
class ZDPlayerManager : NSObject{
    
    //MARK:- 默认播放器
    static let `default` : ZDPlayerManager = {
        let manage = ZDPlayerManager()
        NotificationCenter.default.addObserver(manage, selector: #selector(playEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        return manage
    }()
    
    private override init() {}
    
    /// 代理
    weak var delegate: ZDPlayerManagerDelegate?
    
    ///  player
    lazy var player: AVPlayer = {
        let plar = AVPlayer()
        plar.isMuted = true
        return plar
    }()
    
    
    private var isRegisterStatus=false
    private var lastPlayerItemUrl:String?   //上一次播放的视频
    private var currentPlayerItemUrl:String?    //当前播放的视频
    //var lastPlayerTime:CMTime?  //上一次视频结束的位置
    private var playerItem:AVPlayerItem?
    private var urlLocalVideo:String?
    private var urlWebVideo:String?
    var moveToSeek:CMTime?  //第一次播放移动的位置
    
    var playState:PlayStateEnum = .normal  //播放状态
    
    
    //MARK:- 暂停
    func pasuse() {
        if(playState == .pause){return}
        //self.lastPlayerTime = playerItem?.currentTime()
        player.pause()
        
        playState = .pause
    }
    
    //MARK:- 停止播放
    func stop() {
        if(playState == .normal){return}
        player.pause()
        playState = .normal
    }
    
    //MARK:- 播放
    func play(_ seek:CMTime=kCMTimeZero) {
        if(playState == .playing){return}
        player.seek(to: moveToSeek ?? seek)
        self.moveToSeek = nil
        player.play()
        playState = .playing
    }
    
    //MARK:- 释放播放器
    func releasePlayer(){
        if(playState == .normal){return}
        player.pause()
        player.replaceCurrentItem(with: nil)
        playerItem=nil
        
        playState = .normal
    }
    
    /// 获取编码后的Url
    func getPlayUrl(url:String?)->String{
        return url?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) ?? ""
    }
    
    //MARK:- 准备播放的方法
//    func prepareToPlay(_ mediaConfig:MediaViewConfig?) {
//        if(mediaConfig == nil ||
//            ObjectUtils.isEmptyAnd(arr:mediaConfig?.pathUrl,mediaConfig?.mediaUrl).isEmpty) {
//            return
//        }
//
//        urlLocalVideo=mediaConfig?.pathUrl
//        urlWebVideo=mediaConfig?.mediaUrl
//
//        let isLocalVideo = ObjectUtils.nonEmptyStr(urlLocalVideo)
//        guard let url = isLocalVideo ?  URL(fileURLWithPath: getPlayUrl(url: urlLocalVideo)) : URL(string: getPlayUrl(url: urlWebVideo)) else {
//            return
//        }
//
//        let willPlayUrl=isLocalVideo ? urlLocalVideo : urlWebVideo
//        if ObjectUtils.equals(willPlayUrl, self.currentPlayerItemUrl) &&
//            playState == .prepare{
//            return
//        }
//        self.currentPlayerItemUrl=isLocalVideo ? urlLocalVideo : urlWebVideo
//        playURL(url)
//    }
    
    //MARK:- 根据进度进行播放
    func playWithProgresss(_ progress: CGFloat) {
        stop()
        player.seek(to: CMTimeMake(Int64(fetchTotalTime()) * Int64(progress), 1)) { [weak self]  (finish) in
            self?.play()
        }
    }
    
    /// 获取当前播放的位置
    func getCurrentPlayerPosition() -> CMTime? {
        return playerItem?.currentTime()
    }
    
    //MARK:- KVO,网络状态：loadedTimeRanges，playbackBufferEmpty，playbackLikelyToKeepUp
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let playerItem = object as? AVPlayerItem else { return }
        playState = .resolved
        if keyPath == "status"{
            
            playerItem.removeObserver(self, forKeyPath: "status")
            switch playerItem.status {
            case .unknown:
                break
            case .failed:
//                if ObjectUtils.nonEmptyStr(urlWebVideo),let videoURL = URL(string: getPlayUrl(url: urlWebVideo)) {
//                    self.currentPlayerItemUrl=urlWebVideo
//                    playURL(videoURL)
//                }
                break
            case .readyToPlay:
//                if(!ObjectUtils.equals(lastPlayerItemUrl, currentPlayerItemUrl)){
//                    self.lastPlayerItemUrl=currentPlayerItemUrl
//                    //play(lastPlayerTime ?? kCMTimeZero)
//                }
                play()
                delegate?.readyToPlay(self,playItem:playerItem)
            }
        } else if keyPath == "loadedTimeRanges" {
            let availabletime = availableDuration()
            let totalTime = fetchTotalTime()
            var percent = CGFloat(availabletime) / CGFloat(totalTime)
            if percent > 1 {
                percent = 0
            }
            delegate?.playerManager(self, loadPercent: percent)
        }
    }
    
    //// 播放URL
    private func playURL(_ url:URL){
        self.playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: self.playerItem)
        self.playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        playState = .prepare
    }
    
    
    //MARK:- 定时器方法
    @objc private func timerAction() {
        let totalTime = secondChangeToTimeFormat(time: fetchTotalTime())
        let currentTime = secondChangeToTimeFormat(time: fetchCurrentTime())
        let progress = fetchProgressValue()
        delegate?.playerManager(self, totalTime: totalTime, currentTime: currentTime, progress: progress)
    }
    
    
    //MARK:- 播放完成的方法
    @objc func playEnd() {
        pasuse()
        delegate?.playEnd()
        playState = .end
    }
    
    //MARK:- 获取当前时间
    private func fetchCurrentTime() -> Int {
        guard let time = playerItem?.currentTime() else { return 0 }
        if time.timescale == 0 { return 0 }
        return Int(time.value) / Int(time.timescale)
    }
    
    //MARK:- 获取总时间
    private func fetchTotalTime() -> Int {
        guard let time = playerItem?.duration else { return 0 }
        if time.timescale == 0 { return 0 }
        return Int(time.value) / Int(time.timescale)
    }
    
    //MARK:- 获取进度
    private func fetchProgressValue() -> CGFloat {
        return CGFloat(fetchCurrentTime()) / CGFloat(fetchTotalTime())
    }
    
    //MARK:- 获取缓冲进度
    private func availableDuration() -> Double {
        guard let loadedTimeRanges = playerItem?.loadedTimeRanges else {return 0}
        
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else {return 0}
        
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        
        let result = startSeconds + durationSeconds
        return result
    }
    
    //MARK:- 秒转分与时
    private func secondChangeToTimeFormat(time: Int) -> String {
        let min = time / 60
        let second = time % 60
        return String(format: "%.2ld:%.2ld", min,second)
    }
}



/// 播放状态
enum PlayStateEnum : Int{
    
    case
    //正常状态
    normal = 0,
    //准备状态
    prepare = 1,
    //解析完成
    resolved = 2,
    //播放状态
    playing = 3,
    //暂停状态
    pause = 4,
    //播放结束
    end = 5
}
