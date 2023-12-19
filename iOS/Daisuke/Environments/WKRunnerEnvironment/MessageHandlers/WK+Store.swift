//
//  WK+Store.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-08-03.
//

import Foundation
import WebKit

extension WKHandler {
    class StoreHandler: NSObject, WKScriptMessageHandlerWithReply {
        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
            let task = Task { @MainActor () -> String? in
                guard let webview = message.webView else {
                    return nil
                }
                do {
                    let value = try await webview.evaluateJavaScript("IDENTIFIER", contentWorld: .defaultClient)
                    return value as? String
                } catch {
                    Logger.shared.error(error, "WKStoreHandler")
                }
                return nil
            }
            guard let id = await task.value else {
                return (nil, "Unable to find Runner Instance ID")
            }

            let body = await MainActor.run {
                message.body
            }
            // Check JSON Validity
            let isValidJSON = JSONSerialization.isValidJSONObject(body)
            guard isValidJSON else {
                return (nil, DSK.Errors.InvalidJSONObject.localizedDescription)
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: body)
                let message = try JSONDecoder().decode(Message.self, from: data)
                let value = try await handle(message: message, id: id)
                return (value, nil)
            } catch {
                return (nil, "\(error)")
            }
        }
    }
}

private typealias H = WKHandler.StoreHandler

extension H {
    struct Message: Decodable {
        var store: Store
        var action: Action
        var key: String
        var value: String?

        enum Action: String, Decodable {
            case get, set, remove
        }

        enum Store: String, Decodable {
            case os, ss
        }
    }
}

extension H {
    func handle(message: Message, id: String) async throws -> String? {
        switch message.store {
        case .os: // ObjectStore
            switch message.action {
            case .get:
                return CDKVPair.getValue(runner: id, key: message.key)
            case .set:
                guard let value = message.value else {
                    throw DSK.Errors.ValueStoreErrorKeyValuePairInvalid
                }
                CDKVPair.setPair(runner: id, key: message.key, value: value)
            case .remove:
                CDKVPair.removePair(runner: id, key: message.key)
            }

        // TODO: Potentially move this back to the keychain?
        case .ss: // SecureStore
            switch message.action {
            case .get:
                return CDKVPair.getValue(runner: id, key: message.key)
            case .set:
                guard let value = message.value else {
                    throw DSK.Errors.ValueStoreErrorKeyValuePairInvalid
                }
                CDKVPair.setPair(runner: id, key: message.key, value: value)
            case .remove:
                CDKVPair.removePair(runner: id, key: message.key)
            }
        }
        return nil
    }
}
