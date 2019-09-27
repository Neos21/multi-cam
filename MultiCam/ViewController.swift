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
  // ====================================================================================================
  // MARK: - 変数定義 : セッション・デバイス
  // ====================================================================================================
  
  // セッション
  var session: AVCaptureMultiCamSession!
  
  // 使用できるデバイス名の定義
  enum Devices {
    case ultraWide
    case wideAngle
    case telephoto
    case front
  }
  // 同時利用できるデバイス数の上限
  var maxDevicesCount: Int = 0
  // 使用するデバイスの定義 : self.selectedDevices.count が self.maxDevicesCount を超えないこと
  var selectedDevices: Set<Devices> = []
  
  // マイク : Device
  var microphoneDevice: AVCaptureDevice!
  // マイク : Input
  var microphoneInput: AVCaptureDeviceInput!
  // マイク : Port
  var microphonePort: AVCaptureDeviceInput.Port!
  
  // 超広角 : 左上
  @IBOutlet var ultraWideUIView: UIView!
  // 超広角 : Preview Layer
  var ultraWidePreviewLayer: AVCaptureVideoPreviewLayer!
  // 超広角 : Device
  var ultraWideDevice: AVCaptureDevice!
  // 超広角 : Input
  var ultraWideInput: AVCaptureDeviceInput!
  // 超広角 : Port
  var ultraWidePort: AVCaptureDeviceInput.Port!
  // 超広角 : Output
  var ultraWideOutput: AVCaptureMovieFileOutput!
  // 超広角 : 映像 Connection
  var ultraWideVideoConnection: AVCaptureConnection!
  // 超広角 : 音声 Connection
  var ultraWideAudioConnection: AVCaptureConnection!
  // 超広角 : レイヤー Connection
  var ultraWideLayerConnection: AVCaptureConnection!
  // 超広角 : タスク ID
  var ultraWideBackgroundTaskID : UIBackgroundTaskIdentifier?
  
  // 広角 : 右上
  @IBOutlet var wideAngleUIView: UIView!
  // 広角 : Preview Layer
  var wideAnglePreviewLayer: AVCaptureVideoPreviewLayer!
  // 広角 : Device
  var wideAngleDevice: AVCaptureDevice!
  // 広角 : Input
  var wideAngleInput: AVCaptureDeviceInput!
  // 広角 : Port
  var wideAnglePort: AVCaptureDeviceInput.Port!
  // 広角 : Output
  var wideAngleOutput: AVCaptureMovieFileOutput!
  // 広角 : 映像 Connection
  var wideAngleVideoConnection: AVCaptureConnection!
  // 広角 : 音声 Connection
  var wideAngleAudioConnection: AVCaptureConnection!
  // 広角 : レイヤー Connection
  var wideAngleLayerConnection: AVCaptureConnection!
  // 広角 : タスク ID
  var wideAngleBackgroundTaskID : UIBackgroundTaskIdentifier?
  
  // 望遠 : 左下
  @IBOutlet var telephotoUIView: UIView!
  // 望遠 : Preview Layer
  var telephotoPreviewLayer: AVCaptureVideoPreviewLayer!
  // 望遠 : Device
  var telephotoDevice: AVCaptureDevice!
  // 望遠 : Input
  var telephotoInput: AVCaptureDeviceInput!
  // 望遠 : Port
  var telephotoPort: AVCaptureDeviceInput.Port!
  // 望遠 : Output
  var telephotoOutput: AVCaptureMovieFileOutput!
  // 望遠 : 映像 Connection
  var telephotoVideoConnection: AVCaptureConnection!
  // 望遠 : 音声 Connection
  var telephotoAudioConnection: AVCaptureConnection!
  // 望遠 : レイヤー Connection
  var telephotoLayerConnection: AVCaptureConnection!
  // 超望遠 : タスク ID
  var telephotoBackgroundTaskID : UIBackgroundTaskIdentifier?
  
  // フロント : 右下
  @IBOutlet var frontUIView: UIView!
  // フロント : Preview Layer
  var frontPreviewLayer: AVCaptureVideoPreviewLayer!
  // フロント : Device
  var frontDevice: AVCaptureDevice!
  // フロント : Input
  var frontInput: AVCaptureDeviceInput!
  // フロント : Port
  var frontPort: AVCaptureDeviceInput.Port!
  // フロント : Output
  var frontOutput: AVCaptureMovieFileOutput!
  // フロント : 映像 Connection
  var frontVideoConnection: AVCaptureConnection!
  // フロント : 音声 Connection
  var frontAudioConnection: AVCaptureConnection!
  // フロント : レイヤー Connection
  var frontLayerConnection: AVCaptureConnection!
  // フロント : タスク ID
  var frontBackgroundTaskID : UIBackgroundTaskIdentifier?
  
  
  
  
  // ====================================================================================================
  // MARK: - 変数定義 : 録画処理
  // ====================================================================================================
  
  // 録画中かどうか
  var isRecording: Bool = false
  // 録画ボタン
  @IBOutlet var recordButton: UIButton!
  
  
  
  // ====================================================================================================
  // MARK: - 初期処理
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
    
    // 同時に利用できるデバイスの最大数を特定する
    self.maxDevicesCount = self.detectSupportedDeviceCount()
    // 使用するデバイスを選択する
    self.selectedDevices = self.selectDevices()
    
    // バックグラウンドに入る時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification , object: nil)
    // ホーム画面に戻った時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onWillResignActive(_:))  , name: UIApplication.willResignActiveNotification   , object: nil)
    // フォアグラウンドに戻った時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onWillEnterForground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    // セッションが中断された時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onSessionWasInterrupted(_:))   , name: NSNotification.Name.AVCaptureSessionWasInterrupted   , object: self.session)
    // セッション中断が再開した時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onSessionInterruptionEnded(_:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: self.session)
    // セッションエラー時のイベント
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.onSessionRuntimeError(_:))     , name: NSNotification.Name.AVCaptureSessionRuntimeError     , object: self.session)
    
    // セッションを準備する
    self.setupSession()
    
    print("タップ追加")
    self.ultraWideUIView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTappedUltraWideUIView)))
    self.wideAngleUIView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTappedWideAngleUIView)))
    self.telephotoUIView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTappedTelephotoUIView)))
    self.frontUIView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTappedFrontUIView)))
  }
  
  
  
  // ====================================================================================================
  // MARK: - デバイス上限特定
  // ====================================================================================================
  
  // AVCaptureMultiCamSession に対応している Device の組合せを取得し、同時利用できるデバイス数の上限を取得する
  // MARK: NOTE : iOS13.0・13.1 の iPhone 11 Pro Max で確認したところ、4カメの組合せの Set がないので、4カメ同時には使えないと思われる
  func detectSupportedDeviceCount() -> Int {
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
    // print("\(deviceSets)")
    
    var maxDevicesCount = 0
    for deviceSet in deviceSets {
      if deviceSet.count > maxDevicesCount {
        maxDevicesCount = deviceSet.count
      }
    }
    print("最大数 : \(maxDevicesCount)")
    
    return maxDevicesCount
  }
  
  // 使用可能なデバイス数上限に合わせて使用するデバイスを選択する
  // MARK: FIXME : 最後に選択した状態を保存し復元できるようにしたい
  func selectDevices() -> Set<Devices> {
    switch maxDevicesCount {
      case 0:
        print("使用可能デバイスなし")
        return []
      case 1:
        return [Devices.wideAngle]
      case 2:
        return [Devices.ultraWide, Devices.wideAngle]
      case 3:
        return [Devices.ultraWide, Devices.wideAngle, Devices.front]
      case 4:
        // 現状対応してないけど
        return [Devices.ultraWide, Devices.wideAngle, Devices.telephoto, Devices.front]
      default:
        print("対応外のデバイス数・使用可能デバイスなしとみなす")
        return []
    }
  }
  
  
  
  // ====================================================================================================
  // MARK: - セッション準備
  // ====================================================================================================
  
  // セッションを準備する
  func setupSession() {
    print("セッション準備開始")
    self.session.beginConfiguration()
    
    // マイクデバイスは全てのカメラで共用する
    guard setupMicrophone() else {
      print("[マイク] 準備に失敗")
      return
    }
    print("[マイク] 準備完了")
    
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
    
    self.session.commitConfiguration()
    self.session.startRunning()
    print("セッション開始")
  }
  
  // マイクを用意する
  func setupMicrophone() -> Bool {
    session.beginConfiguration()
    defer {
      session.commitConfiguration()
    }
    
    guard let microphoneDevice = AVCaptureDevice.default(for: AVMediaType.audio) else {
      print("[マイク] AudioDevice 取得に失敗")
      return false
    }
    self.microphoneDevice = microphoneDevice
    
    // Input を Session に追加する
    do {
      self.microphoneInput = try AVCaptureDeviceInput(device: self.microphoneDevice)
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
    
    // Input からオーディオポートを見つける
    guard let microphonePort = self.microphoneInput.ports(for: AVMediaType.audio, sourceDeviceType: self.microphoneDevice.deviceType, sourceDevicePosition: AVCaptureDevice.Position.back).first else {
      print("[マイク] オーディオポートを見つけられなかった")
      return false
    }
    self.microphonePort = microphonePort
    
    return true
  }
  
  // 超広角カメラを用意する
  func setupUltraWideCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let ultraWideDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInUltraWideCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[超広角] VideoDevice 取得に失敗")
      return false
    }
    self.ultraWideDevice = ultraWideDevice
    
    // Input を Session に追加する
    do {
      self.ultraWideInput = try AVCaptureDeviceInput(device: self.ultraWideDevice)
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
    guard let ultraWidePort = self.ultraWideInput.ports(for: AVMediaType.video, sourceDeviceType: self.ultraWideDevice.deviceType, sourceDevicePosition: self.ultraWideDevice.position).first else {
      print("[超広角] ビデオポートを見つけられなかった")
      return false
    }
    self.ultraWidePort = ultraWidePort
    
    // Output を Session に追加する
    self.ultraWideOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.ultraWideOutput) else {
      print("[超広角] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.ultraWideOutput)
    
    // Input と Output を接続する
    self.ultraWideVideoConnection = AVCaptureConnection(inputPorts: [self.ultraWidePort], output: self.ultraWideOutput)
    self.ultraWideVideoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(self.ultraWideVideoConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        self.ultraWideVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[超広角] Cinematic Extended")
      } else {
        self.ultraWideVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[超広角] Cinematic")
      }
    }
    else {
      print("[超広角] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(self.ultraWideVideoConnection) else {
      print("[超広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.ultraWideVideoConnection)
    
    // マイク Input と Output を接続する
    self.ultraWideAudioConnection = AVCaptureConnection(inputPorts: [self.microphonePort], output: self.ultraWideOutput)
    guard self.session.canAddConnection(self.ultraWideAudioConnection) else {
      print("[超広角] マイク Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.ultraWideAudioConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.ultraWidePreviewLayer = AVCaptureVideoPreviewLayer()
    self.ultraWidePreviewLayer.setSessionWithNoConnection(self.session)
    self.ultraWidePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.ultraWidePreviewLayer.position = CGPoint(x: self.ultraWideUIView.frame.width / 2, y: self.ultraWideUIView.frame.height / 2)
    self.ultraWidePreviewLayer.bounds = self.ultraWideUIView.frame
    self.ultraWideUIView.layer.addSublayer(self.ultraWidePreviewLayer)
    self.ultraWideLayerConnection = AVCaptureConnection(inputPort: self.ultraWidePort, videoPreviewLayer: self.ultraWidePreviewLayer)
    self.ultraWideLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(self.ultraWideLayerConnection) else {
      print("[超広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(self.ultraWideLayerConnection)
    
    return true
  }
  
  // 広角カメラを用意する
  func setupWideAngleCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let wideAngleDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[広角] VideoDevice 取得に失敗")
      return false
    }
    self.wideAngleDevice = wideAngleDevice
    
    // Input を Session に追加する
    do {
      self.wideAngleInput = try AVCaptureDeviceInput(device: self.wideAngleDevice)
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
    guard let wideAnglePort = self.wideAngleInput.ports(for: AVMediaType.video, sourceDeviceType: self.wideAngleDevice.deviceType, sourceDevicePosition: self.wideAngleDevice.position).first else {
      print("[広角] ビデオポートを見つけられなかった")
      return false
    }
    self.wideAnglePort = wideAnglePort
    
    // Output を Session に追加する
    self.wideAngleOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.wideAngleOutput) else {
      print("[広角] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.wideAngleOutput)
    
    // Input と Output を接続する
    self.wideAngleVideoConnection = AVCaptureConnection(inputPorts: [self.wideAnglePort], output: self.wideAngleOutput)
    self.wideAngleVideoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(self.wideAngleVideoConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        self.wideAngleVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[広角] Cinematic Extended")
      } else {
        self.wideAngleVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[広角] Cinematic")
      }
    }
    else {
      print("[広角] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(self.wideAngleVideoConnection) else {
      print("[広角] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.wideAngleVideoConnection)
    
    // マイク Input と Output を接続する
    self.wideAngleAudioConnection = AVCaptureConnection(inputPorts: [self.microphonePort], output: self.wideAngleOutput)
    guard self.session.canAddConnection(self.wideAngleAudioConnection) else {
      print("[広角] マイク Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.wideAngleAudioConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.wideAnglePreviewLayer = AVCaptureVideoPreviewLayer()
    self.wideAnglePreviewLayer.setSessionWithNoConnection(self.session)
    self.wideAnglePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.wideAnglePreviewLayer.position = CGPoint(x: self.wideAngleUIView.frame.width / 2, y: self.wideAngleUIView.frame.height / 2)
    self.wideAnglePreviewLayer.bounds = self.wideAngleUIView.frame
    self.wideAngleUIView.layer.addSublayer(self.wideAnglePreviewLayer)
    self.wideAngleLayerConnection = AVCaptureConnection(inputPort: self.wideAnglePort, videoPreviewLayer: self.wideAnglePreviewLayer)
    self.wideAngleLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(self.wideAngleLayerConnection) else {
      print("[広角] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(self.wideAngleLayerConnection)
    
    return true
  }
  
  // 望遠カメラを用意する
  func setupTelephotoCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let telephotoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInTelephotoCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) else {
      print("[望遠] VideoDevice 生成に失敗")
      return false
    }
    self.telephotoDevice = telephotoDevice
    
    // Input を Session に追加する
    do {
      self.telephotoInput = try AVCaptureDeviceInput(device: self.telephotoDevice)
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
    guard let telephotoPort = self.telephotoInput.ports(for: AVMediaType.video, sourceDeviceType: self.telephotoDevice.deviceType, sourceDevicePosition: self.telephotoDevice.position).first else {
      print("[望遠] ビデオポートを見つけられなかった")
      return false
    }
    self.telephotoPort = telephotoPort
    
    // Output を Session に追加する
    self.telephotoOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.telephotoOutput) else {
      print("[望遠] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.telephotoOutput)
    
    // Input と Output を接続する
    self.telephotoVideoConnection = AVCaptureConnection(inputPorts: [self.telephotoPort], output: self.telephotoOutput)
    self.telephotoVideoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    if(self.telephotoVideoConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        self.telephotoVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[望遠] Cinematic Extended")
      } else {
        self.telephotoVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[望遠] Cinematic")
      }
    }
    else {
      print("[望遠] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(self.telephotoVideoConnection) else {
      print("[望遠] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.telephotoVideoConnection)
    
    // マイク Input と Output を接続する
    self.telephotoAudioConnection = AVCaptureConnection(inputPorts: [self.microphonePort], output: self.telephotoOutput)
    guard self.session.canAddConnection(self.telephotoAudioConnection) else {
      print("[望遠] マイクの Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.telephotoAudioConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.telephotoPreviewLayer = AVCaptureVideoPreviewLayer()
    self.telephotoPreviewLayer.setSessionWithNoConnection(self.session)
    self.telephotoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.telephotoPreviewLayer.position = CGPoint(x: self.telephotoUIView.frame.width / 2, y: self.telephotoUIView.frame.height / 2)
    self.telephotoPreviewLayer.bounds = self.telephotoUIView.frame
    self.telephotoUIView.layer.addSublayer(self.telephotoPreviewLayer)
    self.telephotoLayerConnection = AVCaptureConnection(inputPort: self.telephotoPort, videoPreviewLayer: self.telephotoPreviewLayer)
    self.telephotoLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    guard self.session.canAddConnection(self.telephotoLayerConnection) else {
      print("[望遠] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(self.telephotoLayerConnection)
    
    return true
  }
  
  // フロントカメラを用意する
  func setupFrontCamera() -> Bool {
    self.session.beginConfiguration()
    defer {
      self.session.commitConfiguration()
    }
    
    guard let frontDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front) else {
      print("[フロント] VideoDevice 取得に失敗")
      return false
    }
    self.frontDevice = frontDevice
    
    // Input を Session に追加する
    do {
      self.frontInput = try AVCaptureDeviceInput(device: self.frontDevice)
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
    guard let frontPort = self.frontInput.ports(for: AVMediaType.video, sourceDeviceType: self.frontDevice.deviceType, sourceDevicePosition: self.frontDevice.position).first else {
      print("[フロント] ビデオポートを見つけられなかった")
      return false
    }
    self.frontPort = frontPort
    
    // Output を Session に追加する
    self.frontOutput = AVCaptureMovieFileOutput()
    guard self.session.canAddOutput(self.frontOutput) else {
      print("[フロント] Output を Session に追加できない")
      return false
    }
    self.session.addOutputWithNoConnections(self.frontOutput)
    
    // Input と Output を接続する
    self.frontVideoConnection = AVCaptureConnection(inputPorts: [self.frontPort], output: self.frontOutput)
    self.frontVideoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    self.frontVideoConnection.automaticallyAdjustsVideoMirroring = false
    self.frontVideoConnection.isVideoMirrored = false  // 動画は鏡写しにしない
    if(self.frontVideoConnection.isVideoStabilizationSupported) {
      if #available(iOS 13.0, *) {
        self.frontVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematicExtended
        print("[フロント] Cinematic Extended")
      } else {
        self.frontVideoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.cinematic
        print("[フロント] Cinematic")
      }
    }
    else {
      print("[フロント] 手ブレ補正が使えない")
    }
    guard self.session.canAddConnection(self.frontVideoConnection) else {
      print("[フロント] Input と Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.frontVideoConnection)
    
    // マイク Input と Output を接続する
    self.frontAudioConnection = AVCaptureConnection(inputPorts: [self.microphonePort], output: self.frontOutput)
    guard self.session.canAddConnection(self.frontAudioConnection) else {
      print("[マイク] Input と超広角の Output を接続できなかった")
      return false
    }
    self.session.addConnection(self.frontAudioConnection)
    
    // ビデオポートをプレビューレイヤーに接続する
    self.frontPreviewLayer = AVCaptureVideoPreviewLayer()
    self.frontPreviewLayer.setSessionWithNoConnection(self.session)
    self.frontPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect  // アスペクトフィット
    self.frontPreviewLayer.position = CGPoint(x: self.frontUIView.frame.width / 2, y: self.frontUIView.frame.height / 2)
    self.frontPreviewLayer.bounds = self.frontUIView.frame
    self.frontUIView.layer.addSublayer(self.frontPreviewLayer)
    self.frontLayerConnection = AVCaptureConnection(inputPort: self.frontPort, videoPreviewLayer: self.frontPreviewLayer)
    self.frontLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
    self.frontLayerConnection.automaticallyAdjustsVideoMirroring = false
    self.frontLayerConnection.isVideoMirrored = true  // プレビューは鏡写しにする
    guard self.session.canAddConnection(self.frontLayerConnection) else {
      print("[フロント] ビデオポートをプレビューレイヤーに接続できなかった")
      return false
    }
    self.session.addConnection(self.frontLayerConnection)
    
    return true
  }
  
  
  
  // ====================================================================================================
  // MARK: - UIView タップイベント
  // ====================================================================================================
  
  // 超広角の UIView がタップされた時
  @objc func onTappedUltraWideUIView(_ sender: UITapGestureRecognizer) {
    if(self.isRecording) {
      print("[超広角] 録画中は何もしない")
      return
    }
    
    if(self.selectedDevices.contains(Devices.ultraWide)) {
      print("[超広角] デバイスを削除する")
      self.stopSession()
      self.selectedDevices.remove(Devices.ultraWide)
      self.restartSession()
      print("[超広角] デバイス削除・再起動")
      return
    }
    
    if(self.selectedDevices.count >= self.maxDevicesCount) {
      print("[超広角] これ以上デバイスを追加できないので何もしない")
      return
    }
    
    print("[超広角] デバイスを追加する")
    self.stopSession()
    self.selectedDevices.insert(Devices.ultraWide)
    self.restartSession()
    print("[超広角] デバイス追加・再起動")
  }
  
  // 広角の UIView がタップされた時
  @objc func onTappedWideAngleUIView(_ sender: UITapGestureRecognizer) {
    if(self.isRecording) {
      print("[広角] 録画中は何もしない")
      return
    }
    
    if(self.selectedDevices.contains(Devices.wideAngle)) {
      print("[広角] デバイスを削除する")
      self.stopSession()
      self.selectedDevices.remove(Devices.wideAngle)
      self.restartSession()
      print("[広角] デバイス削除・再起動")
      return
    }
    
    if(self.selectedDevices.count >= self.maxDevicesCount) {
      print("[広角] これ以上デバイスを追加できないので何もしない")
      return
    }
    
    print("[広角] デバイスを追加する")
    self.stopSession()
    self.selectedDevices.insert(Devices.wideAngle)
    self.restartSession()
    print("[広角] デバイス追加・再起動")
  }
  
  // 望遠の UIView がタップされた時
  @objc func onTappedTelephotoUIView(_ sender: UITapGestureRecognizer) {
    if(self.isRecording) {
      print("[望遠] 録画中は何もしない")
      return
    }
    
    if(self.selectedDevices.contains(Devices.telephoto)) {
      print("[望遠] デバイスを削除する")
      self.stopSession()
      self.selectedDevices.remove(Devices.telephoto)
      self.restartSession()
      print("[望遠] デバイス削除・再起動")
      return
    }
    
    if(self.selectedDevices.count >= self.maxDevicesCount) {
      print("[望遠] これ以上デバイスを追加できないので何もしない")
      return
    }
    
    print("[望遠] デバイスを追加する")
    self.stopSession()
    self.selectedDevices.insert(Devices.telephoto)
    self.restartSession()
    print("[望遠] デバイス追加・再起動")
  }
  
  // フロントの UIView がタップされた時
  @objc func onTappedFrontUIView(_ sender: UITapGestureRecognizer) {
    if(self.isRecording) {
      print("[フロント] 録画中は何もしない")
      return
    }
    
    if(self.selectedDevices.contains(Devices.front)) {
      print("[フロント] デバイスを削除する")
      self.stopSession()
      self.selectedDevices.remove(Devices.front)
      self.restartSession()
      print("[フロント] デバイス削除・再起動")
      return
    }
    
    if(self.selectedDevices.count >= self.maxDevicesCount) {
      print("[フロント] これ以上デバイスを追加できないので何もしない")
      return
    }
    
    print("[フロント] デバイスを追加する")
    self.stopSession()
    self.selectedDevices.insert(Devices.front)
    self.restartSession()
    print("[フロント] デバイス追加・再起動")
  }
  
  // プレビューレイヤーを全て削除してセッションを止める
  func stopSession() {
    if(self.ultraWidePreviewLayer != nil) {
      self.ultraWidePreviewLayer.removeFromSuperlayer()
    }
    if(self.wideAnglePreviewLayer != nil) {
      self.wideAnglePreviewLayer.removeFromSuperlayer()
    }
    if(self.telephotoPreviewLayer != nil) {
      self.telephotoPreviewLayer.removeFromSuperlayer()
    }
    if(self.frontPreviewLayer != nil) {
      self.frontPreviewLayer.removeFromSuperlayer()
    }
    self.session.stopRunning()
  }
  
  // セッションを再作成して初期作成する・この関数を呼ぶ前に self.selectedDevices を入れ替えておくこと
  func restartSession() {
    self.session = AVCaptureMultiCamSession()
    self.setupSession()
  }
  
  
  
  // ====================================================================================================
  // MARK: - 録画・停止
  // ====================================================================================================
  
  // ボタン押下時
  @IBAction func actionButton(_ sender: Any) {
    if(!self.isRecording) {
      print("録画開始する")
      self.startRecording()
    }
    else {
      print("録画停止する")
      self.stopRecording()
    }
  }
  
  // 録画を開始する
  func startRecording() {
    defer {
      self.isRecording = true
      self.recordButton.setTitle("Stop", for: .normal)
    }
    
    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    let documentsDirectory = paths[0] as String
    
    // 録画終了処理をバックグラウンドで処理できるように TaskID を取得しておく
    if(self.selectedDevices.contains(Devices.ultraWide)) {
      self.ultraWideBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
      self.ultraWideOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempUltraWide.mp4") as URL, recordingDelegate: self)
      print("[超広角] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.wideAngle)) {
      self.wideAngleBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
      self.wideAngleOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempWideAngle.mp4") as URL, recordingDelegate: self)
      print("[広角] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.telephoto)) {
      self.telephotoBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
      self.telephotoOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempTelephoto.mp4") as URL, recordingDelegate: self)
      print("[望遠] 録画開始")
    }
    if(self.selectedDevices.contains(Devices.front)) {
      self.frontBackgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
      self.frontOutput.startRecording(to: NSURL(fileURLWithPath: "\(documentsDirectory)/tempFront.mp4") as URL, recordingDelegate: self)
      print("[フロント] 録画開始")
    }
  }
  
  // 録画を停止する
  func stopRecording() {
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
    PHPhotoLibrary.requestAuthorization({ (status) in
      if status == .authorized {
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { (isCompleted, error) in
          if isCompleted {
            print("保存成功 : \(outputFileURL)")
          }
          else {
            print("保存失敗 : \(outputFileURL) : \(String(describing: error))")
          }
          
          if let currentBackgroundTaskID = self.ultraWideBackgroundTaskID {
            self.ultraWideBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            if currentBackgroundTaskID != UIBackgroundTaskIdentifier.invalid {
              print("[超広角] バックグランド処理終了")
              UIApplication.shared.endBackgroundTask(currentBackgroundTaskID)
            }
          }
          if let currentBackgroundTaskID = self.wideAngleBackgroundTaskID {
            self.wideAngleBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            if currentBackgroundTaskID != UIBackgroundTaskIdentifier.invalid {
              print("[広角] バックグランド処理終了")
              UIApplication.shared.endBackgroundTask(currentBackgroundTaskID)
            }
          }
          if let currentBackgroundTaskID = self.telephotoBackgroundTaskID {
            self.telephotoBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            if currentBackgroundTaskID != UIBackgroundTaskIdentifier.invalid {
              print("[望遠] バックグランド処理終了")
              UIApplication.shared.endBackgroundTask(currentBackgroundTaskID)
            }
          }
          if let currentBackgroundTaskID = self.frontBackgroundTaskID {
            self.frontBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
            if currentBackgroundTaskID != UIBackgroundTaskIdentifier.invalid {
              print("[フロント] バックグランド処理終了")
              UIApplication.shared.endBackgroundTask(currentBackgroundTaskID)
            }
          }
        }
      }
      else {
        print("フォトライブラリへの保存を許可されていない")
      }
    })
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
  
  // フォアグラウンドに戻る時
  @objc func onWillEnterForground(_ notification: Notification?) {
    print("フォアグラウンドに戻る")
    if(self.isRecording) {
      print("フォアグラウンドに戻るので録画を停止する")
      self.stopRecording()
    }
  }
  
  // セッションが中断された時
  @objc func onSessionWasInterrupted(_ notification: Notification?) {
    print("セッションが中断された")
    if(self.isRecording) {
      print("セッションが中断されたので録画を停止する")
      self.stopRecording()
    }
  }
  
  // セッション中断が再開した時
  @objc func onSessionInterruptionEnded(_ notification: Notification?) {
    print("セッション中断が再開した")
    if(self.isRecording) {
      print("セッション中断が再開したので録画を停止する")
      self.stopRecording()
    }
  }
  
  // セッションエラー時
  @objc func onSessionRuntimeError(_ notification: Notification?) {
    print("セッションエラー時")
    if(self.isRecording) {
      print("セッションエラー時なので録画を停止する")
      self.stopRecording()
    }
  }
}
