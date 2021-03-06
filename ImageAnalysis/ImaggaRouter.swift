//
//  ImaggaRouter.swift
//  ImageAnalysis
//
//  Created by 李超逸 on 2018/03/04.
//  Copyright © 2018 李超逸. All rights reserved.
//

import Foundation
import Alamofire

public enum ImaggaRouter: URLRequestConvertible {
    static let baseURLPath = "http://api.imagga.com/v1"
    static let authenticationToken = "Basic YWNjXzcxNTEwZTczNTc1YmVmZjpkOTMwZjA4ZDRlNWVlMWI5MTg5NzEyNjlmNzc5OTBlYQ=="
    
    case content
    case tags(String)
    case colors(String)
    
    var method: HTTPMethod {
        switch self {
        case .content:
            return .post
        case .tags, .colors:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .content:
            return "/content"
        case .tags:
            return "/tagging"
        case .colors:
            return "/colors"
        }
    }
    
    public func asURLRequest() throws -> URLRequest {
        let parameters: [String: Any] = {
            switch self {
            case .tags(let contentID):
                return ["content": contentID]
            case .colors(let contentID):
                return ["content": contentID, "extract_object_colors": 0]
            default:
                return [:]
            }
        }()
        
        let url = try ImaggaRouter.baseURLPath.asURL()
        
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue(ImaggaRouter.authenticationToken, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = TimeInterval(10 * 1000)
        
        return try URLEncoding.default.encode(request, with: parameters)
    }
}
