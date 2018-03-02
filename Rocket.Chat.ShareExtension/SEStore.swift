//
//  SEDatabase.swift
//  Rocket.Chat.ShareExtension
//
//  Created by Matheus Cardoso on 3/1/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import Foundation

private func getServers() -> [(name: String, host: String)] {
    return DatabaseManager.servers?.flatMap {
        guard
            let name = $0[ServerPersistKeys.serverName],
            let host = URL(string: $0[ServerPersistKeys.serverURL] ?? "")?.host
        else {
            return nil
        }

        return (name, host)
    } ?? []
}

protocol SEStoreSubscriber: class {
    func storeUpdated(_ store: SEStore)
}

class SEStore {
    var servers = getServers() {
        didSet {
            notifySubscribers()
        }
    }

    var selectedServerIndex: Int = 0 {
        didSet {
            notifySubscribers()
        }
    }

    private var subscribers = [SEStoreSubscriber]()

    func subscribe(_ subscriber: SEStoreSubscriber) {
        guard !subscribers.contains(where: { $0 === subscriber }) else {
            return
        }

        subscribers.append(subscriber)
        subscriber.storeUpdated(self)
    }

    func unsubscribe(_ subscriber: SEStoreSubscriber) {
        guard let index = subscribers.index(where: { $0 === subscriber }) else {
            return
        }

        subscribers.remove(at: index)
    }

    func notifySubscribers() {
        subscribers.forEach {
            $0.storeUpdated(self)
        }
    }
}

let store = SEStore()