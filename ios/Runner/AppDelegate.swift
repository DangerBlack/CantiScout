import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "cantiscout/file_intent"

    /// Stores the path of a file that was used to launch the app (cold start).
    /// Dart retrieves this via getInitialFile once the engine is ready.
    private var pendingFilePath: String? = nil
    private var fileChannel: FlutterMethodChannel? = nil

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        if let controller = window?.rootViewController as? FlutterViewController {
            fileChannel = FlutterMethodChannel(
                name: channelName,
                binaryMessenger: controller.binaryMessenger
            )
            fileChannel!.setMethodCallHandler { [weak self] call, result in
                if call.method == "getInitialFile" {
                    result(self?.pendingFilePath)
                    self?.pendingFilePath = nil
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return result
    }

    /// Called when a file is opened with CantiScout (both cold and warm start).
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let path = url.path
        // Store for getInitialFile (handles cold-start race condition).
        pendingFilePath = path
        // Also invoke directly — works when the Dart engine is already running (warm start).
        fileChannel?.invokeMethod("onNewFile", arguments: path)
        return true
    }
}
