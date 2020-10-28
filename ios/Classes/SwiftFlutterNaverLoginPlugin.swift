import Flutter
import UIKit
import NaverThirdPartyLogin
import Alamofire

public class SwiftFlutterNaverLoginPlugin:FlutterPluginAppLifeCycleDelegate, FlutterPlugin, NaverThirdPartyLoginConnectionDelegate{
    static let methodChannel:String = "flutter_naver_login"
    static var naverResult:FlutterResult?
    
    var thirdPartyLoginConn:NaverThirdPartyLoginConnection?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_naver_login", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNaverLoginPlugin()
        instance._init()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func _init(){
        thirdPartyLoginConn = NaverThirdPartyLoginConnection.getSharedInstance()
        thirdPartyLoginConn?.isNaverAppOauthEnable = true
        thirdPartyLoginConn?.isInAppOauthEnable = true
        thirdPartyLoginConn?.isOnlyPortraitSupportedInIphone()
        
        thirdPartyLoginConn?.serviceUrlScheme = Bundle.main.object(forInfoDictionaryKey: "kServiceAppUrlScheme") as? String
        thirdPartyLoginConn?.consumerKey = Bundle.main.object(forInfoDictionaryKey: "kConsumerKey") as? String
        thirdPartyLoginConn?.consumerSecret = Bundle.main.object(forInfoDictionaryKey: "kConsumerSecret") as? String
        thirdPartyLoginConn?.appName = Bundle.main.object(forInfoDictionaryKey: "kServiceAppName") as? String
        thirdPartyLoginConn?.delegate = self;
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftFlutterNaverLoginPlugin.naverResult = result
        switch call.method{
        case "logIn":
            thirdPartyLoginConn?.requestThirdPartyLogin()
            break
        case "logOut":
            thirdPartyLoginConn?.requestDeleteToken()
            break
        case "getCurrentAccount":
            self.getInfo()
            break
        case "getCurrentAccessToken":
            let map = ["status":"getToken",
                       "accessToken":thirdPartyLoginConn?.accessToken,
                       "tokenType":thirdPartyLoginConn?.tokenType,
            ] as [String: Any]
            result(map)
            break
        default:
            break
        //            case
        }
    }
    
    public func getInfo() {
        guard let isValidAccessToken = thirdPartyLoginConn?.isValidAccessTokenExpireTimeNow() else {
            SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "isValidAccessToken is Not Valid", details: "isValidAccessToken is Not Valid"))
            return
        }
        print("isValidAccessToken")
        print(isValidAccessToken)
        if !isValidAccessToken {
            SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "isValidAccessToken is Not Valid", details: "isValidAccessToken is Not Valid"))
            return
        }
        
        guard let tokenType = thirdPartyLoginConn?.tokenType else { return }
        guard let accessToken = thirdPartyLoginConn?.accessToken else { return }
        print(tokenType)
        print(accessToken)
        let urlStr = "https://openapi.naver.com/v1/nid/me"
        let url = URL(string: urlStr)!
        
        let authorization = "\(tokenType) \(accessToken)"
        
        let req = AF.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": authorization])
        
        req.responseJSON { response in
            guard let result = response.value as? [String: Any] else {
                SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "result is Not Map", details: "result is Not Map"))
                return
                
            }
            guard let object = result["response"] as? [String: Any] else {
                SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "response is Not Map", details: "response is Not Map"))
                return
                
            }
            guard let email = object["email"] as? String else {
                SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "email is Not String", details: "email is Not String"))
                return
                
            }
            guard let id = object["id"] as? String else {
                
                SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "id is Not String", details: "id is Not String"))
                return
            }
            
            let name = object["name"]
            let gender = result["gender"];
            let age = result["age"];
            let profile_image = result["profile_image"];
            let nickname = result["nickname"];
            let birthday = result["birthday"];
            
            let info = [
                "status":"loggedIn",
                "id": id,
                "email": email,
                "name": name,
                "gender":gender,
                "age":age,
                "profile_image":profile_image,
                "nickname":nickname,
                "birthday":birthday
            ] as [String: Any]
            
            SwiftFlutterNaverLoginPlugin.naverResult!(info)
        }
    }
    
    
    override public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if !url.absoluteString.contains("authCode") {
            if SwiftFlutterNaverLoginPlugin.naverResult == nil{
                SwiftFlutterNaverLoginPlugin.naverResult!(FlutterError(code: "LoginError", message: "Login Fail", details: "사용자가 중간에 취소함"))
            }
          
        }else{
           return NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
        }
        
        return false;
    }
    
    public func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        self.getInfo()
    }
    
    public func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        self.getInfo()
    }
    
    public func oauth20ConnectionDidFinishDeleteToken() {
        print("oauth20ConnectionDidFinishDeleteToken")
        let info = [
            "status": "cancelledByUser",
            "isLogin": false,
        ] as [String:Any]
        
        SwiftFlutterNaverLoginPlugin.naverResult!(info)
        
        
    }
    
    public func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        print("oauth20Connection");
        let info = [
            "status": "cancelledByUser",
            "isLogin": false,
        ] as [String:Any]
        
        SwiftFlutterNaverLoginPlugin.naverResult!(info)
        
    }
    
    
}
