//
//  ReportCore.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/27.
//

import Foundation
import JavaScriptCore
import SwiftyJSON
import Alamofire


class Report {
    private var host: String = UserDefaults.standard.string(forKey: "host")!
    private var tableId: String = UserDefaults.standard.string(forKey: "tableId")!
    private var cookie: String = UserDefaults.standard.string(forKey: "cookie")!
    private var isAutoGPS: Bool = UserDefaults.standard.bool(forKey: "isAutoGPS")
    private var isRandHeat: Bool = UserDefaults.standard.bool(forKey: "isRandHeat")
    
    private var request: Request
    private var API: WEBAPI = WEBAPI(USERID: "", GUID: "", TASKHANDLER_URL: "", FORMID: "")

    init() {
        self.request = Request()
        self.request.setRequestHeaders(headers: [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/7.0.18(0x17001229) NetType/WIFI Language/zh_CN Edg/88.0.4324.96",
            ])

        let domain = URL(string: self.host)!.host!
        let cookieDict = self.cookie.components(separatedBy: "; ").reduce(into: [String: String]()) { (dict, item) in
            let pair = item.components(separatedBy: "=")
            dict[pair[0]] = pair[1]
        }
        self.request.setCookies(domain: domain, cookies: cookieDict)
    }
    
    func initInfo() -> RMsg<String> {
        let resp = self.request.get(url: "\(self.host)/Pages/Detail.aspx?ID=\(self.tableId)", headers: ["Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"])
        
        if resp.response == nil {
            return RMsg(status: false, message: "Init: response == nil")
        }
        
        if resp.response!.statusCode != 200 {
            return RMsg(status: false, message: "Init: statusCode != 200")
        }
        
        var html = ""
        var temp: RMsg<String>?
        // sync get response string
        let semaphore = DispatchSemaphore(value: 0)
        resp.responseString { res in
            switch res.result {
            case .success(let str):
                html = str as String
            case .failure(let error):
                temp = RMsg(status: false, message: "Init: Failed to get Response String.")
                print(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        
        if temp != nil {
            return temp!
        }
        
        let webapi = Utility.parseScript(script: html)
        if webapi == "" {
            return RMsg(status: false, message: "Init: parse webapi failed", data: "")
        }
        
        let context: JSContext = JSContext()
        context.evaluateScript("var WEBAPI = (\(webapi))")
        
        guard let taskHandlerUrl = context.evaluateScript("WEBAPI.TASKHANDLER_URL")?.toString() else {
            return RMsg(status: false, message: "Init: get WEBAPI.TASKHANDLER_URL failed")
        }
        guard let userId = context.evaluateScript("WEBAPI.USERAPI.USERID")?.toString() else {
            return RMsg(status: false, message: "Init: get WEBAPI.USERAPI.USERID failed")
        }
        guard let guid = context.evaluateScript("WEBAPI.GUID")?.toString() else {
            return RMsg(status: false, message: "Init: get WEBAPI.GUID failed")
        }
        guard let formId = context.evaluateScript("WEBAPI.FORMID")?.toString() else {
            return RMsg(status: false, message: "Init: get WEBAPI.FORMID failed")
        }
        
        self.API.TASKHANDLER_URL = taskHandlerUrl
        self.API.USERID = userId
        self.API.GUID = guid
        self.API.FORMID = formId
        
        return RMsg(status: true, message: "初始化信息成功")
    }
    
    func sqlQuery(key: String) -> RMsg<JSON> {
        let url = "\(self.host)\(self.API.TASKHANDLER_URL)"
        let body = [
            "Action": "exesql",
            "strSQLKey": key,
            "flag": "Query",
            "t": Utility.getTimestamp()
        ]

        let resp = self.request.post(url: url, body: body, headers: ["Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"])
        if resp.response == nil {
            return RMsg(status: false, message: "sqlQuery: response == nil")
        }

        if resp.response!.statusCode != 200 {
            return RMsg(status: false, message: "sqlQuery: statusCode != 200")
        }
        
        var temp: RMsg<JSON>?
        let semaphore = DispatchSemaphore(value: 0)
        resp.responseJSON { res in
//            debugPrint(res)
            switch res.result {
            case .success(let value):
                temp = RMsg(status: true, message: "", data: JSON(value))
            case .failure(let error):
                temp = RMsg(status: false, message: "sqlQuery: Failed to get Response String.")
                print(error)
            }
            semaphore.signal()
        }
        semaphore.wait()

        return temp!
    }
    
    func getLastRecord() -> RMsg<JSON> {
        let resp = self.sqlQuery(key: "SYS_SJYZ%24\(self.API.USERID)%7E\(Utility.getLastDay())")
        if resp.status == false {
            return resp
        }
        let json = JSON(resp.data!)
        
        if let rp = json.array {
            return RMsg(status: true, message: "", data: rp[0])
        }
        
        return RMsg(status: true, message: "Failed to get last record: \(resp.message)")
    }
    
    func getServerDate() -> RMsg<JSON> {
        let resp = self.sqlQuery(key: "SELECT_GETDATE%24")
        if resp.status == false {
            return resp
        }
        let json = JSON(resp.data!)

        if let date = json.array {
            return RMsg(status: true, message: "", data: date[0])
        }
        return RMsg(status: true, message: "Failed to get server date: \(resp.message)")
    }
    
    func generateReport(templateReportJSON: JSON, serverTimeJSON: JSON) -> RMsg<JSON> {
        var templateReportJSON = templateReportJSON
        
        guard let nowdate = serverTimeJSON["nowdate"].string else {
            return RMsg(status: false, message: "generateReport: failed to get nowdate")
        }
        
        guard let nowtime = serverTimeJSON["nowtime"].string else {
            return RMsg(status: false, message: "generateReport: failed to get nowtime")
        }

        templateReportJSON["GUID"].string = self.API.GUID
        templateReportJSON["YQ_SBRQ"].string = nowdate
        templateReportJSON["BZSJ"].string = nowtime
        templateReportJSON["YQDATE"].string = nowdate
                
        if self.isRandHeat {
            let heat = Utility.getRandHeat()
            templateReportJSON["YQ_DRTW"].string = heat
        }

        if self.isAutoGPS {
            let location = Utility.getGPS()
            if location == "" {
                return RMsg(status: false, message: "獲取定位失敗")
            }

            // valid location.
            let locationArray = location.components(separatedBy: " ")
            if locationArray.count != 3 {
                return RMsg(status: false, message: "定位格式錯誤： \(location)")
            }

            if locationArray[0].suffix(1) != "省" {
                return RMsg(status: false, message: "定位格式錯誤： \(location)")
            }

            if locationArray[1].suffix(1) != "市" {
                return RMsg(status: false, message: "定位格式錯誤： \(location)")
            }

            if locationArray[2].suffix(1) != "区" && locationArray[2].suffix(1) != "县"  && locationArray[2].suffix(1) != "市" {
                return RMsg(status: false, message: "定位格式錯誤： \(location)")
            }

            templateReportJSON["YQ_SZD"].string = location
        }

        let temp = [
            "main": [
                [
                    "TableName": "PROC_YQBS",
                    "Data": [templateReportJSON],
                    "TableId": self.tableId
                ]
            ],
            "sub": [],
            "LoginUserID": self.API.USERID,
            "GUID": self.API.GUID,
            "FORMID": self.API.FORMID
        ] as [String : Any]

        return RMsg(status: true, message: "", data: JSON.init(temp))
    }
    
    func submit(report: JSON) -> RMsg<String> {
        let url = "\(self.host)\(self.API.TASKHANDLER_URL)?Action=submit_model&t=\(Utility.getTimestamp())"
        // convert JSON to [String: Any]
        let body = report.dictionaryObject!
        let resp = self.request.post(url: url, body: body, encoding: JSONEncoding.default, headers: ["Content-Type": "application/json; charset=UTF-8"])
        if resp.response == nil {
            return RMsg(status: false, message: "submit: response == nil")
        }

        if resp.response!.statusCode != 200 {
            return RMsg(status: false, message: "submit: statusCode != 200")
        }

        var temp: RMsg<String>?
        let semaphore = DispatchSemaphore(value: 0)

        resp.responseString { res in
            switch res.result {
            case .success(let value):
                temp = RMsg(status: true, message: "", data: value as String)
                
            case .failure(let error):
                temp = RMsg(status: false, message: "submit: Failed to get Response String.")
                print(error)
            }
            semaphore.signal()
        }
        semaphore.wait()

        return temp!
    }

    func run() -> RMsg<String> {
        print("host: \(host)")
        print("tableId: \(tableId)")
        print("cookie: \(cookie)")
        print("isAutoGPS: \(isAutoGPS)")
        print("isRandHeat: \(isRandHeat)")
        
        if self.host == "" || self.tableId == "" || self.cookie == "" {
            return RMsg(status: false, message: "首次使用請先進入APP配置並保存")
        }

        var strMsg: RMsg<String>
        var jsonMsg: RMsg<JSON>
        
        strMsg = self.initInfo()
        if !strMsg.status {
            return strMsg
        }
        
        jsonMsg = self.getLastRecord()
        if !jsonMsg.status {
            return RMsg(status: jsonMsg.status, message: jsonMsg.message, data: jsonMsg.data?.rawString()!)
        }
        let lastRecord = jsonMsg.data!
        
        print("lastRecord -> ", lastRecord)
        
        jsonMsg = self.getServerDate()
        if !jsonMsg.status {
            return RMsg(status: jsonMsg.status, message: jsonMsg.message, data: jsonMsg.data?.rawString()!)
        }
        let serverDate = jsonMsg.data!
        
        print("serverDate -> ", serverDate)
        
        jsonMsg = self.generateReport(templateReportJSON: lastRecord, serverTimeJSON: serverDate)
        if !jsonMsg.status {
            return RMsg(status: jsonMsg.status, message: jsonMsg.message, data: jsonMsg.data?.rawString()!)
        }
        let genReport = jsonMsg.data!
        
        print("genReport -> ", genReport)
        
        strMsg = self.submit(report: genReport)
        return strMsg
    }
}
