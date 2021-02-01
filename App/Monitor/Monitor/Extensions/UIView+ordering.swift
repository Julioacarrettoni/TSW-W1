import Foundation
import UIKit

extension UIView {
    /// Moves the view back so that it is rendered behind its siblings.
    func sendToBack() {
        self.superview?.sendSubviewToBack(self)
    }
}
