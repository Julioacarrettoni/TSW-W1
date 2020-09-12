import Foundation
import FakeService

extension Environment {
    /// The production profile
    static func setProduction() {
        FakeService.Current = Environment.production
    }
    
    /// All request are successful but time pass faster
    ///
    /// - parameter multipler: Multipler applied to each second that passes.
    static func setNotFailsWithSpeedMultipler(of multipler: Double) {
        var environment = Environment.production
        let referenceDate = Date.init(timeIntervalSinceNow: 0)
        environment.delay = { 0.1 }
        environment.tick = { -referenceDate.timeIntervalSinceNow * Double(multipler)}
        FakeService.Current = environment
    }
    
    /// The intermitent profile, every other request fails
    static func setIntermitentFailure() {
        var environment = Environment.production
        var failNext = false
        environment.failNext = {
            failNext.toggle()
            return failNext
        }
        FakeService.Current = environment
    }
    
    /// Every 4th request is delayed by X seconds, default: 10
    ///
    /// - parameter delay: Delay for every 4th request in seconds.
    static func set4thDelayed(by delay: Double = 10.0) {
        var environment = Environment.production
        
        var index = -1
        let delays: [Double] = [ 1, 1, 1, delay ]
        environment.delay = {
            index += 1
            return delays[index % delays.count]
        }
        
        FakeService.Current = environment
    }
}
