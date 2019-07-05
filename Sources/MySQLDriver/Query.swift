//
//  Query.swift
//  mysql_driver
//
//  Created by Marius Corega on 24/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


import Foundation

public extension MySQL.Connection {

	enum QueryResultType {
        case success(MySQL.ResultSet)
        case error(Error)
    }
    
	class QueryResult {
        
        var rows : MySQL.ResultSet?
        var succClosure : ((_ rows:MySQL.ResultSet)->Void)? = nil
        var errorClosure : ((_ error:Error)->Void)? = nil
        
        init() {
        }
        
        init(r:MySQL.ResultSet) {
            rows = r
            //succClosure = nil
        }
        
        open func success(_ closure:@escaping (_ rows:MySQL.ResultSet)->Void)->Self {
            
            succClosure = closure
            
            return self
        }
        
        open func error(_ closure:@escaping (_ error:Error)->Void)->Self {
            
            errorClosure = closure
            
            return self
        }
    }


    func query(_ q:String) throws -> MysqlResult {
        
     //   if self.EOFfound && !self.hasMoreResults {
            try writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
            
            let resLen = try readResultSetHeaderPacket()
            self.columns = try readColumns(resLen)
            
            return MySQL.TextRow(con: self)
            
    //    }
    //    throw MySQL.Connection.Error.QueryInProgress
    }
    
    func nextResult() throws -> MysqlResult {
        let resLen = try readResultSetHeaderPacket()
        self.columns = try readColumns(resLen)
        
        return MySQL.TextRow(con: self)
        
    }
    
    func prepare(_ q:String) throws -> MySQL.Statement {
        
        guard self.socket != nil else {
            throw MySQL.Connection.ConnectionError.notConnected
        }
        
        try writeCommandPacketStr(MysqlCommands.COM_STMT_PREPARE, q: q)
        let stmt = MySQL.Statement(con: self)
        
        if let colCount = try stmt.readPrepareResultPacket(), let  paramCount = stmt.paramCount {
            if paramCount > 0 {
                try readUntilEOF()
            }
            
            if colCount > 0 {
                try readUntilEOF()
            }
        }
        else {
            throw MySQL.Connection.ConnectionError.statementPrepareError("Could not get col and param count")
        }
        
        return stmt
    }
    
    func exec(_ q:String) throws {
        try writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
        
        let resLen = try readResultSetHeaderPacket()
        
        if resLen > 0 {
            try readUntilEOF()
            try readUntilEOF()
        }
    }
    
    func use(_ dbname:String) throws {
        try writeCommandPacketStr(MysqlCommands.COM_INIT_DB, q: dbname)
        self.dbname = dbname
        
        let resLen = try readResultSetHeaderPacket()
        
        if resLen > 0 {
            try readUntilEOF()
            try readUntilEOF()
        }
    }
    
    /*
    func query(q:String) -> MySQL.QueryResult {
        
        let qr = MySQL.QueryResult()
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            do {
                
                try self.writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
                
                let resLen = try self.readResultSetHeaderPacket()
                self.columns = try self.readColumns(resLen)
                
                let rows = try self.readRows() as MySQL.RowArray
                
                qr.rows = rows
                qr.succClosure?(rows: rows)
            }
            catch (let e) {
                qr.errorClosure?(error: e)
            }
            
        }
        
        return qr
    }
*/
    /*
    func query(q:String, comp: (r:MySQL.QueryResultType) ->Void)  ->Void {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            do {
                try self.writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
                
                let resLen = try self.readResultSetHeaderPacket()
                self.columns = try self.readColumns(resLen)
                
                let rows = try self.readRows() as MySQL.RowArray
                comp(r: MySQL.QueryResultType.Success(rows))
            }
            catch (let e) {
                comp(r: MySQL.QueryResultType.Error(e))
            }
            
        }
    }
    */
    
    /*
    func query(q:String) throws -> MySQL.RowArray {
        try writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
        
        let resLen = try readResultSetHeaderPacket()
        self.columns = try readColumns(resLen)
        
        return try readRows()
    }
*/
    

    
}
