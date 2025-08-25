//
//  DatabaseWriter.swift
//  Overlap
//
//  Created by Paul Davis on 8/23/25.
//

import OSLog
import SharingGRDB

private let logger = Logger(subsystem: "Overlap", category: "Database")

/// Provides a configured database writer based on the current app context.
func appDatabase() throws -> any DatabaseWriter {
    // Determine the current app context (live, test, or preview)
    @Dependency(\.context) var context
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    
    
    #if DEBUG
        configuration.prepareDatabase { db in
            db.trace(options: .profile) {
                if context == .preview {
                    print("\($0.expandedDescription)")
                } else {
                    logger.debug("\($0.expandedDescription)")
                }
            }
        }
    #endif
    
    // Build the file
    let database: any DatabaseWriter
    
    // On live, use a persistent file in the documents directory
    if context == .live {
        let path = URL.documentsDirectory.appending(component: "db.sqlite")
            .path()
        logger.info("open \(path)")
        database = try DatabasePool(path: path, configuration: configuration)
    } else if context == .test { // In testing env
        let path = URL.temporaryDirectory.appending(
            component: "\(UUID().uuidString)-db.sqlite"
        ).path()
        database = try DatabasePool(path: path, configuration: configuration)
    } else { // In preview env, use an in-memory database
        database = try DatabaseQueue(configuration: configuration)
    }
    
    // Setup Migrations
    var migrator = DatabaseMigrator()
    
    // Always rebuild in development and preview
    #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
    #endif
    
    // Setup Migrations
    migrator.registerMigration("Create tables") { db in
        try #sql("""
            CREATE TABLE "questionnaireTables" (
                "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                "title" TEXT NOT NULL DEFAULT '',
                "description" TEXT NOT NULL DEFAULT '',
                "instructions" TEXT NOT NULL DEFAULT '',
                "author" TEXT NOT NULL DEFAULT 'Anonymous',
                "creationDate" REAL NOT NULL DEFAULT (julianday('now')),
                "questions" TEXT NOT NULL DEFAULT '[]',
                "iconEmoji" TEXT NOT NULL DEFAULT '📝',
                "startColorRed" REAL NOT NULL DEFAULT 0.0,
                "startColorGreen" REAL NOT NULL DEFAULT 0.0,
                "startColorBlue" REAL NOT NULL DEFAULT 1.0,
                "startColorAlpha" REAL NOT NULL DEFAULT 1.0,
                "endColorRed" REAL NOT NULL DEFAULT 0.5,
                "endColorGreen" REAL NOT NULL DEFAULT 0.0,
                "endColorBlue" REAL NOT NULL DEFAULT 0.5,
                "endColorAlpha" REAL NOT NULL DEFAULT 1.0,
                "isFavorite" INTEGER NOT NULL DEFAULT 0
            )
        """)
        .execute(db)
    }
    try migrator.migrate(database)
    
    return database
}
