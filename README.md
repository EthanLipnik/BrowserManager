# BrowserManager

### Easy browser managment in Swift.
*Supports iOS 9 and above.*

### Try it in [Neptune](https://www.twitter.com/NeptuneApp_ "Neptune")

## How to use
### The Default Browser
*Automatically defaults to in-app safari if not modified.*
```swift
BrowserManager.shared.defaultBrowser
```
**How to change the default browser**
```swift
let safari = BrowserManager.shared.supportedBrowsers.safari
BrowserManager.shared.defaultBrowser = safari
```

### Get installed browsers
```swift
BrowserManager.shared.installedBrowsers
```

### Open URL with default browser
```swift
BrowserManager.shared.open(url: {YOUR URL}, presentingController: self)
```
