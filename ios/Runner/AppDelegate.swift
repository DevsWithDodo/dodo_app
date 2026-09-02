import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Recommended by firebase_messaging for UIScene apps.
    if let pluginClass = NSClassFromString("FLTFirebaseMessagingPlugin") as? NSObject.Type {
      let selector = NSSelectorFromString("configureNotificationCenterDelegate")
      if pluginClass.responds(to: selector) {
        _ = pluginClass.perform(selector)
      }
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
