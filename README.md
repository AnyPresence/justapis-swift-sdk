# JustAPIs Swift SDK

## Overview

Lightweight Swift SDK to connect to a JustAPIs gateway through an iOS client.

## Dependencies
Managed using Cocoapods.

Framework: CocoaMQTT [MSWeakTimer, CocoaAsyncSocket]
Unit Tests: OHHTTPStub, HKLSocketStubServer

### Development/Production
This SDK is a Swift dynamic framework, and is written in Swift 3 and needs Xcode 8.

Some features used in the SDK (i.e. tuples, structs) are not currently available in Objective-C code. If you want to use this framework in an Objective-C app, you'll need to marshall these features through Swift code of your own. 

### Unit Testing
If you want to perform unit tests on this framework, it requires [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs/) & [HKLSocketStubServer](https://github.com/hirohitokato/HKLSocketStubServer) in order to mock requests. These already included as a pod of Unit Test Target, so you can run:

```pod install``` 

to make them available.

## Introduction

The core features of the SDK are exposed through three simple protocols: `Gateway`, `Request`, and `Response`. 

These basic protocols are defined in `CoreTypes.swift`

A `Gateway` represents your connection to a single JustAPIs server. You can send `Request`s to this gateway, and you'll receive a `Response` through a simple callback closure.

The SDK includes two implementations of `Gateway`:

### CompositedGateway
The composited gateway is built from a few configurable and replacable components.

* A `NetworkAdapter` that accepts a `Request` and sends it out over the network before returning a `Response` or an error. The default NetworkAdapter is `FoundationNetworkAdapter`, which uses NSURLSession. 

If you prefer to use a different communications technique (AFNetworking, Alamofire, background sessions, caching, etc) you can write a simple NetworkAdapter and plug it into CompositedGateway's constructor.

* An optional `RequestPreparer`. A RequestPreparer can modify requests at the gateway level. You might use one to insert a token on certain requests, apply default headers, remap URL's, or serialize body data into a standard format like JSON or form-data.

Two sample `RequestPreparer`s are included in the SDK. `DefaultFieldsRequestPreparer` can apply missing query parameters or header fields to all requests. `RequestPreparerClosureAdapter` allows you to provide a simple closure that does whatever you'd like.

* An optional `ResponseProcessor`. A `ResponseProcessor` can modify a response at the gateway level, before the original response callback is invoked. This provides an opportunity to do logging, handle errors, or parse common response formats like JSON or XML.

Two sample `ResponseProcessor`s are included in the SDK. `JsonResponseProcessor` deserializes the body of all responses using NSJSONSerialization. `ResponsePreparerClosureAdapter` allows you to provide a simple closure that does whatever you'd like.

* An `CacheProvider` that can cache responses and return them on later requests without making another network request. The default CacheProvider is an `InMemoryCacheProvider` that stores responses in-memory using Foundation's NSCache.

If you'd like more persistent or sophisticated caching, you can implement your own CacheProvider and pass it to the CompositeGateway on initialization. 

* An optional `SSLCertificate` to be used for certificate pinning. If you provide the public key or certificate associated with your server, its identity will be validated before any requests are sent.

* An optional `DefaultRequestPropertySet` that allows you to customize the default options for GET, POST, PUT, and DELETE requests submitted to the Gateway. These defaults are used when using the Gateway's convenience methods to submit a request. If you don't provide your own defaults, the Gateway will use `GatewayDefaultRequestProperties` as found in `Request.swift` 

* An optional `PushNotificationsProvider` that allows you interact with Push Notification Related End Points. If you don't provide your own, the Gateway will use `DefaultPushNotificationsProvider` as found in `PushNotifications.swift` 

* An optional `MQTTProvider` that allows you to interact with MQTT Server/Broker. If you don't provide your own, the Gateway will use `DefaultMQTTProvider` as found in `MQTT.swift` SSL is not supported currently.

### JsonGateway

`JsonGateway` is Gateway implementation provided for convenience. It's just a `CompositedGateway` that includes a `JsonResponseProcessor` by default.

## Setup

### Framework Integration

#### Cocoapods

The preferred way to include the SDK in your project is by using [Cocoapods](https://cocoapods.org). 

For the bleeding edge version of this SDK, you can add the following directive to the target definition in your Podfile:

`pod 'JustApisSwiftSDK', :git => 'https://github.com/AnyPresence/justapis-swift-sdk.git'`

Since this SDK is a dynamic framework that uses Swift 3.0, you'll also need to make sure that your Podfile targets iOS 8.0 or higher and is set to use dynamic frameworks(See 'examples' below). The repository also includes a basic Demo project that uses Cocoapods. You're encoraged to look at it and its Podfile for a better understanding.

###### For version `0.2.0+`: 

This version requires modified variants of some pods. So you also need to include alternate `podspec` source at the top of your pod file.

```ruby
source 'git@github.com:ebricks/NanoscalePodspecs.git'
source 'git@github.com:CocoaPods/Specs.git'

platform :ios 8.0
use_frameworks!
```

###### For Earlier Versions:

```ruby
platform :ios 8.0
use_frameworks!
```

#### Carthage

Coming soon.

#### Manual

Coming soon.

### Module Import

Once the framework is included in your project, simply import the module into your own code using:

`import JustApisSwiftSDK`

## Usage

### Making requests

To make requests to your JustAPIs server, you'll just need to create a `Gateway` and submit a `Request`. 

A simple example is shown here: 

```swift

var gateway = CompositedGateway(baseUrl: NSURL(string:"http://my-justapi-server.local:5000/"))

gateway.get("/foo", params:["id":123], callback:
{ (result:RequestResult) in

if let error = result.error
{
print("Received an error: \(error)")
return
}
guard let response = result.response else
{
print("Received no response!")
return
}

print("Received a response with HTTP status code: \(response.statusCode)")
})
```

In this example, you can see us use the `get` conveneince method on our gateway. 

This method prepares and submits a GET request using as few parameters as we likely need. There are a number of these convenience methods available for each of the common HTTP methods (GET, POST, PUT, DELETE). The full list of these convenience methods are available in `Gateway.swift`

You may also prepare your own requests from scratch using any object that conforms to the `RequestProperties` protocol. `MutableRequestProperties` is provided for your convenience. Instead of calling one of the convenience methods, simply pass your request properties and the callback to the `submitRequest` method.

### Request Queue

Each instance of Gateway throttles requests so that no more than `maxActiveRequests` run at any time (default=2). If you submit requests faster than they can be processed, the pending requests can be accessed through the `pendingRequests` property.

You may pause and resume the request queue at any time. When paused, the Gateway will not start any new requests that have been queued. You may want to pause the queue when you go offline and resume it when connectivity is restored.

Requests are immutable and **cannot** be modified once they've been submitted to the Gateway. However, you can cancel requests that are still pending by calling `cancelRequest(...)`

### Certificate Pinning

The CompositedGateway supports certificate pinning. This allows you to require that the remote server publishes an expected public key, confirming its identity.

To utilize certificate pinning, simply create an `SSLCertificate` with the expected public key contents and supply it as the `sslCertificate` argument when initializing the CompositedGateway:

```swift
var certificate = SSLCertificate(path:NSBundle.mainBundle().pathForResource("server-public-key", ofType:"pem")!)!

var gateway = CompositedGateway(baseUrl: NSURL(string:"http://my-justapi-server.local:5000/"), sslCertificate:certificate)
```


### Automatic Content-Type Parsing

The CompositedGateway supports automatic parsing based on Content-Type. By calling `setParser(...)`. You may register a `ResponseProcessor` to run whenever a certain Content-Type is encountered on the gateway. The `JsonCompositedGateway` uses this tecnique to automatically parse JSON responses when the Content-Type is `application/json`

You may assign as many Content-Type parsers as you'd like.

You may disable automatic Content-Type parsing for any request by setting the `applyContentTypeParsing` Request property to false.

You may force a response to be interpreted with a certain Content-Type by setting the `contentTypeProperty` Request property to a non-nil value. This Content-Type will be used in place of any returned in the response headers. 

### Response Caching

The CompositedGateway supports caching of responses. You may control cache behavior using Request properties.

You make sure a fresh network request is performed by setting `allowCachedResponse` to false.

You may disable the caching of a response by setting `cacheResponseWithExpiration` to 0. Setting it to a higher value suggests the number of seconds for which a cached response will be preserved.

You may provide a custom cache identifier for a request by setting the `customCacheIdentifier` property. By default, only the method, path, and query parameters are used to distinguish requests from one another. If your headers or body are relevant to cached responses, you'll want to set a customCacheIdentifer that appropriately captures this information.  An example might be if you send search parameters using the BODY of a GET or POST request and want to cache the responses.

### Push Notification Endpoints

The CompositedGateway exposes a method group named `pushNotifications` that allows you to register (`subscribe`) your device for push notifications, unsubscribe it (`unsubcribe`), as well as publish messages (`publish`) to specific channels.

For each method, you'll need the `endpointCodename` expected by the Gateway. 

### MQTT Method Group

The CompositedGateway exposes a method group named `mqtt` that allows you to interact with Nanoscale Server(MQTT Broker/Server) that has MQTT configured.

### Receiving JSON Responses

If your JustAPI endpoints provide their responses in JSON, you can use the `JsonGateway` or set a `JsonResponseProcessor` as a `CompositedGateway` content-type parser.

```swift
var gateway = JsonGateway(baseUrl: NSURL(string:"http://my-justapi-server.local:5000/"))

gateway.get("/foo", params:["id":123], callback:
{ (result:RequestResult) in

if let error = result.error
{
print("Received an error: \(error)")
return
}
guard let response = result.response else
{
print("Received no response!")
return
}
guard let jsonData = response.parsedBody else
{
print:("No parsed body data found!")
return
}
print("Received a response with JSON content: \(jsonBody)")
})

```

### Request Preparers

RequestPreparers allow you to modify Requests after they've been submitted to your Gateway instance, but before they're added to the Request Queue.

Common uses would be to add additional headers to the request, build and add an authentication token based on query parameters, or encode body data using a specific format.

### Response Processors

ResponseProcessors are extremely flexible and can modify, observe, or reject a response before it makes its way to the callback. 

All response processors expose an asynchronous `processResponse(...)` method that receives the current (immutable) response and eventually calls a ResponseProcessorCallback with a response and/or error. `processResponse` is always invoked on the main thread.

The `ResponseProcessorClosureAdapter` is a convenience wrapper to use when you have a fast and simple action you want to perform on responses (i.e. signalling an error if an expected header or response field is invalid). It wraps a simple, synchronous closure.

The `CompoundResponseProcessor` lets you easily chain a series of response processors together so that they run sequentially. If any response processor signals an error, the remainder will be skipped.

## Development

The SDK is designed to be lightweight and modular so that you can enhance and modify its functionality without modifying its code directly. 

However, if you would like to make changes to the SDK, you are welcome to  clone or fork this repository. You will also need to modify your apps to make sure they integrate your code rather than what's hosted in this repository.

See **Dependencies** for more information.

## Changes in Version `0.2.0` from `0.1.0`

- Added Support for Swift 3
- Refactored builder methods names from `propertName(value: PropertyType)` to `copyWith(propertyName value: PropertyType)`
- Support for MQTT(without SSL)
