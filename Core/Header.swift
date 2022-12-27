//
//  Types.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/29.
//

import Foundation

struct RMsg<T> {
    var status: Bool
    var message: String
    var data: T?
}

struct WEBAPI {
    var USERID: String
    var GUID: String
    var TASKHANDLER_URL: String
    var FORMID: String
}

