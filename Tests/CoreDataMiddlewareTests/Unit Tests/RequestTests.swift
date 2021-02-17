//
//  File.swift
//  
//
//  Created by Bo Weber on 12.02.21.
//

import Foundation
import XCTest
import CoreData
import Combine
@testable import CoreDataMiddleware

class RequestTests: XCTestCase {
    var sut: NSPersistentContainer!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        let container = NSPersistentContainer.testContainer!
        container.loadPersistentStores { _, error in
            _ = error.map { fatalError($0.localizedDescription) }
        }
        self.sut = container
        self.cancellables = []
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }

    func insertEntities(count: Int) {
        for index in 0..<count {
            _ = sut
                .viewContext
                .makeManagedObject(basedOn: SongArtist(artistName: index.description))
        }
    }
    
    func deleteEntities(withAttributes attributes: Int...) throws {
        let fetchRequest: NSFetchRequest<ManagedSong> = ManagedSong.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K IN %@", "artist", attributes.map(\.description))
        let results = try sut.viewContext.fetch(fetchRequest)
        for entity in results {
            sut.viewContext.delete(entity)
        }
    }
    
    func testSimpleRequest() throws {
        insertEntities(count: 6)
        
        let firstResult = [0, 1, 2, 3, 4, 5].map { SongArtist(artistName: $0.description) }
        let secondResult = [3, 4, 5].map { SongArtist(artistName: $0.description) }
        var secondResultReceived = false
        let thirdResult = [3, 4, 5, 6].map { SongArtist(artistName: $0.description) }
        
        let expectFirstResult = expectation(description: "First result")
        let expectSecondResult = expectation(description: "Second result")
        let expectThirdResult = expectation(description: "Third result")
        
        sut
            .viewContext
            .request(SongArtistRequest.all)
            .sink { completion in
            switch completion {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { result in
            switch result {
            case .difference(let difference):
                guard let difference = difference else {
                    XCTFail()
                    return
                }
                if !secondResultReceived {
                    XCTAssertEqual(
                        firstResult.applying(difference),
                        secondResult
                    )
                    expectSecondResult.fulfill()
                    secondResultReceived = true
                } else {
                    XCTAssertEqual(
                        secondResult.applying(difference),
                        thirdResult
                    )
                    expectThirdResult.fulfill()
                }
            case .elements(let elements):
                XCTAssertEqual(elements, firstResult)
                expectFirstResult.fulfill()
            }
        }
        .store(in: &cancellables)
        
        try deleteEntities(withAttributes: 0, 1, 2)
        wait(for: [expectFirstResult, expectSecondResult], timeout: 4, enforceOrder: true)
        _ = sut.viewContext.makeManagedObject(basedOn: SongArtist(artistName: 6.description))
        wait(for: [expectThirdResult], timeout: 4, enforceOrder: true)
    }
}
