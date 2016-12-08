//
//  SSLCertificatePinningTests.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/6/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import XCTest
import JustApisSwiftSDK

// Adding this private extension for initing reasonably nice multi-line strings, below
private extension String {
    init(sep:String, _ lines:String...){
        self.init(sep:sep, lines)
    }
    
    init(sep:String, _ lines:[String]){
        self = lines.joined(separator: sep)
    }
    
    init(_ lines:String...){
        self.init(sep:"\n", lines)
    }
}

class SSLCertificatePinningTests: XCTestCase {
    
    
    private let validDerCertificate:Data = Data(base64Encoded: String(
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg46Pe"),
        options:NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
    private let validTrimmedPemCertificate:Data = String(
        "-----BEGIN CERTIFICATE-----",
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg46Pe",
        "-----END CERTIFICATE-----")
        .data(using: String.Encoding.utf8)!
    private let validPaddedPemCertificate:Data = String(
        "                                  ",
        "-----BEGIN CERTIFICATE-----",
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg46Pe",
        "-----END CERTIFICATE-----",
        "                 ",
        "    ",
        "")
        .data(using: String.Encoding.utf8)!
    private let invalidDerLikeCertificate:Data = Data(base64Encoded: String(
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg"),
        options:NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
    private let invalidUntrimmablePemLikeCertificate:Data = String(
        "  asa There are nontrimmable characters here.   ",
        "-----BEGIN CERTIFICATE-----",
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg46Pe",
        "-----END CERTIFICATE-----",
        "  and more nontrimmable characters here               ",
        "    ",
        "")
        .data(using: String.Encoding.utf8)!
    private let invalidBadDataPemLikeCertificate:Data = String(
        "  asa There are nontrimmable characters here.   ",
        "-----BEGIN CERTIFICATE-----",
        "MIIDgDCCAmgCCQC48nFC+7UzoTANBgkqhkiG9w0BAQUFADCBgTELMAkGA1UEBhMC",
        "VVMxCzAJBgNVBAgTAlZBMQ8wDQYDVQQHEwZSZXN0b24xFDASBgNVBAoTC0FueVBy",
        "ZXNlbmNlMRYwFAYDVQQDEw1sb2NhbGhvc3Quc3NsMSYwJAYJKoZIhvcNAQkBFhdz",
        "dXBwb3J0QGFueXByZXNlbmNlLmNvbTAeFw0xNDEwMTYxOTUyNThaFw0xNTEwMTYx",
        "OTUyNThaMIGBMQswCQYDVQQGEwJVUzELMAkGA1UECBMCVkExDzANBgNVBAcTBlJl",
        "c3RvbjEUMBIGA1UEChMLQW55UHJlc2VuY2UxFjAUBgNVBAMTDWxvY2FsaG9zdC5z",
        "c2wxJjAkBgkqhkiG9w0BCQEWF3N1cHBvcnRAYW55cHJlc2VuY2UuY29tMIIBIjAN",
        "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAodQdhI7efASNoyTkweqqqsPOlG94",
        "sMPH28I/adLpvMoh/wGAGi0Kr/MMZ2ae2EUYH0nBwulBL9/IvxFCErOJdAyc3arU",
        "+mjvTtF8/PqiORO2uloj9RXm1dh50YUPTK51xlH6cxqF1R2xSzTSG7zVhD4O/FvF",
        "3VcHsN7t09gjCgCCzqRe+ceklYE3ngAR/d60Vod3YQa8D6vyVH0B4BtsmiaguJ4L",
        "1ZNvSUTVcTYizoga6b70RKwpqbZ8i3tXmt8O+Kqve1Dx7gs4x984NwQCZz1yqHqQ",
        "vG+snZOGDKR4OgrAHALiN6Kj7f0wSjZIEEjelVKt8efD2/KQEdXahgQLZQIDAQAB",
        "MA0GCSqGSIb3DQEBBQUAA4IBAQAWlp1bn7bJMs8usV+r2MwQ5hjIhIZNQPOKd3jr",
        "48WJ19hqddaYZIawvE/Y8Mt0W3Ik/DPM/JJY3LUn3X1utDAcVudEV2po+Bzgqjyc",
        "bwMRDwH2a6pxp6G686UuKrJMVYAI/k8zAbfpLs/tYQtewER4cYSh1YVciFr0lT0E",
        "T2zGXDNYqBsGd4+awKr7JYSQHLmrJiUIfarXD3AT+HqZ6mcyKKGZRXy/tO4WSkqc",
        "6FAexKUfjDYxMfmZNRbnxy8GnKxEd9v3w8JMoiUYpYCT4zyQlksAcB34byrgwbKk",
        "r9peYjRswIMsCQRPLfo6F/2Ly00Iu2kWtnUNR/ZK+uFg",
        "-----END CERTIFICATE-----",
        "  and more nontrimmable characters here               ",
        "    ",
        "")
        .data(using: String.Encoding.utf8)!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidDerCertificate() {
        XCTAssertTrue(nil != SSLCertificate(data: self.validDerCertificate))
    }
    
    func testInvalidDerLikeCertificate() {
        XCTAssertTrue(nil == SSLCertificate(data: self.invalidDerLikeCertificate))
    }
    
    func testValidTrimmedPemCertificate() {
        XCTAssertTrue(nil != SSLCertificate(data: self.validTrimmedPemCertificate))
    }
    
    func testValidPaddedPemCertificate() {
        XCTAssertTrue(nil != SSLCertificate(data: self.validPaddedPemCertificate))
    }
    
    func testInvalidUntimmablePemLikeCertificate() {
        XCTAssertTrue(nil == SSLCertificate(data: self.invalidUntrimmablePemLikeCertificate))
    }
    
    func testInvalidBadDataPemLikeCertificate() {
        XCTAssertTrue(nil == SSLCertificate(data: self.invalidBadDataPemLikeCertificate))
    }
}
