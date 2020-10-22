//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Rakesh Ramamurthy on 22/10/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataFeedStore: FeedStore {
    
    private let persistentContainer: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle = .main) throws {
        persistentContainer = try NSPersistentContainer.load(modelName: "CoreDataFeedStore", url: storeURL, in: bundle)
        context = persistentContainer.newBackgroundContext()
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        context.perform {
            do {
                let cache = ManagedCache(context: self.context)
                cache.timestamp = timestamp

                let images: [ManagedFeedImage] = feed.map {
                    let imageFeed = ManagedFeedImage(context: self.context)
                    imageFeed.id = $0.id
                    imageFeed.imageDescription = $0.description
                    imageFeed.url = $0.url
                    imageFeed.location = $0.location
                    return imageFeed
                }

                cache.feed = NSOrderedSet(array: images)

                try self.context.save()
                completion(nil)

            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {

        context.perform {
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false

                if let cache = try self.context.fetch(request).first {
                    completion(.found(
                        feed: cache.feed
                        .compactMap {($0 as? ManagedFeedImage)}
                        .map {LocalFeedImage(id: $0.id, description: $0.imageDescription, location: $0.location, url: $0.url)},
                        timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: Core Data Models

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

private extension NSPersistentContainer {

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
