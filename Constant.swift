import Foundation
import UIKit

// get app version
func getAppVersion() -> String? {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return version
    }
    return nil
}

