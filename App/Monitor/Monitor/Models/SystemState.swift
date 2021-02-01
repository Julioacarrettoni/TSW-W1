import Foundation

/// The system state at a given point in time
struct SystemState {
    /// The time of the reading
    let date: Date
    /// Available readings temperatures
    let temperatures: [Reading]
    /// Available readings for pressure
    let pressure: [Reading]
}
