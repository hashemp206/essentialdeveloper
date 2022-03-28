//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Hashem Aboonajmi on 3/14/20.
//  Copyright © 2020 Hashem Aboonajmi. All rights reserved.
//

import Foundation

final class FeedItemMapper {
    
    private struct Root: Decodable {
        private let items: [RemoteFeedItem]
        
        private struct RemoteFeedItem: Decodable {
           
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
       }
        
        var images: [FeedImage] {
            return items.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        }
    }
    
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedImage] {
        guard response.isHTTPURLResponseOK, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.images
    }
}
