//
//  AppDelegate.swift
//  MultiCam
//
//  Created by Neo on 2019-09-25.
//  Copyright © 2019 Neo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  // 「The app delegate must implement the window property if it wants to use a main storyboard file.」とエラーが出たので書いておく
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }
}



// - 最初は SceneDelegate.swift があった、コレは複数の UI のインスタンスを作るためのモノで、iOS13 からの機能
//   - 要らないのでファイルを消し、Info.plist の Application Scene Manifest を消した
