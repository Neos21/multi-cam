//
//  ViewController.swift
//  MultiCam
//
//  Created by Neo on 2019-09-25.
//  Copyright © 2019 Neo. All rights reserved.
//

import UIKit

import AVFoundation

class ViewController: UIViewController {
  // ビュー1 : 左上
  @IBOutlet var view1: UIView!
  
  var captureSesssion: AVCaptureSession!
  var stillImageOutput: AVCapturePhotoOutput!
  var previewLayer: AVCaptureVideoPreviewLayer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // - 一旦このページをベースにプレビュー配置までやる : http://developers.goalist.co.jp/entry/2017/01/19/171612
    // ==========================================================================================================
    captureSesssion = AVCaptureSession()
    stillImageOutput = AVCapturePhotoOutput()
    print("解像度の設定")
    captureSesssion.sessionPreset = AVCaptureSession.Preset.hd1920x1080
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInUltraWideCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("VideoDevice 生成に失敗")
      return
    }
    
    do {
      let videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
      print("入力")
      guard captureSesssion.canAddInput(videoInput) else {
        print("入力設定できなさそう")
        return
      }
      captureSesssion.addInput(videoInput)
      
      print("出力")
      guard captureSesssion.canAddOutput(stillImageOutput) else {
        print("出力設定できなさそう")
        return
      }
      captureSesssion.addOutput(stillImageOutput)
      
      print("カメラ起動")
      captureSesssion.startRunning()
      
      print("プレビューのアスペクト比・カメラ向きを縦に設定")
      previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
      previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
      previewLayer.connection!.videoOrientation = AVCaptureVideoOrientation.portrait
      view1.layer.addSublayer(previewLayer!)
      print("プレビューのサイズの調整")
      previewLayer.position = CGPoint(x: self.view1.frame.width / 2, y: self.view1.frame.height / 2)
      previewLayer.bounds = view1.frame
    }
    catch {
      print("エラー : \(error)")
    }
  }
  
  // ボタン押下時
  @IBAction func actionButton(_ sender: Any) {
    print("ボタン押下")
  }
}

// - UIView と UIButton を配置
// - Main.storyboard と ViewController.swift を横並びに配置し、Control を押しながら、UI 部品をコード行にドラッグする
//   - http://neos21.hatenablog.com/entry/2018/06/03/080000
