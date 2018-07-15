//
//  NVAPIManager.swift
//  NaverPapago
//
//  Created by 영준 이 on 2016. 12. 8..
//  Copyright © 2016년 leesam. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

/**
    Naver Papago Kit
 */
public class NaverPapago : NSObject{
    /// Root Url for Naver API
    internal static let NaverAPIURLV1 = URL(string: "https://openapi.naver.com/v1")!;
    /// Shared Singleton Instance of NaverPapago
    public static let shared = NaverPapago();
    
    /// Papago API Type
    enum PapagoType : String{
        ///Neural Machine Translation
        case nmt
        ///Statistical Machine Translation
        case smt
    }
    
    private static let plistName = "NaverPapago";
    private static let plistFile : String = {
        return "\(plistName).plist"
    }()
    /// Dictionary from NaverPapago.plist
    private var infos : [String : String]{
        get{
            guard let plist = Bundle.main.path(forResource: type(of: self).plistName, ofType: "plist") else{
                preconditionFailure("Please create plist file named of \(type(of: self).plistName). file[\(type(of: self).plistFile)]");
            }
            
            guard let dict = NSDictionary.init(contentsOfFile: plist) as? [String : String] else{
                preconditionFailure("\(type(of: self).plistFile) is not Property List.");
            }
            
            return dict;
        }
    };
    
    /// Gets Client Id for given PapagoType
    private func clientIDForAPI(_ api : PapagoType) -> String{
        guard let value = self.infos["ClientID"] else{
            preconditionFailure("Please add 'ClientID' into \(type(of: self).plistFile)");
        }
        
        return value;
    }

    /// Gets SecretKey for given PapagoType
    private func clientSecretForAPI(_ api : PapagoType) -> String{
        guard let value = self.infos["ClientSecret"] else{
            preconditionFailure("Please add 'ClientSecret' into \(type(of: self).plistFile)");
        }
        
        return value;
    }
    
    enum PapagoLocale : String{
        case korean = "ko-kore"
        case japanese = "ja"
        case english = "en"
        case chinese = "zh-Hans"
        case taiwan = "zh-Hant"
        case spain = "es"
        case france = "fr"
        case vietnam = "vi"
        case thai = "th"
        case indonesian = "id"
    }
    
    enum PapagoLanguage : String{
        case korean = "ko"
        case japanese = "ja"
        case english = "en"
        case chinese = "zh-CN"
        case taiwan = "zh-TW"
        case spain = "es"
        case france = "fr"
        case vietnam = "vi"
        case thai = "th"
        case indonesian = "id"
    }
    
    static let supportedNMTLangs : [PapagoLocale : PapagoLanguage] = [.korean : .korean, .japanese : .japanese, .english : .english, .chinese : .chinese, .taiwan : .taiwan, .spain : .spain, .france : .france, .vietnam : .vietnam, .thai : .thai,  .indonesian : .indonesian];
    static let supportedSMTLangs : [PapagoLocale : PapagoLanguage] = [.korean : .korean, .japanese : .japanese, .english : .english, .chinese : .chinese, .taiwan : .taiwan];
    
    /**
        Returns Papago language code converted from given locale
         - parameter locale: Locale to get Papago language code
         - parameter papagoType: Papago API Type
         - returns: Papago language code converted from given locale
    */
    static func convertToLang(_ locale : Locale, papagoType: PapagoType) -> PapagoLanguage?{
        var langs : [PapagoLocale : PapagoLanguage] = [:];
        
        switch papagoType{
            case .nmt:
                langs = self.supportedNMTLangs;
                break;
            case .smt:
                langs = self.supportedSMTLangs;
                break;
        }
        
        return langs.first(where: { (key: PapagoLocale, value: PapagoLanguage) -> Bool in
            return locale.identifier.lowercased().hasPrefix(key.rawValue.lowercased());
        })?.value;
    }
    
    static let DefaultSourceLang : PapagoLanguage = .korean;
    
    /**
        Returns the indication to able to translate by given locale of source/target
         - parameter source: locale of native text
         - parameter target: locale of translated text
         - returns: the indication to able to translate by given locale of source/target
    */
    public static func canSupportTranslate(source : Locale, target : Locale) -> Bool{
        return ((source.languageCode == PapagoLanguage.korean.rawValue
            || target.languageCode == PapagoLanguage.korean.rawValue)) && (source.languageCode != target.languageCode);
    }
    
    /**
        Call Naver Papago NMT
     
         - parameter text: native text to translate
         - parameter source: locale of native text
         - parameter target: locale of translated text
         - parameter completionHandler: Handler to execute after the translation
        # API Introduce
        * [https://developers.naver.com/products/nmt](https://developers.naver.com/products/nmt)
        # Reference
        * [https://developers.naver.com/docs/nmt/reference](https://developers.naver.com/docs/nmt/reference/)
    */
    public func requestTranslateByNMT(text : String, source : Locale, target : Locale, completionHandler: @escaping (_ result: NaverPapagoNMTResult) -> Void){
        var naverReq = NaverPapagoNMTRequest(id: self.clientIDForAPI(.nmt),
                                             secret: self.clientSecretForAPI(.nmt));
        
        //Checks source and target locale
        let sourceLang = type(of: self).convertToLang(source, papagoType: .nmt) ?? NaverPapago.DefaultSourceLang;
        let targetLang = type(of: self).convertToLang(target, papagoType: .nmt) ?? PapagoLanguage.english;
        naverReq.data.source = sourceLang.rawValue;
        naverReq.data.target = targetLang.rawValue;
        naverReq.data.text = text;
        
        //let json = String(data: naverReq.urlRequest.httpBody!, encoding: .utf8);
        //print("naver => request \(naverReq.urlRequest) -> \(json ?? "")");
        
        //Turns on network indicator
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        }
        
        //Calls Naver Papago NMT
        Alamofire.request(naverReq.urlRequest).responseObject(success: NaverPapagoNMTResponse.self,
                                                              fail: NaverPapagoNMTError.self,
                                                              failureHandler: {(fail, response) in
                                                                guard let fail = fail else{
                                                                    return;
                                                                }
                                                                
                                                                completionHandler(NaverPapagoNMTResult.error(fail));
        }) { (success, response) in
            //Turns off network indicator
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false;
            }
            let translatedText = success.message.result.text;
            
            //Executes success callback
            completionHandler(NaverPapagoNMTResult.success(translatedText));
            //completionHandler?(response.response?.statusCode ?? 200, translatedText, nil);
        }
    }
    
    /**
     Call Naver Papago SMT
     
     - parameter text: native text to translate
     - parameter source: locale of native text
     - parameter target: locale of translated text
     - parameter completionHandler: Handler to execute after the translation
     # API Introduce
     * [https://developers.naver.com/products/nmt](https://developers.naver.com/products/smt)
     # Reference
     * [https://developers.naver.com/docs/nmt/reference](https://developers.naver.com/docs/smt/reference/)
     */
    public func requestTranslateBySMT(text : String, source : Locale, target : Locale, completionHandler: @escaping (NaverPapagoSMTResult) -> Void){
        var naverReq = NaverPapagoSMTRequest(id: self.clientIDForAPI(.nmt),
                                       secret: self.clientSecretForAPI(.nmt));
        
        //Checks source and target locale
        let sourceLang = type(of: self).convertToLang(source, papagoType: .smt) ?? NaverPapago.DefaultSourceLang;
        let targetLang = type(of: self).convertToLang(target, papagoType: .smt) ?? PapagoLanguage.english;
        naverReq.data.source = sourceLang.rawValue;
        naverReq.data.target = targetLang.rawValue;
        naverReq.data.text = text;
        
        //let json = String(data: naverReq.urlRequest.httpBody!, encoding: .utf8);
        //print("naver => request \(naverReq.urlRequest) -> \(json ?? "")");
        
        //Turns on network indicator
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false;
        }
        
        //Calls Naver Papago SMT
        Alamofire.request(naverReq.urlRequest).responseObject(success: NaverPapagoSMTResponse.self,
                                                              fail: NaverPapagoSMTError.self,
                                                              failureHandler: {(fail, response) in
            completionHandler(NaverPapagoSMTResult.error(fail!));
        }) { (success, response) in
            //Turns off network indicator
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false;
            }
            
            //Executes success callback
            let translatedText = success.message.result.text;
            completionHandler(NaverPapagoSMTResult.success(translatedText));
            //completionHandler?(response.response?.statusCode ?? 200, translatedText, nil);
        }
    }
}
