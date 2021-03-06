//
//  SSLCertificate.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/6/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

///
/// An SSL Certificate to be used for certificate pinning
public struct SSLCertificate
{
    /// The decoded and reasonably verified certificate data
    public let data:NSData
    
    /// Returns a new SSLCertificate using data at the specified path or nil
    public init?(path:String)
    {
        guard let data = NSData(contentsOfFile: path) else
        {
            // No data could be loaded at the specified path
            return nil
        }
        self.init(data:data)
    }
    
    /// Returns a new SSLCertificate if the data is a DER-formatted or PEM-formatted cert
    public init?(data:NSData)
    {
        guard let certificateData = SSLCertificate.extractCertificateData(data) else
        {
            // The certificate data was not valid
            return nil
        }
        self.data = certificateData
    }
    
    private static func extractCertificateData(data:NSData) -> NSData?
    {
        // 1 try to parse the certificate as a valid DER-formatted cert
        if let _ = SecCertificateCreateWithData(nil, data)
        {
            return data
        }
        
        // 2 It wasn't a DER-formatted cert. See if it's PEM-formatted and pull out the DER data

        let pemPrefix = "-----BEGIN CERTIFICATE-----"
        let pemSuffix = "-----END CERTIFICATE-----"

        // Interpret the data as a String and trim off any unwanted padding and check for prefix+suffix
        guard let
            certificateString = String(data: data, encoding: NSUTF8StringEncoding)?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            where
            certificateString.hasPrefix(pemPrefix) && certificateString.hasSuffix(pemSuffix)
            else
        {
            // It doesn't look like a PEM file
            return nil
        }

        // Extract any content between the prefix and suffix
        let potentialDERContent = certificateString.stringByReplacingOccurrencesOfString(pemPrefix, withString: "").stringByReplacingOccurrencesOfString(pemSuffix, withString: "")
        
        // Decode the base64 data and try to parse it as a certificate
        guard let
            data = NSData(base64EncodedString: potentialDERContent, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
            where
            nil != SecCertificateCreateWithData(nil, data)
            else
        {
            // The data between the PEM Prefix and Suffix still couldn't be decoded as a valid certicate
            return nil
        }
        
        return data
    }
}