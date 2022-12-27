//
//  RunTask.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/29.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct RunTask: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "RunTaskIntent"

    static var title: LocalizedStringResource = "执行任务"
    static var description = IntentDescription("run task.")

//    static var parameterSummary: some ParameterSummary {
//        Summary
//    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Place your refactored intent handler code here.
        let report = Report()
         let ret = report.run()
//        let ret = RMsg(status: true, message: "Failed", data: #"{"status":1,"msg":"提交成功！"}"#)
        
//        let status = ret.status
        let msg = ret.status ? ret.data! : ret.message
        
        print(msg)
        return .result(value: String(msg))
    }
}


