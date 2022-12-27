//
//  Utility.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/29.
//

import UIKit
import Foundation
import CoreLocation

class Utility {
    // Get random heat range 36.3 - 36.8
    static func getRandHeat() -> String {
        let rand = Double.random(in: 36.3...36.8)
        return String(format: "%.1f", rand)
    }

    // Get current time, format: "年月日"
    static func getCurrentTime() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    // Get last day, format: "年-月-日"
    static func getLastDay() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date.addingTimeInterval(-(24 * 60 * 60)))
    }

    // Get timestamp 13 bit
    static func getTimestamp() -> String {
        let date = Date()
        let timeInterval: TimeInterval = date.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return String(timeStamp)
    }

    // parse html script: var WEB_API=(.*);
    static func parseScript(script: String) -> String {
        let pattern = #"var WEBAPI=(.*);"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let results = regex.matches(in: script, options: [], range: NSRange(location: 0, length: script.count))
        guard results.count > 0 else {
            return ""
        }
        let result = results[0]
        let range = Range(result.range(at: 1), in: script)!
        let text = script[range]

        return String(text)
    }
    
   

    // Get GPS, format: "province city district"
    static func getGPS() -> String {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        let location = locationManager.location!
        locationManager.stopUpdatingLocation()
        
        let geocoder = CLGeocoder()
        
        var gps = ""
        
        // sync get gps
        let semaphore = DispatchSemaphore(value: 0)
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil {
                let placemark = placemarks?.first
                let province = placemark?.administrativeArea
                let city = placemark?.locality
                let district = placemark?.subLocality
                gps = "\(province ?? "") \(city ?? "") \(district ?? "")"
            }
            semaphore.signal()
        }
        semaphore.wait()
        
        
        return gps
    }
}
