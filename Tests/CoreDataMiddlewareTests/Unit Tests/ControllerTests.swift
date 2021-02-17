//
//  File.swift
//  
//
//  Created by Bo Weber on 11.02.21.
//

import XCTest
import Combine
import CoreData
@testable import CoreDataMiddleware

class ControllerTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    var sut: NSPersistentContainer!
    
    var container: CoreDataContainer {
        CoreDataContainer(state: .loaded(sut))
    }
    
    override func setUp() {
        self.cancellables = []
        self.sut = NSPersistentContainer.testContainer
        sut.loadPersistentStores { _, error in
            _ = error.map { fatalError($0.localizedDescription) }
        }
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
    }
    
    func entity(with attribute: String) throws -> SongArtist? {
        let entities = try sut.viewContext.fetch(SongArtistRequest.withName(attribute).fetchRequest)
        if entities.count > 1 {
            XCTFail(entities.debugDescription)
        }
        return entities.first.map { SongArtist(artistName: $0.artist, managedObjectID: $0.objectID) }
    }
    
    func testSavingElement() throws {
        let attribute = "some element"
        let expectSave = expectation(description: "Did save element")
        XCTAssertNil(try entity(with: attribute))
        
        CoreDataController<SongArtistRequest>(container)
            .savePublisher(for: SongArtist(artistName: attribute))
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: {
                expectSave.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectSave], timeout: 3)
        XCTAssertNotNil(try entity(with: attribute))
    }
    
    func testUpdatingElement() throws {
        let attribute = UUID().uuidString
        _ = sut.viewContext.makeManagedObject(basedOn: SongArtist(artistName: attribute))
        try sut.viewContext.save()
        sut.viewContext.reset()
        var savedEntity = try XCTUnwrap(try entity(with: attribute))
        let newAttribute = UUID().uuidString
        XCTAssertNotEqual(attribute, newAttribute)
        savedEntity.artistName = newAttribute
        let expectSave = expectation(description: "Did save element")
        
        CoreDataController<SongArtistRequest>(container)
            .savePublisher(for: savedEntity)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: {
                expectSave.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectSave], timeout: 3)
        XCTAssertNotNil(try entity(with: newAttribute))
        XCTAssertNil(try entity(with: attribute))
    }

    func testDeletingElement() throws {
        let attribute = "delete element"
        _ = sut.viewContext.makeManagedObject(basedOn: SongArtist(artistName: attribute))
        try sut.viewContext.save()
        sut.viewContext.reset()
        let savedEntity = try XCTUnwrap(try entity(with: attribute))
        XCTAssertNotNil(savedEntity.managedObjectID)
        let expectDeletion = expectation(description: "Deleted")

        CoreDataController<SongArtistRequest>(container)
            .deletePublisher(for: savedEntity)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: {
                expectDeletion.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectDeletion], timeout: 3)
    
        XCTAssertNil(try entity(with: attribute))
    }
}
