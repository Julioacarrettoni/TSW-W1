import Foundation

public struct Configuration: Equatable {
    public struct Delay: Equatable {
        /// How often the API for refreshing the configuration should be pool
        public let configuration: TimeInterval
        /// How often the API for the map information should be pool
        public let map: TimeInterval
        /// How often the API for rendering paths should be pool
        public let path: TimeInterval
    }
    
    /// Different pooling delays
    public let delays: Delay
    
    /// The location of the currently designated HQ
    public let central: Location
}
