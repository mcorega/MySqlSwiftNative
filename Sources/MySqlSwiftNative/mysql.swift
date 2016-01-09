//
//  mysql.swift
//  mysql_driver
//
//  Created by Marius Corega on 24/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


public struct Field {
    var tableName:String = ""
    var name:String = ""
    var flags:UInt16 = 0
    var fieldType:UInt8 = 0
    var decimals:UInt8 = 0
    var origName:String = ""
    var charSetNr:UInt8 = 0
    var collation:UInt8 = 0
}

public struct MySQL {
    
    static let maxPackAllowed = 16777215
    
    struct mysql_handshake {
        var proto_version:UInt8?
        var server_version:String?
        var conn_id:UInt32?
        var scramble:[UInt8]?
        var cap_flags:UInt16?
        var lang:UInt8?
        var status:UInt16?
        var scramble2:[UInt8]?
    }
    
    public enum Error:ErrorType {
        case Error(Int, String)
    }
    
    public class Connection {
        
        var addr:String?
        var user:String?
        var passwd:String?
        var dbname:String?
        
        var affectedRows : UInt64 = 0
        var insertId : UInt64 = 0
        var status : UInt16 = 0
        
        var socket:Socket?
        var mysql_Handshake: mysql_handshake?
        
        var columns:[Field]?
        var hasMoreResults = false
        var EOFfound = true
        var isConnected = false

        public init() {
        }
        
        public init(addr:String, user:String, passwd:String? = nil, dbname:String? = nil) throws {
            
            self.addr = addr
            self.user = user
            self.passwd = passwd
            self.dbname = dbname
        }

    }
}
