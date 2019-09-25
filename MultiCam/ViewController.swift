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
  // セッション
  var session: AVCaptureSession!
  
  // 超広角 : 左上
  @IBOutlet var ultraWideUIView: UIView!
  // 超広角 : プレビューレイヤー
  var ultraWidePreviewLayer: AVCaptureVideoPreviewLayer!
  // 超広角 : Input
  var ultraWideInput: AVCaptureDeviceInput!
  // 超広角 : Output
  var ultraWideOutput: AVCaptureMovieFileOutput!
  
  // 広角 : 右上
  @IBOutlet var wideAngleUIView: UIView!
  // 広角 : プレビューレイヤー
  var wideAnglePreviewLayer: AVCaptureVideoPreviewLayer!
  // 広角 : Input
  var wideAngleInput: AVCaptureDeviceInput!
  // 広角 : Output
  var wideAngleOutput: AVCaptureMovieFileOutput!
  
  // 初期表示時の処理
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // セッション生成
    self.session = AVCaptureMultiCamSession()
    guard AVCaptureMultiCamSession.isMultiCamSupported else {
      print("マルチカムに未対応")
      return
    }
    
    print("セッション準備開始")
    // AVCaptureMultiCamSession を使う時は手動で AVCaptureInputs から AVCaptureOutputs にコネクションを繋ぐと良いらしい
    self.session.beginConfiguration()
    
    guard setupBackUltraWideCamera() else {
      print("超広角カメラの準備に失敗")
      return
    }
    guard setupBackWideAngleCamera() else {
      print("広角カメラの準備に失敗")
      return
    }
    
    self.session.commitConfiguration()
    self.session.startRunning()
    print("セッション開始")
  }
  
  // 超広角カメラを用意する
  private func setupBackUltraWideCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInUltraWideCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[超広角] VideoDevice 生成に失敗")
      return false
    }
    
    // Input を Session に追加する
    do {
      self.ultraWideInput = try AVCaptureDeviceInput(device: videoDevice)
      guard session.canAddInput(self.ultraWideInput) else {
        print("[超広角] Input を Session に追加できない")
        return false
      }
      self.session.addInputWithNoConnections(self.ultraWideInput)
    }
    catch {
      print("[超広角] Input 準備に失敗 : \(error)")
      return false
    }
    
    // Input からビデオポートを見つける
    guard let videoPort = self.ultraWideInput.ports(for: AVMediaType.video, sourceDeviceType: videoDevice.deviceType, sourceDevicePosition: videoDevice.position).first else {
      print("[超広角] ビデオポートを見つけられなかった")
      return false
    }
    
    // Output を Session に追加する
    self.ultraWideOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.ultraWideOutput) else {
      print("[超広角] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.ultraWideOutput)
    
    // Input と Output を接続する
    let outputConnection = AVCaptureConnection(inputPorts: [videoPort], output: self.ultraWideOutput)
    guard self.session.canAddConnection(outputConnection) else {
      print("[超広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    
    // ビデオポートをプレビューレイヤーに接続する
    self.ultraWidePreviewLayer = AVCaptureVideoPreviewLayer()
    // <AVCaptureConnection: 0x2810a64e0> cannot be added because AVCaptureVideoPreviewLayer only accepts one connection of this media type at a time, and it is already connected'
    // このエラーが出るので、宣言時に session を指定しない
    self.ultraWidePreviewLayer.setSessionWithNoConnection(self.session)
    self.ultraWidePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.ultraWidePreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    self.ultraWideUIView.layer.addSublayer(self.ultraWidePreviewLayer)
    self.ultraWidePreviewLayer.position = CGPoint(x: self.ultraWideUIView.frame.width / 2, y: self.ultraWideUIView.frame.height / 2)
    self.ultraWidePreviewLayer.bounds = self.ultraWideUIView.frame
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.ultraWidePreviewLayer)
    guard self.session.canAddConnection(layerConnection) else {
      print("[超広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    
    print("[超広角] 準備完了")
    return true
  }
  
  // 広角カメラを用意する
  private func setupBackWideAngleCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[広角] VideoDevice 生成に失敗")
      return false
    }
    
    // Input を Session に追加する
    do {
      self.wideAngleInput = try AVCaptureDeviceInput(device: videoDevice)
      guard session.canAddInput(self.wideAngleInput) else {
        print("[広角] Input を Session に追加できない")
        return false
      }
      self.session.addInputWithNoConnections(self.wideAngleInput)
    }
    catch {
      print("[広角] Input 準備に失敗 : \(error)")
      return false
    }
    
    // Input からビデオポートを見つける
    guard let videoPort = self.wideAngleInput.ports(for: AVMediaType.video, sourceDeviceType: videoDevice.deviceType, sourceDevicePosition: videoDevice.position).first else {
      print("[広角] ビデオポートを見つけられなかった")
      return false
    }
    
    // Output を Session に追加する
    self.wideAngleOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.wideAngleOutput) else {
      print("[広角] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.wideAngleOutput)
    
    // Input と Output を接続する
    let outputConnection = AVCaptureConnection(inputPorts: [videoPort], output: self.wideAngleOutput)
    guard self.session.canAddConnection(outputConnection) else {
      print("[広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    
    // ビデオポートをプレビューレイヤーに接続する
    self.wideAnglePreviewLayer = AVCaptureVideoPreviewLayer()
    self.wideAnglePreviewLayer.setSessionWithNoConnection(self.session)
    self.wideAnglePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.wideAnglePreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    self.wideAngleUIView.layer.addSublayer(self.wideAnglePreviewLayer)
    self.wideAnglePreviewLayer.position = CGPoint(x: self.wideAngleUIView.frame.width / 2, y: self.wideAngleUIView.frame.height / 2)
    self.wideAnglePreviewLayer.bounds = self.wideAngleUIView.frame
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.wideAnglePreviewLayer)
    guard self.session.canAddConnection(layerConnection) else {
      print("[広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    
    print("[広角] 準備完了")
    return true
  }
  
  // ボタン押下時
  @IBAction func actionButton(_ sender: Any) {
    print("ボタン押下")
  }
}

// - UIView と UIButton を配置
// - Main.storyboard と ViewController.swift を横並びに配置し、Control を押しながら、UI 部品をコード行にドラッグする
//   - http://neos21.hatenablog.com/entry/2018/06/03/080000
// - 最初に参考にした単独プレビュー : http://developers.goalist.co.jp/entry/2017/01/19/171612
// - defer : この関数を抜ける時に必ず行う処理を定義しておく。finally 的な
