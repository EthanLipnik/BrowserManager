//
//  BrowserManager.swift
//
//  Created by Ethan Lipnik.
//

import Foundation
import UIKit
import SafariServices

open class BrowserManager {
    static let shared = BrowserManager()
    
    struct Browsers {
        let firefox = Browser(scheme: URL(string: "firefox://"), name: "firefox")
        let opera = Browser(scheme: URL(string: "opera://"), name: "opera")
        let googleChrome = Browser(scheme: URL(string: "googlechrome://"), name: "google chrome")
        let dolphin = Browser(scheme: URL(string: "dolphin://"), name: "dolphin")
        let brave = Browser(scheme: URL(string: "brave://"), name: "brave")
        let safari = Browser(name: "safari")
        let inAppSafari = Browser(name: "in-app safari")
        lazy var array: [Browser] = {
            return [inAppSafari, safari, firefox, opera, googleChrome, dolphin, brave]
        }()
    }
    
    var supportedBrowsers = Browsers()
    
    lazy var installedBrowsers: [Browser] = {
        return supportedBrowsers.array.filter({ $0.isInstalled() })
    }()
    var defaultBrowser: Browser {
        get {
            return (installedBrowsers.first(where: { $0.name == UserDefaults.standard.string(forKey: "defaultBrowser") }) ?? Browser(name: "in-app safari"))
        }
        set(value) {
            
            guard installedBrowsers.contains(where: { $0 == value }) else {
                self.defaultBrowser = (installedBrowsers.first(where: { $0.name == UserDefaults.standard.string(forKey: "defaultBrowser") }) ?? Browser(name: "in-app safari"))
                
                return
            }
            
            UserDefaults.standard.set(value.name, forKey: "defaultBrowser")
        }
    }
        
    
    let app = UIApplication.shared

    fileprivate func encodeByAddingPercentEscapes(_ input: String) -> String {
        return NSString(string: input).addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]"))!
    }

    open func open(url: URL, presentingController: UIViewController? = nil, completion: ((() -> Void))? = nil) {
        DispatchQueue.main.async { [weak self] in
            
            func openInSafari() {
                if #available(iOS 10.0, *) {
                    self?.app.open(url, options: [:], completionHandler: { (_) in
                        completion?()
                    })
                } else {
                    self?.app.openURL(url)
                    completion?()
                }
            }
            let scheme = url.scheme
            if scheme == "http" || scheme == "https" {
                
                guard let browser = self?.defaultBrowser else { return }
                switch browser.name {
                case "in-app safari":
                    if let presenting = presentingController {
                        
                        let VC = SFSafariViewController(url: url)
                        
                        if #available(iOS 11.0, *) {
                            VC.dismissButtonStyle = .done
                        }
                        VC.modalPresentationStyle = .pageSheet
                        
                        presenting.present(VC, animated: true) {
                            completion?()
                        }
                    } else {
                        openInSafari()
                    }
                case "safari":
                    openInSafari()
                case "firefox", "opera", "brave":
                    if let browserScheme = browser.scheme, let escaped = self?.encodeByAddingPercentEscapes(url.absoluteString), let firefoxURL = URL(string: "\(browserScheme.absoluteString)open-url?url=\(escaped)") {
                        if #available(iOS 10.0, *) {
                            self?.app.open(firefoxURL, options: [:], completionHandler: { (_) in
                                completion?()
                            })
                        } else {
                            self?.app.openURL(url)
                            completion?()
                        }
                    } else {
                        openInSafari()
                    }
                case "google chrome", "dolphin":
                    if let browserScheme = browser.scheme, let finalURL = URL(string: url.absoluteString.replacingOccurrences(of: "http://", with: browserScheme.absoluteString).replacingOccurrences(of: "https://", with: "googlechrome://")) {
                        if #available(iOS 10.0, *) {
                            self?.app.open(finalURL, options: [:], completionHandler: { (_) in
                                completion?()
                            })
                        } else {
                            self?.app.openURL(finalURL)
                            completion?()
                        }
                    } else {
                        openInSafari()
                    }
                default:
                    break
                }
            } else {
                openInSafari()
            }
        }
    }
}

public struct Browser: Equatable {
    var scheme: URL? = nil
    let app = UIApplication.shared
    let name: String
    
    func isInstalled() -> Bool {
        
        guard let scheme = scheme else { return true }
        
        return app.canOpenURL(scheme)
    }
}
