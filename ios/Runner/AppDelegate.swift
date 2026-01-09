import Flutter
import UIKit
import flutter_config

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FlutterConfig.register(with: self.registrar(forPlugin: "flutter_config")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
