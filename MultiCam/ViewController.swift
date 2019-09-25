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
  var session: AVCaptureMultiCamSession!
  
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
  
  // 望遠 : 左下
  @IBOutlet var telephotoUIView: UIView!
  // 望遠 : プレビューレイヤー
  var telephotoPreviewLayer: AVCaptureVideoPreviewLayer!
  // 望遠 : Input
  var telephotoInput: AVCaptureDeviceInput!
  // 望遠 : Output
  var telephotoOutput: AVCaptureMovieFileOutput!
  
  // フロント : 右下
  @IBOutlet var frontUIView: UIView!
  // フロント : プレビューレイヤー
  var frontPreviewLayer: AVCaptureVideoPreviewLayer!
  // フロント : Input
  var frontInput: AVCaptureDeviceInput!
  // フロント : Output
  var frontOutput: AVCaptureMovieFileOutput!
  
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
    
    guard setupUltraWideCamera() else {
      print("超広角カメラの準備に失敗")
      return
    }
    guard setupWideAngleCamera() else {
      print("広角カメラの準備に失敗")
      return
    }
    guard setupTelephotoCamera() else {
      print("望遠カメラの準備に失敗")
      return
    }
    // guard setupFrontCamera() else {
    //   print("フロントカメラの準備に失敗")
    //   return
    // }
    
    self.session.commitConfiguration()
    self.session.startRunning()
    print("セッション開始")
  }
  
  // 超広角カメラを用意する
  private func setupUltraWideCamera() -> Bool {
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
  private func setupWideAngleCamera() -> Bool {
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
  
  // 望遠カメラを用意する
  private func setupTelephotoCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInTelephotoCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[望遠] VideoDevice 生成に失敗")
      return false
    }
    
    // Input を Session に追加する
    do {
      self.telephotoInput = try AVCaptureDeviceInput(device: videoDevice)
      guard session.canAddInput(self.telephotoInput) else {
        print("[望遠] Input を Session に追加できない")
        return false
      }
      self.session.addInputWithNoConnections(self.telephotoInput)
    }
    catch {
      print("[望遠] Input 準備に失敗 : \(error)")
      return false
    }
    
    // Input からビデオポートを見つける
    guard let videoPort = self.telephotoInput.ports(for: AVMediaType.video, sourceDeviceType: videoDevice.deviceType, sourceDevicePosition: videoDevice.position).first else {
      print("[望遠] ビデオポートを見つけられなかった")
      return false
    }
    
    // Output を Session に追加する
    self.telephotoOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.telephotoOutput) else {
      print("[望遠] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.telephotoOutput)
    
    // Input と Output を接続する
    let outputConnection = AVCaptureConnection(inputPorts: [videoPort], output: self.telephotoOutput)
    guard self.session.canAddConnection(outputConnection) else {
      print("[望遠] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    
    // ビデオポートをプレビューレイヤーに接続する
    self.telephotoPreviewLayer = AVCaptureVideoPreviewLayer()
    self.telephotoPreviewLayer.setSessionWithNoConnection(self.session)
    self.telephotoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.telephotoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
    self.telephotoUIView.layer.addSublayer(self.telephotoPreviewLayer)
    self.telephotoPreviewLayer.position = CGPoint(x: self.telephotoUIView.frame.width / 2, y: self.telephotoUIView.frame.height / 2)
    self.telephotoPreviewLayer.bounds = self.telephotoUIView.frame
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.telephotoPreviewLayer)
    guard self.session.canAddConnection(layerConnection) else {
      print("[望遠] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    print("[望遠] 準備完了")
    return true
  }
  
  // フロントカメラを用意する
  private func setupFrontCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) else {
      print("[フロント] VideoDevice 生成に失敗")
      return false
    }
    
    // Input を Session に追加する
    do {
      self.frontInput = try AVCaptureDeviceInput(device: videoDevice)
      guard session.canAddInput(self.frontInput) else {
        print("[フロント] Input を Session に追加できない")
        return false
      }
      self.session.addInputWithNoConnections(self.frontInput)
      // Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVCaptureMultiCamSession addInputWithNoConnections:] These devices may not be used simultaneously. Use -[AVCaptureDeviceDiscoverySession supportedMultiCamDeviceSets]'
      // 3つまでは同時起動できるが、4つ目はどの組合せでも表示できない
    }
    catch {
      print("[フロント] Input 準備に失敗 : \(error)")
      return false
    }
    
    // Input からビデオポートを見つける
    guard let videoPort = self.frontInput.ports(for: AVMediaType.video, sourceDeviceType: videoDevice.deviceType, sourceDevicePosition: videoDevice.position).first else {
      print("[フロント] ビデオポートを見つけられなかった")
      return false
    }
    
    // Output を Session に追加する
    self.frontOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.frontOutput) else {
      print("[フロント] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.frontOutput)
    
    // Input と Output を接続する
    let outputConnection = AVCaptureConnection(inputPorts: [videoPort], output: self.frontOutput)
    guard self.session.canAddConnection(outputConnection) else {
      print("[フロント] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    outputConnection.automaticallyAdjustsVideoMirroring = false
    outputConnection.isVideoMirrored = false  // 鏡写しにするかどうか
    
    // ビデオポートをプレビューレイヤーに接続する
    self.frontPreviewLayer = AVCaptureVideoPreviewLayer()
    self.frontPreviewLayer.setSessionWithNoConnection(self.session)
    self.frontPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.frontPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait  // TODO : ココから3つは layerConnection 宣言後に指定するモノかもしれない
    self.frontPreviewLayer.connection?.automaticallyAdjustsVideoMirroring = false
    self.frontPreviewLayer.connection?.isVideoMirrored = false  // 鏡写しにするかどうか
    self.frontUIView.layer.addSublayer(self.frontPreviewLayer)
    self.frontPreviewLayer.position = CGPoint(x: self.frontUIView.frame.width / 2, y: self.frontUIView.frame.height / 2)
    self.frontPreviewLayer.bounds = self.frontUIView.frame
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.frontPreviewLayer)
    guard self.session.canAddConnection(layerConnection) else {
      print("[フロント] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    print("[フロント] 準備完了")
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
