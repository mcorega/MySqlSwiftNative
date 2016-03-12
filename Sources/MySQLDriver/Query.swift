//
//  Query.swift
//  mysql_driver
//
//  Created by Marius Corega on 24/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


import Foundation

public extension MySQL.Connection {

    public enum QueryResultType {
        case Success(MySQL.ResultSet)
        case Error(ErrorType)
    }
    
    public class QueryResult {
        
        var rows : MySQL.ResultSet?
        var succClosure : ((rows:MySQL.ResultSet)->Void)? = nil
        var errorClosure : ((error:ErrorType)->Void)? = nil
        
        init() {
        }
        
        init(r:MySQL.ResultSet) {
            rows = r
            //succClosure = nil
        }
        
        public func success(closure:(rows:MySQL.ResultSet)->Void)->Self {
            
            succClosure = closure
            
            return self
        }
        
        public func error(closure:(error:ErrorType)->Void)->Self {
            
            errorClosure = closure
            
            return self
        }
    }


    func query(q:String) throws -> Result {
        
     //   if self.EOFfound && !self.hasMoreResults {
            try writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
            
            let resLen = try readResultSetHeaderPacket()
            self.columns = try readColumns(resLen)
            
            return MySQL.TextRow(con: self)
            
    //    }
    //    throw MySQL.Connection.Error.QueryInProgress
    }
    
    func nextResult() throws -> Result {
        let resLen = try readResultSetHeaderPacket()
        self.columns = try readColumns(resLen)
        
        return MySQL.TextRow(con: self)
        
    }
    
    func prepare(q:String) throws -> MySQL.Statement {
        
        guard self.socket != nil else {
            throw MySQL.Connection.Error.NotConnected
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
            throw MySQL.Connection.Error.StatementPrepareError("Could not get col and param count")
        }
        
        return stmt
    }
    
    func exec(q:String) throws {
        try writeCommandPacketStr(MysqlCommands.COM_QUERY, q: q)
        
        let resLen = try readResultSetHeaderPacket()
        
        if resLen > 0 {
            try readUntilEOF()
            try readUntilEOF()
        }
    }
    
    func use(dbname:String) throws {
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