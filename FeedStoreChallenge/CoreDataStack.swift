//
//  CoreDataStack.swift
//  FeedStoreChallenge
//
//  Created by Rakesh Ramamurthy on 22/10/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

internal extension NSPersistentContainer {

    enum LoadError: Swift.Error {
        case didNotFindModel
        case didFailToLoadPersistentStores(Swift.Error)
    }

    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadError.didNotFindModel
        }

        var loadError: Swift.Error?

        let persistentDescription = NSPersistentStoreDescription(url: url)

        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [persistentDescription]

        container.loadPersistentStores { (_, error) in
            loadError = error
        }

        try loadError.map { throw LoadError.didFailToLoadPersistentStores($0) }

        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle.url(forResource: name, withExtension: "momd").flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
