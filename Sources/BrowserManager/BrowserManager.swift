//
//  BrowserManager.swift
//
//  Created by Ethan Lipnik.
//

import Foundation

#if !os(macOS)
import UIKit
import SafariServices

open class BrowserManager {
    public static let shared = BrowserManager()
    
    public struct Browsers {
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
    
    open var supportedBrowsers = Browsers()
    
    open var installedBrowsers: [Browser] {
        get {
            return supportedBrowsers.array.filter({ $0.isInstalled() })
        }
    }
    open var defaultBrowser: Browser {
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
        
    
    private let app = UIApplication.shared

    private func encodeByAddingPercentEscapes(_ input: String) -> String {
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
            #if targetEnvironment(macCatalyst)
            openInSafari()
            #else
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
            #endif
        }
    }
}

public struct Browser: Equatable {
    public var scheme: URL? = nil
    public let app = UIApplication.shared
    public let name: String
    
    public func isInstalled() -> Bool {
        
        guard let scheme = scheme else { return true }
        
        return app.canOpenURL(scheme)
    }
}

#endif
