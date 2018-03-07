//
//  SENavigationController.swift
//  Rocket.Chat.ShareExtension
//
//  Created by Matheus Cardoso on 3/2/18.
//  Copyright © 2018 Rocket.Chat. All rights reserved.
//

import UIKit
import MobileCoreServices

final class SENavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        initializeStore(store: store)

        guard
            let inputItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = inputItem.attachments?.first as? NSItemProvider
        else {
            return
        }

        itemProvider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { text, error in
            guard error == nil, let text = text as? String else { return }
            store.dispatch(.setComposeText(text))
        }

        itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { url, error in
            guard error == nil, let url = url as? URL else { return }
            store.dispatch(.setComposeText(url.absoluteString))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store.subscribe(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        fatalError("This cannot be called directly")
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        store.dispatch(.makeSceneTransition(.pop))
        return nil
    }
}

extension SENavigationController: SEStoreSubscriber {
    func stateUpdated(_ state: SEState) {
        switch state.navigation.sceneTransition {
        case .none:
            return
        case .pop:
            super.popViewController(animated: true)
        case .push(let scene):
            switch scene {
            case .rooms:
                super.pushViewController(SERoomsViewController.fromStoryboard(), animated: true)
            case .servers:
                super.pushViewController(SEServersViewController.fromStoryboard(), animated: true)
            case .compose:
                super.pushViewController(SEComposeViewController.fromStoryboard(), animated: true)
            }
        case .finish:
            extensionContext?.cancelRequest(withError: SEError.canceled)
        }

        store.dispatch(.makeSceneTransition(.none))
    }
}