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
        
        enum Error : ErrorProtocol {
            case TableExists
            case NilWhereClause
            case WrongParamCountInWhereClause
            case WrongParamInWhereClause
            case UnknownType(String)
        }
        
        var tableName : String
        var con : Connection
        
        public init(tableName:String, connection:Connection) {
            self.tableName = tableName
            con = connection
        }
        
        
        func mysqlType(_ val:Any) throws -> String {
            
            var optional = " NOT NULL"
            var type = ""
            let mi = Mirror(reflecting: val)
            let s = "\(mi.subjectType)"
            
            #if os(Linux)
                let range = s.bridge().rangeOfString("Optional<")
                
                if range.length != 0 {
                    optional = ""
                    let typePos = NSRange(location:range.length, length:s.bridge().length - range.length - 1)
                    type = s.bridge().substringWithRange(typePos)
                }
                else {
                    type = s
                }
            #else
            
                if let optPos = s.range(of: "Optional<") {
                    optional = ""
                    let typePos = optPos.endIndex..<s.endIndex.predecessor()
                    type = s.substring(with: typePos)
                }
                else {
                    type = s
                }
            #endif
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
                return "MEDIUMTEXT" + optional
            case "__NSTaggedDate", "__NSDate", "NSDate":
                return "DATETIME" + optional
            case "NSConcreteData", "NSConcreteMutableData", "NSMutableData":
                return "LONGBLOB" + optional
            case "Array<UInt8>":
                return "LONGBLOB" + optional
            default:
                throw Error.UnknownType(type)
            }
        }
        
        
        /// Creates a new table based on a Swift Object using the connection
        func create(object:Any, primaryKey:String?=nil, autoInc:Bool=false) throws {
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            
            for case let (label?, value) in mirror.children {
                var type = try mysqlType(value)
                count -= 1
                
                if type != "" {
                    if let pkey = primaryKey where pkey == label {
                        type += " AUTO_INCREMENT"
                    }
                    
                    v += label + " " + type
                    if count > 0 {
                        v += ","
                    }
                }
            }
            
            if let pkey = primaryKey {
                v += ",PRIMARY KEY (\(pkey))"
            }
            
            let q = "create table \(tableName) (\(v))"
            //print(q)
            try con.exec(q)
        }
        
        /// Creates a new table based on a MySQL.RowStructure using the connection
        func create(row:MySQL.Row, primaryKey:String?=nil, autoInc:Bool=false) throws {
            var v = ""
            var count = row.count
            
            for (key, val) in row {
                var type = try mysqlType(val)
                count -= 1
                
                if type != "" {
                    if let pkey = primaryKey where pkey == key {
                        type += " AUTO_INCREMENT"
                    }
                    
                    v += key + " " + type
                    if count > 0 {
                        v += ","
                    }
                }
            }
            
            let q = "create table \(tableName) (\(v))"
            print(q)
            try con.exec(q)
        }
        
        public func insert(object:Any, exclude:[String]? = nil) throws {
            var l = ""
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            var args = [Any]()
            
            for case let (label?, value) in mirror.children {
                
                if !excludeColumn(label, cols: exclude) {
                    args.append(value)
                    
                    count -= 1
                    l += label
                    v += "?"
                    if count > 0 {
                        l += ","
                        v += ","
                    }

                }
            }
            
            let q = "INSERT INTO \(tableName) (\(l)) VALUES (\(v))"
            //  print(q)
            let stmt = try con.prepare(q)
            try stmt.exec(args)
        }
        
        private func excludeColumn(_ colName:String, cols:[String]?) -> Bool {
            
            guard cols != nil else {
                return false
            }
            
            for col in cols! {
                if colName == col {
                    return true
                }
            }
            
            return false
        }
        
        public func insert(_ row:Row, exclude:[String]? = nil) throws {
            var l = ""
            var v = ""
            
            var count = row.count
            var args = [Any]()
            
            for case let (label, value) in row {
                
                if !excludeColumn(label, cols: exclude) {
                    args.append(value)
                    
                    count -= 1
                    l += label
                    v += "?"
                    if count > 0 {
                        l += ","
                        v += ","
                    }
                }
            }
            
            let q = "INSERT INTO \(tableName) (\(l)) VALUES (\(v))"
            //  print(q)
            let stmt = try con.prepare(q)
            try stmt.exec(args)
        }
        
        public func update(_ row:Row, Where:[String:Any], exclude:[String]? = nil) throws {
            var l = ""
            //var v = ""
            var excludeCount = 0
            var excl : [String]
            
            if exclude == nil {
                excl = [String]()
            }
            else {
                excl = exclude!
            }
            
            if Where.keys.count > 0 {
                excl.append(Where.keys.first!)
            }
            
            excludeCount = excl.count
            
            var count = row.count - excludeCount + 1
            var args = [Any]()
            
            for case let (label, value) in row {
                
                if !excludeColumn(label, cols: exclude) {
                    args.append(value)
                    
                    count -= 1
                    l += label + "=?"
                    //v += "?"
                    if count > 0 {
                        l += ","
                        //  v += ","
                    }
                }
            }
            
            let keys = Array(Where.keys)
            let vals = Array(Where.values)
            
            if keys.count > 0 && vals.count > 0 {
                let q = "UPDATE \(tableName) SET \(l) WHERE \(keys[0])=?"
                let stmt = try con.prepare(q)
                args.append(vals[0])
                try stmt.exec(args)
                
            }
            
        }
        
        public func update(row:Row, key:String, exclude:[String]? = nil) throws {
            try update(row, Where: [key : row[key]], exclude: exclude)
        }
        
        public func update(_ object:Any, Where:[String:Any], exclude:[String]? = nil) throws {

            let mirror = Mirror(reflecting: object)
            var row = Row()
            
            for case let (label?, value) in mirror.children {
                row[label] = value
            }
            
            try update(row, Where: Where, exclude: exclude)
        }
        
        public func update(_ object:Any, key:String, exclude:[String]? = nil) throws {
            let mirror = Mirror(reflecting: object)
            var row = Row()
            
            for case let (label?, value) in mirror.children {
                row[label] = value
            }
            
            try update(row, key: key, exclude: exclude)
        }
        
        private func parsePredicate(_ pred:[Any]) throws -> (String, [Any]) {
            
            guard pred.count % 2 == 0 else {
                throw Error.WrongParamCountInWhereClause
            }
            
            var res = ""
            var values = [Any]()
            
            for i in 0..<pred.count {
                let val = pred[i]
                
                if let k = val as? String where i % 2 == 0 {
                    res += " \(k)?"
                }
                else if i%2 == 1 {
                    values.append(val)
                }
                else {
                    throw Error.WrongParamInWhereClause
                }
            }
            
            return (res, values)
        }
        
        public func select(_ columns:[String]?=nil, Where:[Any]) throws -> [MySQL.ResultSet]? {
            
            guard Where.count > 0 else {
                throw Error.NilWhereClause
            }
            
            let (predicate, vals) = try parsePredicate(Where)
            
            var q = ""
            var res : [MySQL.ResultSet]?
            var cols = ""
            
            if let colsArg = columns where colsArg.count > 0 {
                cols += colsArg[0]
                for i in 1..<colsArg.count {
                    cols += "," + colsArg[i]
                }
            }
            else {
                cols = "*"
            }
            
            q = "SELECT \(cols) FROM \(tableName) WHERE \(predicate)"
            
            let stmt = try con.prepare(q)
            let stRes = try stmt.query(vals)
            
            if let rr = try stRes.readAllRows() {
                res = rr
            }
            
            return res
        }
        
        
        public func getRecord(Where:[String: Any], columns:[String]?=nil) throws -> MySQL.Row? {
            
            var q = ""
            var res : MySQL.Row?
            var cols = ""
            
            if let colsArg = columns where colsArg.count > 0 {
                cols += colsArg[0]
                for i in 1..<colsArg.count {
                    cols += "," + colsArg[i]
                }
            }
            
            //          if let wcl = Where {
            let keys = Array(Where.keys)
            
            if  keys.count > 0 {
                let key = keys[0]
                if let val = Where[key] {
                    if cols == "" {
                        q = "SELECT * FROM \(tableName) WHERE \(key)=? LIMIT 1"
                    }
                    else {
                        q = "SELECT \(cols) FROM \(tableName) WHERE \(key)=? LIMIT 1"
                    }
                    
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
        
        public func getRecord<T:RowType>(Where:[String: Any], columns:[String]?=nil) throws -> T? {
            if let r = try getRecord(Where: Where, columns: columns) {
                return T(dict: r)
            }
            return nil
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