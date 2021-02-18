//
//  File.swift
//  
//
//  Created by Bo Weber on 25.01.21.
//

public enum PersistenceFetchResult<Element> {
    case elements([Element])
    case difference(CollectionDifference<Element>?)
}
