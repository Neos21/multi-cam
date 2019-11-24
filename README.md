# Multi Cam

![Example 1](https://user-images.githubusercontent.com/16625731/69497175-6b7c5500-0f1d-11ea-9331-e0bba1a0d952.png)  
![Example 2](https://user-images.githubusercontent.com/16625731/69497170-5c95a280-0f1d-11ea-8e3c-9898f6723e47.png)

iOS 13 から使えるようになった `AVCaptureMultiCamSession` を使って、複数カメラデバイスで同時にビデオ録画するアプリです。

- 検証端末 : iPhone 11 Pro Max
- 検証 OS : iOS 13.0・iOS 13.1
- 撮影される動画ファイルの仕様 : 1920x1080px・29.58fps (バックカメラ・フロントカメラともに同じ)

## 既知の問題

- iPhone 11 Pro Max には合計4つのレンズが付いているが、4つを同時に使用することができなかった
    - `AVCaptureDevice.DiscoverySession#supportedMultiCamDeviceSets` で利用可能なデバイスの組合せを見ると、最大で3カメラ分までの定義しか見つからない
    - 無理やり4つ目のカメラを追加しようとすると、4つ目の `addInputWithNoConnections()` 実行時にエラーになる。
        - `self.avCaptureMultiCamSession.addInputWithNoConnections(avCaptureDeviceInput)`
        - `*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[AVCaptureMultiCamSession addInputWithNoConnections:] These devices may not be used simultaneously. Use -[AVCaptureDeviceDiscoverySession supportedMultiCamDeviceSets]'`
    - 参考 : https://gist.github.com/Neos21/1ef84b2114a9946663e130ffd210b742
    - __現時点では、最大3つのレンズでの同時撮影が可能__
- バックグラウンドに移ると、デバッグコンソールに以下のエラーが出力されている
    - `Can't end BackgroundTask: no background task exists with identifier 1 (0x1), or it may have already been ended. Break in UIApplicationEndBackgroundTaskError() to debug.`
    - Apple 公式のサンプルコード [AVMultiCamPiP: Capturing from Multiple Cameras](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avmulticampip_capturing_from_multiple_cameras) でも同じエラーが表示されていた
    - 解決方法不明
- 作者の Swift ちから不足によるバギーな挙動
    - アプリがバックグラウンドに移動した時の処理やエラーハンドリング、iPhone 11 Pro Max 以外の端末で動かした場合の処理が不十分
    - うまくカメラが起動しなかったり、フォトライブラリへの保存に失敗する場合があったり…
    - プルリクで助けてください


## Author

[Neo](http://neo.s21.xrea.com/) ([@Neos21](https://twitter.com/Neos21))


## Links

- [Neo's World](http://neo.s21.xrea.com/)
- [Corredor](http://neos21.hatenablog.com/)
- [Murga](http://neos21.hatenablog.jp/)
- [El Mylar](http://neos21.hateblo.jp/)
- [Neo's GitHub Pages](https://neos21.github.io/)
- [GitHub - Neos21](https://github.com/Neos21/)
