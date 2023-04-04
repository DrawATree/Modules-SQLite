require 'sqlite3'
module Bd   

    private def db_open()
        db = SQLite3::Database.open "./libraries/bd/database.db"
        db.results_as_hash = true
        return db
    end

    private def db_send(db, results)
        db.close
        return results.to_json
    end

    def select(restOfQuery)
        db = db_open
        query = "SELECT #{restOfQuery}"
        results = db.execute query
        return db_send(db, results)
    end
    
    def insert(restOfQuery)
        db =  db_open
        query = "INSERT INTO #{restOfQuery}"
        result = db.execute query
        return db_send(db, result)
    end

    def update(restOfQuery)
        db =  db_open
        query = "UPDATE #{restOfQuery}"
        result = db.execute query
        return db_send(db, result)
    end

    def delete(restOfQuery)
        db = db_open
        query = "DELETE #{restOfQuery}"
        result = db.execute query
        return db_send(db, result)
    end

end