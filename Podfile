source 'git@github.com:ebricks/NanoscalePodspecs.git'
source 'git@github.com:CocoaPods/Specs.git'

# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

target 'JustApisSwiftSDK' do
    # Uncomment the next line to define a global platform for your project
    platform :ios, '8.0'

    # Pods for JustApisSwiftSDK
    pod 'CocoaMQTT', '~> 1.0.11'
    
    target 'JustApisSwiftSDKTests' do
        inherit! :search_paths
        # Pods for testing
        pod 'OHHTTPStubs', '~> 5.2.3' # Default subspecs, including support for NSURLSession & JSON etc
        pod 'OHHTTPStubs/Swift', '~> 5.2.3' # Adds the Swiftier API wrapper too
        pod 'HKLSocketStubServer', '~> 0.0.1'
    end
end

target 'JustApisSwiftSDK-OSX' do
    # Uncomment the next line to define a global platform for your project
    platform :osx, '10.9'

    # Pods for JustApisSwiftSDK-OSX
    pod 'CocoaMQTT', '~> 1.0.11'
end

target 'JustApisSwiftSDK-tvOS' do
    # Uncomment the next line to define a global platform for your project
    platform :tvos, '9.0'
    
    # Pods for JustApisSwiftSDK-OSX
    pod 'CocoaMQTT', '~> 1.0.11'
end

target 'JustApisSwiftSDK-watchOS' do
  
    # Pods for JustApisSwiftSDK-watchOS
  
end
