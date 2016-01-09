//
//  Table.swift
//  MySQLDriver
//
//  Created by Marius Corega on 08/01/16.
//
//  Copyright © 2015 Marius Corega. All rights reserved.
//

import Foundation

public extension MySQL {

    public class Table {
        
        enum Error : ErrorType {
            case TableExists

        }
    
        var tableName : String
        var con : Connection
        
        init(tableName:String, connection:Connection) {
            self.tableName = tableName
            con = connection
        }
    
        
        func mysqlType(val:Any) -> String {
            
            var optional = " NOT NULL"
            var type = ""
            let mi = Mirror(reflecting: val)
            let s = "\(mi.subjectType)"
            
            if let optPos = s.rangeOfString("Optional<") {
                optional = ""
                let typePos = optPos.endIndex..<s.endIndex.predecessor()
                type = s.substringWithRange(typePos)
            }
            else {
                type = s
            }

            switch type {
            case "Int8":
                return "TINYINT" + optional
            case "UInt8":
                return "TINYINT UNSIGNED" + optional
            case "Int16":
                return "SMALLINT" + optional
            case "UInt16":
                return "SMALLINT UNSIGNED" + optional
            case "Int":
                return "INT" + optional
            case "UInt":
                return "INT UNSIGNED" + optional
            case "Int64":
                return "BIGINT" + optional
            case "UInt64":
                return "BIGINT UNSIGNED" + optional
            case "Float":
                return "FLOAT" + optional
            case "Double":
                return "DOUBLE" + optional
            case "String":
                return "VARCHAR(21000)" + optional
            case "__NSTaggedDate":
                return "DATETIME" + optional
            case "NSConcreteData":
                return "LONGBLOB" + optional
            default:
                return ""
            }
        }

        
        
        func create(object:Any) throws {
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            
            for case let (label?, value) in mirror.children {
                let type = mysqlType(value)
                count -= 1
                
                              
                if type != "" {
                    v += label + " " + type
                    if count > 0 {
                        v += ","
                    }
                }
            }
            
            let q = "create table \(tableName) (\(v))"
            print(q)
            try con.exec(q)
        }

        func create(row:MySQL.Row) throws {
            var v = ""
            var count = row.count
            
            for (key, val) in row {
                let type = Utils.mysqlType(val)
                count -= 1
                
                if type != "" {
                    v += key + " " + type
                    if count > 0 {
                        v += ","
                    }
                }
            }
            
            let q = "create table \(tableName) (\(v))"
            try con.exec(q)
        }
        
        public func insert(object:Any) throws {
            var l = ""
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            var args = [Any]()
            
            for case let (label?, value) in mirror.children {
                
                args.append(value)
                
                count -= 1
                l += label
                v += "?"
                if count > 0 {
                    l += ","
                    v += ","
                }
            }
            
            let q = "INSERT INTO \(tableName) (\(l)) VALUES (\(v))"
            //  print(q)
            let stmt = try con.prepare(q)
            try stmt.exec(args)
        }

        public func getRecord(Where:[String: Any]) throws -> MySQL.Row? {
            
            var q = ""
            var res : MySQL.Row?
            
  //          if let wcl = Where {
                let keys = Array(Where.keys)
                
                if  keys.count > 0 {
                    let key = keys[0]
                    if let val = Where[key] {
                        q = "SELECT * FROM \(tableName) WHERE \(key)=? LIMIT 1"
                        
                        let stmt = try con.prepare(q)
                        let stRes = try stmt.query([val])
                        
                        if let rr = try stRes.readAllRows() {
                            if rr.count > 0 && rr[0].count > 0 {
                                res = rr[0][0]
                            }
                        }

                    }
   //             }
            }
            
            
            return res
         }
        
        private func insertWithText(object:Any) throws {
            var l = ""
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            
            for case let (label?, value) in mirror.children {
                let val = Utils.stringValue(value)
                count -= 1
                
                if val != "" {
                    l += label
                    v += val
                    if count > 0 {
                        l += ","
                        v += ","
                    }
                }
            }
            
            let q = "INSERT INTO \(tableName) (\(l)) VALUES (\(v))"
            //  print(q)
            try con.exec(q)
        }
        
        public func drop() throws {
            let q = "drop table if exists " + tableName
            try con.exec(q)
        }

    }
}