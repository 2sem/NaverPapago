//
//  NaverPapagoNMTRequest.swift
//  talktrans
//
//  Created by 영준 이 on 2018. 4. 14..
//  Copyright © 2018년 leesam. All rights reserved.
//

import Foundation

public struct NaverPapagoNMTRequest{
    enum HeaderName : String{
        case ClientId = "X-Naver-Client-Id";
        case ClientSecret = "X-Naver-Client-Secret";
        case ContentType = "Content-Type";
    }
    
    /// Request Body
    struct RequestData : Codable{
        /// Source Locale
        var source : String;
        /// Translated Locale
        var target : String;
        /// Text to translate
        var text : String;
        
        // JSON String generated for http body
        var json : Data?{
            let encoder = JSONEncoder.init();
            encoder.outputFormatting = [.prettyPrinted];
            
            return try? encoder.encode(self);
        }
    }
    
    /// Client ID for http header
    var clientId : String?{
        mutating get{
            return self[.ClientId];
        }
        set(value){
            self[.ClientId] = value;
        }
    }
    
    /// Client Secret Key for http header
    var clientSecret : String?{
        mutating get{
            return self[.ClientSecret];
        }
        set(value){
            self[.ClientSecret] = value;
        }
    }
    
    private lazy var _urlRequest : URLRequest = {
        var url = NaverPapago.NaverAPIURLV1;
        url.appendPathComponent("papago/n2mt");
        var req = URLRequest.init(url: url);
        req.httpMethod = "POST";
        
        return req;
    }()
    
    var urlRequest : URLRequest{
        mutating get{
            self._urlRequest.httpBody = self.data.json;
            /*for header in self._urlRequest.allHTTPHeaderFields ?? [:]{
                print("http header[\(header.key)] : \(header.value)");
            }*/
            
            return self._urlRequest;
        }
    }
    
    var data : RequestData = RequestData.init(source: "", target: "", text: "");
    
    /**
        Gets header field
    */
    private subscript(field : HeaderName) -> String?{
        mutating get{
            return self._urlRequest.value(forHTTPHeaderField: field.rawValue);
        }
        
        set(value){
            //print("setting http header[\(field)] : \(value)");
            guard let value = value else{
                self._urlRequest.setValue(nil, forHTTPHeaderField: field.rawValue);
                return;
            }
            
            if self[field] == nil{
                self._urlRequest.addValue(value, forHTTPHeaderField: field.rawValue);
                print("add http header[\(field)] : \(value)");
            }else{
                self._urlRequest.setValue(value, forHTTPHeaderField: field.rawValue);
                print("set http header[\(field)] : \(value)");
            }
        }
    }
    
    init(id: String, secret: String) {
        self.clientId = id;
        self.clientSecret = secret;
        
        self[.ContentType] = "application/json;charset=utf-8";
    }
}
