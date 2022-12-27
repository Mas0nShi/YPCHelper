//
//  ContentView.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/27.
//

import SwiftUI
import CoreLocation

struct HostField: View {
    @Binding var host: String;
    
    var body: some View {
        return VStack (alignment: .leading, spacing: -25) {
            Label("Host", systemImage: "")
                .labelStyle(.titleOnly)
                .padding()
            
            TextField(host, text: $host)
                .textFieldStyle(.roundedBorder)
                .padding()
                
        }
    }
}

struct TableIdField: View {
    @Binding var tableId: String;
    
    var body: some View {
        return VStack (alignment: .leading, spacing: -25) {
            Label("Table ID", systemImage: "")
                .labelStyle(.titleOnly)
                .padding()
            
            TextField(tableId, text: $tableId)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
    }
}

struct CookieField: View {
    @Binding var cookie: String;
    
    var body: some View {
        return VStack(alignment: .leading, spacing: -25)  {
            Label("Cookie", systemImage: "")
                .labelStyle(.titleOnly)
                .padding()
            
            TextField(cookie, text: $cookie)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
    }
}

struct ToggleField: View {
    @Binding var isAutoGPS: Bool;
    @Binding var isRandHeat: Bool;
    
    var body: some View {
        return VStack(alignment: .center) {
            Toggle(isOn: $isAutoGPS) {
                Text("启用定位")
            }
            .padding()
            
            Toggle(isOn: $isRandHeat) {
                Text("随机温度")
            }
            .padding()
        }
    }
}

struct SaveButtonField: View {
    @Binding var host: String;
    @Binding var tableId: String;
    @Binding var cookie: String;
    @Binding var isAutoGPS: Bool;
    @Binding var isRandHeat: Bool;
    
    @Binding var isConfigSave: Bool;
    
    var body: some View {
        return Button("保存", action: {
            saveConfig(host: host, tableId: tableId, cookie: cookie, isAutoGPS: isAutoGPS, isRandHeat: isRandHeat)
            isConfigSave.toggle();
        })
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(width: 120, height: 50)
        .background(Color.green)
        .cornerRadius(15.0)
        .alert(isPresented: $isConfigSave) {
            Alert(title: Text("提示"), message: Text("保存成功！"))
        }
    }
}

func saveConfig(host: String, tableId: String, cookie: String, isAutoGPS: Bool, isRandHeat: Bool) {
    UserDefaults.standard.set(host, forKey: "host")
    UserDefaults.standard.set(tableId, forKey: "tableId")
    UserDefaults.standard.set(cookie, forKey: "cookie")
    UserDefaults.standard.set(isAutoGPS, forKey: "isAutoGPS")
    UserDefaults.standard.set(isRandHeat, forKey: "isRandHeat")
}



struct ContentView: View {
    @Binding var cookie: String;

    @Binding var host: String;
    @Binding var tableId: String;
    
    @Binding var isAutoGPS: Bool;
    @Binding var isRandHeat: Bool;

    @State private var isConfigSave: Bool = false;
    
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 50) {
            
            Text("Hi, YPCer!").font(.title)

            VStack(alignment: .leading, spacing: -10) {
                HostField(host: $host)
                TableIdField(tableId: $tableId)
                
                Divider().padding(25)
                
                CookieField(cookie: $cookie)
                
                Divider().padding(25)
                
                ToggleField(isAutoGPS: $isAutoGPS, isRandHeat: $isRandHeat)
                
                Divider().padding(25)
            }
            
            SaveButtonField(host: $host, tableId: $tableId, cookie: $cookie, isAutoGPS: $isAutoGPS, isRandHeat: $isRandHeat, isConfigSave: $isConfigSave)
           
        }
        .padding()
        
    }
}

