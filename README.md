# Oblivious HTTP client for Swift

<a href="LICENSE.txt">
    <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
</a>
<a href="https://github.com/apple/swift-package-manager" alt="RxSwift on Swift Package Manager" title="RxSwift on Swift Package Manager">
    <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" />
</a>

## Description
This project provides a way to use Oblivious HTTP in iOS client applications via the provided `URLProtocol`. Implementation corresponds to version 8 of [IETF Oblivious HTTP draft](https://datatracker.ietf.org/doc/draft-ietf-ohai-ohttp/), and is confirmed to be working with the [relay](https://github.com/cloudflare/privacy-gateway-relay) and the [gateway](https://github.com/cloudflare/privacy-gateway-server-go) implementations from Cloudflare.

## Installation


#### Swift Package Manager


You can use [The Swift Package Manager](https://swift.org/package-manager) to install `OHTTPClientSwift` by adding the dependency to your `Package.swift` file:


```swift
// swift-tools-version:4.0
import PackageDescription


let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "git@github.com:flohealth/ohttp-client-swift.git", from: "0.1.0"),
    ]
)
```


## Usage

1. Import `OHTTPSwift`
2. Provide your OHTTP configuration by calling `OHTTPSwift.configure`. If not configured, OHTTP will be disabled and throw an assertion in debug if any requests pass. Configuration consists of:
    1. Custom value of the `User-Agent` header for OHTTP requests. Default iOS implementation may give too much information about the client, increasing the chances of identifying a user. Hence, the recommendation is to use something more opaque, such as a plain application name.
    2. URL to gateway endpoint with OHTTP keys configuration
    3. URL to OHTTP relay
3. Insert `OHTTPSwift.urlProtocol` into your `URLSession` configuration. You can do this at any point in time, even after steps 4 and 5.
4. Set `OHTTPSwift.isEnabled` to `true` (it is `false` by default) when you are ready to turn on OHTTP for all `URLSession`s configured in step 3. 
5. At last, the recommendation is to call `OHTTPSwift.fetchOHTTPKeyConfig()` at certain times (for example, once at the app launch) for all app users - even if some of them have OHTTP turned off. The same behavior for all users makes it harder to identify which ones use OHTTP and which don't. 


```swift
// Import the Oblivious HTTP library
import OHTTPSwift

// Configure it
OHTTPSwift.configure(
 userAgent: "The Application (iOS)",
 configURL: URL(string: "https://www.theapp-gateway.com/ohttp-keys")!,
 relayURL: URL(string: "https://www.theapp.relay.cloudflare.com/relay")!
)

// Configure URLSession
let defaultConfig = URLSessionConfiguration.default
if var currentProtocols = defaultConfig.protocolClasses {
 currentProtocols.insert(OHTTPSwift.urlProtocol, at: 0)
 defaultConfig.protocolClasses = currentProtocols
} else {
 defaultConfig.protocolClasses = [OHTTPSwift.urlProtocol]
}
let urlSession = URLSession(configuration: defaultConfig, delegate: nil, delegateQueue: nil)

// Turn on OHTTP
OHTTPSwift.isEnabled = true

// Initiate config fetch
OHTTPSwift.fetchOHTTPKeyConfig()
```

## How this library manages OHTTP keys configuration

This library has a built-in key caching and invalidation mechanism. It relies on URLSession default caching logic and thus requires standard HTTP caching headers (like `'Cache-Control'`) to be in place in the key config response. Nothing will be cached without them, and keys will be fetched for each request.
If you wish to have custom keys fetching and caching logic, use an alternative version of `OHTTPSwift.configure`: the one that takes `OHTTPKeyConfigClient` parameter instead of the plain url - you can pass your own implementation this way. This interface has a single function, `fetchKeyConfiguration`, with a `Bool` parameter indicating whether the cache needs to be invalidated.

If the relay answers with HTTP code `401` to any request, this library will treat it as 'key config is invalid' and will try to invalidate current key cache and fetch new key from the remote, then automatically retry the request.

## Limitations

OHTTP cannot be enabled globally for the whole app - each `URLSession` should be configured explicitly to use the provided `URLProtocol`. It means that `URLSession`s you don't control, such as from other 3rd-party libraries, will still work without OHTTP. Also, there is currently no way to set up `WKWebView`s to work with `URLProtocol`, so all traffic from them will also be unaffected.

As OHTTP `URLProtocol` significantly changes the client-server interaction, we can't prove that every feature of the HTTP protocol will correctly work with OHTTP enabled.
Please perform proper testing of your use cases before use.

All limitations of [bhttp-swift](https://github.com/flohealth/bhttp-swift) are also applied.

## License

Released under [**MIT License**](LICENSE.txt).