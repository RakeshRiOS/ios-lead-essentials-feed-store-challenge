//
//  ManagedFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Rakesh Ramamurthy on 22/10/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
    @NSManaged internal var id: UUID
    @NSManaged internal var imageDescription: String?
    @NSManaged internal var location: String?
    @NSManaged internal var url: URL
    @NSManaged internal var cache: ManagedCache

    internal var local: LocalFeedImage {
        return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
    }

    internal static func images(from localFeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map { local in
            let image = ManagedFeedImage(context: context)
            image.id = local.id
            image.imageDescription = local.description
            image.location = local.location
            image.url = local.url
            return image
        })
    }
}
