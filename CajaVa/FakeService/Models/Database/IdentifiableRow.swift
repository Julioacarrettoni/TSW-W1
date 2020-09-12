import Foundation

public protocol IdentifiableRow {
    var id: String { get }
    var tick: Int { get }
}
