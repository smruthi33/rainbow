//
//  ScoreRoutes.swift
//  Application
//
//  Created by David Okun IBM on 5/1/18.
//

import Foundation
import CouchDB
import LoggerAPI
import KituraContracts

private var client: CouchDBClient?

func initializeScoreRoutes(app: App) {
    client = app.services.couchDBService
    
    app.router.get("/entries", handler: getAllEntries)
    app.router.get("/entries", handler: getOneEntry)
    app.router.post("/entries", handler: addNewEntry)
    app.router.put("/entries", handler: updateEntry)
}

func getAllEntries(completion: @escaping ([ScoreEntry]?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.getAll(from: client) { entries, error in
        return completion(entries, error as? RequestError)
    }
}

func getOneEntry(anonymousIdentifier: String, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.get(from: client, with: anonymousIdentifier) { entry, error in
        return completion(entry, error as? RequestError)
    }
}

func addNewEntry(newEntry: ScoreEntry, completion: @escaping(ScoreEntry?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.save(entry: newEntry, to: client) { entryID, error in
        guard let entryID = entryID else {
            return completion(nil, .noContent)
        }
        ScoreEntry.Persistence.get(from: client, with: entryID, completion: { entry, error in
            return completion(entry, error as? RequestError)
        })
    }
}

func updateEntry(anonymousIdentifier: String,newEntry: ScoreEntry, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    Log.info("Updating entry document")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.update(id: anonymousIdentifier, entry: newEntry, to: client) { revID, error in
        guard let revID = revID else {
            return completion(nil, .noContent)
        }
        Log.info("Document updated with new revision: ", functionName: revID)
        ScoreEntry.Persistence.get(from: client, with: anonymousIdentifier, completion: { entry, error in
            return completion(entry, error as? RequestError)
        })
    }
}
