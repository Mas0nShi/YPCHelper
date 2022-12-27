//
//  ypcReportApp.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/27.
//
import CoreLocation
import SwiftUI

@main
struct ypcReportApp: App {
    @State private var host: String = UserDefaults.standard.string(forKey: "host")
        ?? "http://ehallwx.ypc.edu.cn"
    @State private var tableId: String = UserDefaults.standard.string(forKey: "tableId")
        ?? "2cd898ec1e394ab1a4c7c539a41a1487"
    @State private var cookie: String = UserDefaults.standard.string(forKey: "cookie")
        ?? ""

    @State private var isAutoGPS: Bool = UserDefaults.standard.bool(forKey: "isAutoGPS")
    @State private var isRandHeat: Bool = UserDefaults.standard.bool(forKey: "isRandHeat")



    var body: some Scene {
        WindowGroup {
            ContentView(cookie: $cookie, host: $host, tableId: $tableId, isAutoGPS: $isAutoGPS, isRandHeat: $isRandHeat)
        }
        
    }

    init() {
        let authorizationStatus: CLAuthorizationStatus
        // 兼容IOS 14+
        if #available(iOS 14, *) {
            authorizationStatus = CLLocationManager().authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        // 没有授权，请求用户授权
        if authorizationStatus == .notDetermined {
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
        }
        // 用户拒绝授权
        else if authorizationStatus == .denied {
            
            exit(0)
        }
    }
}
