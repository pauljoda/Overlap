//
//  Overlap+Database.swift
//  Overlap
//
//  Created by Paul Davis on 8/31/25.
//

import SharingGRDB

extension Overlap {

    /// Update or insert into the db
    func updateOrInsert(database: DatabaseWriter) -> Bool {
        var errors: ()? = withErrorReporting {
            // See if it exists, if so update
            try database.write { db in
                // See if we already have one
                var existingOverlap = try Overlap.where { $0.id == self.id }
                    .fetchOne(db)
                
                // If so, update otherwise insert
                if existingOverlap != nil {
                    _ = saveToDatabase(database: database)
                } else {
                    _ = insertToDatabase(database: database)
                }
            }

        }

        return errors == nil
    }

    /// Save the Overlap instance to the database.
    func saveToDatabase(database: DatabaseWriter) -> Bool {

        // Attempt to save
        var errors: ()? = withErrorReporting {
            try database.write { db in
                try Overlap.update(self).execute(db)
            }
        }

        return errors == nil
    }

    /// Insert into the database
    func insertToDatabase(database: DatabaseWriter) -> Bool {

        // Attempt to insert
        var errors: ()? = withErrorReporting {
            try database.write { db in
                try Overlap.insert { self }.execute(db)
            }
        }

        return errors == nil
    }
}
