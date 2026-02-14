//
//  FirebaseBootstrap.swift
//  Overlap
//
//  Configures Firebase only when the SDK is linked and a plist is present.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrap {
    private static var didConfigure = false

    static func configureIfAvailable() {
        #if canImport(FirebaseCore)
        guard !didConfigure else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        FirebaseApp.configure()
        didConfigure = true
        #endif
    }
}
