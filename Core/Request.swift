//
//  Request.swift
//  ypcReport
//
//  Created by mas0n on 2022/12/29.
//

import Foundation
import Alamofire

// http request
class Request {
    var session: Session
    
    init() {
        self.session = Session(configuration: URLSessionConfiguration.af.default)
    }

    func setCookies(domain: String, cookies: [String: String]) {
       for (key, value) in cookies {
           self.session.sessionConfiguration.httpCookieStorage?.setCookie(HTTPCookie(properties: [
               .domain: domain,
               .path: "/",
               .name: key,
               .value: value,
               .expires: Date(timeIntervalSinceNow: 3600 * 24 * 30)
           ])!)
       }
    }

    func setRequestHeaders(headers: [String: String]) {
        self.session.sessionConfiguration.httpAdditionalHeaders = headers
    }

    func post(url: String, body: [String: Any], encoding: ParameterEncoding = URLEncoding.default, headers: [String: String] = [:]) -> DataRequest {
        // sync request with Alamofire session, json body
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let request = self.session.request(url, method: .post, parameters: body, encoding: encoding, headers: HTTPHeaders(headers))
        request.response { resp in
            semaphore.signal()
        }
        semaphore.wait()
        return request
    }

    func get(url: String, headers: [String: String] = [:]) -> DataRequest {
        // sync request with Alamofire session
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let request = self.session.request(url, method: .get, headers: HTTPHeaders(headers))
        request.response { resp in
            semaphore.signal()
        }
        semaphore.wait()
        return request
    }

}
