import Foundation
import CoreLocation
import Combine

class HeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0
    @Published var headingAccuracy: Double = 0
    @Published var isCalibrating: Bool = false
    
    var useTrueNorth: Bool = true {
        didSet {
            // Re-trigger heading update when mode changes
            if let lastHeading = lastHeadingData {
                updateHeading(from: lastHeading)
            }
        }
    }
    
    private var lastHeadingData: CLHeading?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.headingFilter = 1 // Update for every 1 degree change
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        
        lastHeadingData = newHeading
        updateHeading(from: newHeading)
        
        DispatchQueue.main.async {
            self.headingAccuracy = newHeading.headingAccuracy
        }
    }
    
    private func updateHeading(from newHeading: CLHeading) {
        DispatchQueue.main.async {
            if self.useTrueNorth && newHeading.trueHeading >= 0 {
                self.heading = newHeading.trueHeading
            } else {
                self.heading = newHeading.magneticHeading
            }
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        DispatchQueue.main.async {
            self.isCalibrating = true
        }
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        DispatchQueue.main.async {
            self.isCalibrating = false
        }
    }
}
