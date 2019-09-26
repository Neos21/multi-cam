//
//  ViewController.swift
//  MultiCam
//
//  Created by Neo on 2019-09-25.
//  Copyright © 2019 Neo. All rights reserved.
//

import UIKit

import AVFoundation
import Photos

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
  // セッション
  var session: AVCaptureMultiCamSession!
  // 使用できるデバイス名の定義
  enum Devices {
    case ultraWide
    case wideAngle
    case telephoto
    case front
  }
  // 使用するデバイスの定義 : 3つまでにすること・4つ選択するとエラーになる
  var selectedDevices: Set = [Devices.ultraWide, Devices.wideAngle, Devices.front]  // Devices.front
  
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
  
  // マイク : Input
  var microphoneInput: AVCaptureDeviceInput!
  // マイク : Output
  var microphoneOutput: AVCaptureAudioDataOutput!
  
  // 録画中かどうか
  var isRecording: Bool = false
  // 録画ボタン
  @IBOutlet var recordButton: UIButton!
  
  
  
  // ====================================================================================================
  
  
  
  // 初期表示時の処理
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // セッション生成
    self.session = AVCaptureMultiCamSession()
    guard AVCaptureMultiCamSession.isMultiCamSupported else {
      print("マルチカムに未対応")
      return
    }
    
    // バックグラウンドに入る時のイベントを定義する
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    // ホーム画面に戻った時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onWillResignActive(_:))  , name: UIApplication.willResignActiveNotification  , object: nil)
    
    print("セッション準備開始")
    // AVCaptureMultiCamSession を使う時は手動で AVCaptureInputs から AVCaptureOutputs にコネクションを繋ぐ
    self.session.beginConfiguration()
    
    if(self.selectedDevices.contains(Devices.ultraWide)) {
      guard setupUltraWideCamera() else {
        print("[超広角] 準備に失敗")
        return
      }
      print("[超広角] 準備完了")
    }
    
    if(self.selectedDevices.contains(Devices.wideAngle)) {
      guard setupWideAngleCamera() else {
        print("[広角] 準備に失敗")
        return
      }
      print("[広角] 準備完了")
    }
    
    if(self.selectedDevices.contains(Devices.telephoto)) {
      guard setupTelephotoCamera() else {
        print("[望遠] 準備に失敗")
        return
      }
      print("[望遠] 準備完了")
    }
    
    if(self.selectedDevices.contains(Devices.front)) {
      guard setupFrontCamera() else {
        print("[フロント] 準備に失敗")
        return
      }
      print("[フロント] 準備完了")
    }
    
    guard setupMicrophone() else {
      print("[マイク] 準備に失敗")
      return
    }
    print("[マイク] 準備完了")
    
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
      print("[超広角] VideoDevice 取得に失敗")
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
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(outputConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[超広角] Cinematic Extended")
      } else {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[超広角] Cinematic")
      }
    }
    else {
      print("[超広角] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(outputConnection) else {
      print("[超広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.ultraWidePreviewLayer = AVCaptureVideoPreviewLayer()
    // <AVCaptureConnection: 0x2810a64e0> cannot be added because AVCaptureVideoPreviewLayer only accepts one connection of this media type at a time, and it is already connected'
    // このエラーが出るので、宣言時に session を指定しない
    self.ultraWidePreviewLayer.setSessionWithNoConnection(self.session)
    self.ultraWidePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.ultraWidePreviewLayer.position = CGPoint(x: self.ultraWideUIView.frame.width / 2, y: self.ultraWideUIView.frame.height / 2)
    self.ultraWidePreviewLayer.bounds = self.ultraWideUIView.frame
    self.ultraWideUIView.layer.addSublayer(self.ultraWidePreviewLayer)
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.ultraWidePreviewLayer)
    layerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(layerConnection) else {
      print("[超広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    return true
  }
  
  // 広角カメラを用意する
  private func setupWideAngleCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[広角] VideoDevice 取得に失敗")
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
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(outputConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[広角] Cinematic Extended")
      } else {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[広角] Cinematic")
      }
    }
    else {
      print("[広角] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(outputConnection) else {
      print("[広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.wideAnglePreviewLayer = AVCaptureVideoPreviewLayer()
    self.wideAnglePreviewLayer.setSessionWithNoConnection(self.session)
    self.wideAnglePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.wideAnglePreviewLayer.position = CGPoint(x: self.wideAngleUIView.frame.width / 2, y: self.wideAngleUIView.frame.height / 2)
    self.wideAnglePreviewLayer.bounds = self.wideAngleUIView.frame
    self.wideAngleUIView.layer.addSublayer(self.wideAnglePreviewLayer)
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.wideAnglePreviewLayer)
    layerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(layerConnection) else {
      print("[広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
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
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(outputConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[望遠] Cinematic Extended")
      } else {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[望遠] Cinematic")
      }
    }
    else {
      print("[望遠] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(outputConnection) else {
      print("[望遠] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.telephotoPreviewLayer = AVCaptureVideoPreviewLayer()
    self.telephotoPreviewLayer.setSessionWithNoConnection(self.session)
    self.telephotoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.telephotoPreviewLayer.position = CGPoint(x: self.telephotoUIView.frame.width / 2, y: self.telephotoUIView.frame.height / 2)
    self.telephotoPreviewLayer.bounds = self.telephotoUIView.frame
    self.telephotoUIView.layer.addSublayer(self.telephotoPreviewLayer)
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.telephotoPreviewLayer)
    layerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(layerConnection) else {
      print("[望遠] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    return true
  }
  
  // フロントカメラを用意する
  private func setupFrontCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) else {
      print("[フロント] VideoDevice 取得に失敗")
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
    outputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    outputConnection.automaticallyAdjustsVideoMirroring = false
    outputConnection.isVideoMirrored = false  // 動画は鏡写しにしない
    if(outputConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[フロント] Cinematic Extended")
      } else {
        outputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[フロント] Cinematic")
      }
    }
    else {
      print("[フロント] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(outputConnection) else {
      print("[フロント] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(outputConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.frontPreviewLayer = AVCaptureVideoPreviewLayer()
    self.frontPreviewLayer.setSessionWithNoConnection(self.session)
    self.frontPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.frontPreviewLayer.position = CGPoint(x: self.frontUIView.frame.width / 2, y: self.frontUIView.frame.height / 2)
    self.frontPreviewLayer.bounds = self.frontUIView.frame
    self.frontUIView.layer.addSublayer(self.frontPreviewLayer)
    let layerConnection = AVCaptureConnection(inputPort: videoPort, videoPreviewLayer: self.frontPreviewLayer)
    layerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    layerConnection.automaticallyAdjustsVideoMirroring = false
    layerConnection.isVideoMirrored = true  // プレビューは鏡写しにする
    guard self.session.canAddConnection(layerConnection) else {
      print("[フロント] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(layerConnection)
    
    return true
  }
  
  // マイクを用意する
  private func setupMicrophone() -> Bool {
    session.beginConfiguration()
    defer {
      session.commitConfiguration()
    }
    
    guard let microphoneDevice = AVCaptureDevice.default(for: .audio) else {
      print("[マイク] AudioDevice 取得に失敗")
      return false
    }
    
    // Input を Session に追加する
    do {
      self.microphoneInput = try AVCaptureDeviceInput(device: microphoneDevice)
      guard session.canAddInput(self.microphoneInput) else {
        print("[マイク] Input を Session に追加できない")
        return false
      }
      self.session.addInputWithNoConnections(self.microphoneInput)
    }
    catch {
      print("[マイク] Input 準備に失敗 : \(error)")
      return false
    }
    
    // TODO : 動画ファイルに一緒に記録できていない
    
    return true
  }
  
  
  // ====================================================================================================
  
  
  
  // ボタン押下時
  @IBAction func actionButton(_ sender: Any) {
    print("ボタン押下")
    
    if(self.isRecording) {
      print("停止するつもり")
      self.stopRecording()
    }
    else {
      print("録画するつもり")
      self.startRecording()
    }
  }
  
  // 録画を開始する
  private func startRecording() {
    defer {
      self.isRecording = true
      self.recordButton.setTitle("Stop", for: .normal)
    }
    
    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    let documentsDirectory = paths[0] as String
    
    if(self.selectedDevices.contains(Devices.ultraWide)) {
      self.ultraWideOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempUltraWide.mp4") as URL, recordingDelegate: self)
      print("[超広角] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.wideAngle)) {
      self.wideAngleOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempWideAngle.mp4") as URL, recordingDelegate: self)
      print("[広角] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.telephoto)) {
      self.telephotoOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempTelephoto.mp4") as URL, recordingDelegate: self)
      print("[望遠] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.front)) {
      self.frontOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempFront.mp4") as URL, recordingDelegate: self)
      print("[フロント] 録画開始")
    }
  }
  
  // 録画を停止する
  private func stopRecording() {
    defer {
      self.isRecording = false
      self.recordButton.setTitle("Start", for: .normal)
    }
    
    if(self.selectedDevices.contains(Devices.ultraWide)) {
      self.ultraWideOutput.stopRecording()
      print("[超広角] 録画停止")
    }
    if(self.selectedDevices.contains(Devices.wideAngle)) {
      self.wideAngleOutput.stopRecording()
      print("[広角] 録画停止")
    }
    if(self.selectedDevices.contains(Devices.telephoto)) {
      self.telephotoOutput.stopRecording()
      print("[望遠] 録画停止")
    }
    if(self.selectedDevices.contains(Devices.front)) {
      self.frontOutput.stopRecording()
      print("[フロント] 録画停止")
    }
  }
  
  // Override : AVCaptureFileOutputRecordingDelegate
  // 録画終了時
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    print("保存処理開始")
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
    }) { (isCompleted, error) in
      if isCompleted {
        print("保存成功 : \(outputFileURL)")
      }
      else {
        print("保存失敗 : \(outputFileURL) : \(String(describing: error))")
      }
    }
  }
  
  // バックグラウンドに入る時
  @objc func onDidEnterBackground(_ notification: Notification?) {
    print("バックグラウンドに入る")
    if(self.isRecording) {
      print("バックグラウンドに入るので録画を停止する")
      self.stopRecording()
    }
  }
  
  // ホーム画面に戻る時
  @objc func onWillResignActive(_ notification: Notification?) {
    print("ホーム画面に戻る")
    if(self.isRecording) {
      print("ホーム画面に戻るので録画を停止する")
      self.stopRecording()
    }
  }
  
  
  
  // ====================================================================================================
  
  
  
  // 4カメの組合せの Set がないので、4カメ同時には使えないっぽい…
  private func printSupportedMultiCamDeviceSets() {
    let discoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [
      AVCaptureDevice.DeviceType.builtInWideAngleCamera,
      AVCaptureDevice.DeviceType.builtInUltraWideCamera,
      AVCaptureDevice.DeviceType.builtInTelephotoCamera,
      // AVCaptureDevice.DeviceType.builtInDualCamera,
      // AVCaptureDevice.DeviceType.builtInDualWideCamera,
      // AVCaptureDevice.DeviceType.builtInTripleCamera,
      // AVCaptureDevice.DeviceType.builtInTrueDepthCamera
    ], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
    let deviceSets = discoverySession.supportedMultiCamDeviceSets
    print("\(deviceSets)")
  }
}

// - UIView と UIButton を配置
// - Main.storyboard と ViewController.swift を横並びに配置し、Control を押しながら、UI 部品をコード行にドラッグする
//   - http://neos21.hatenablog.com/entry/2018/06/03/080000
// - 最初に参考にした単独プレビュー : http://developers.goalist.co.jp/entry/2017/01/19/171612
// - defer : この関数を抜ける時に必ず行う処理を定義しておく。finally 的な
// - 3つまでは同時起動できるが、4つ目はどの組合せでも表示できない
//   - Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVCaptureMultiCamSession addInputWithNoConnections:] These devices may not be used simultaneously. Use -[AVCaptureDeviceDiscoverySession supportedMultiCamDeviceSets]'
// - バックグラウンドに移ると以下のエラーが出る
//   - Can't end BackgroundTask: no background task exists with identifier 1 (0x1), or it may have already been ended. Break in UIApplicationEndBackgroundTaskError() to debug.
