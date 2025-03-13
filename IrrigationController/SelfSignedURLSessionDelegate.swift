//
//  SelfSignedURLSessionDelegate.swift
//  IrrigationController
//
//  Created by Allen Pomeroy on 2/27/25.
//


import Foundation

class SelfSignedURLSessionDelegate: NSObject, URLSessionDelegate {
    // Accept self-signed certificates (testing only)
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Check if the challenge is for server trust.
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
