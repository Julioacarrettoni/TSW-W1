import Foundation
import UIKit

extension UIActivityIndicatorView {
    var theOtherIsAnimating: Bool {
        set {
            if newValue != theOtherIsAnimating {
                if newValue {
                    self.startAnimating()
                } else {
                    self.stopAnimating()
                }
            }
        }
        
        get {
            self.isAnimating
        }
    }
}
