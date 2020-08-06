//
//  LoadFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Hashem Aboonajmi on 8/4/20.
//  Copyright © 2020 Hashem Aboonajmi. All rights reserved.
//

import XCTest
import EssentialFeed

class LoadFromCacheUseCaseTest: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCachRetreival() {
        let (sut, store) = makeSut()
        sut.load{_ in}
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSut()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (sut, store) = makeSut()
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    func test_load_deliversCachedImagesLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        
        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
        })
    }

    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
        })
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSut()
        
        sut.load{ _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSut()
        
        sut.load{ _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
            
        sut.load{ _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
            
        sut.load{ _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let (sut, store) = makeSut(currentDate: {fixedCurrentDate})
        let feed = uniqueImageFeed()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
            
        sut.load{ _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        sut = nil
        
        store.completeRetrievalWithEmptyCache()
        XCTAssertTrue(receivedResults.isEmpty)
    }
    // MARK: - Helpers
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(recievedError), .failure(expectedError)):
                XCTAssertEqual(recievedError as NSError, expectedError as NSError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init , file: StaticString = #file, line: Int = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
    
}
