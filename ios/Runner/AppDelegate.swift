import Flutter
import UIKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // IDFA許可要求（iOS 14.5以降）
    if #available(iOS 14.5, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        ATTrackingManager.requestTrackingAuthorization { status in
          switch status {
          case .authorized:
            print("IDFA tracking authorized")
          case .denied:
            print("IDFA tracking denied")
          case .notDetermined:
            print("IDFA tracking not determined")
          case .restricted:
            print("IDFA tracking restricted")
          @unknown default:
            print("IDFA tracking unknown status")
          }
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
