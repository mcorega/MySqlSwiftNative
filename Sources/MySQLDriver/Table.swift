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
    
	class Table {
        
        enum TableError : Error {
            case tableExists
            case nilWhereClause
            case wrongParamCountInWhereClause
            case wrongParamInWhereClause
            case unknownType(String)
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
                    type = String(s[optPos.upperBound..<s.index(before: s.endIndex)])
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
            case "__NSTaggedDate", "__NSDate", "NSDate", "Date":
                return "DATETIME" + optional
            case "NSConcreteData", "NSConcreteMutableData", "NSMutableData", "Data":
                return "LONGBLOB" + optional
            case "Array<UInt8>":
                return "LONGBLOB" + optional
            default:
                throw TableError.unknownType(type)
            }
        }
        
        
        /// Creates a new table based on a Swift Object using the connection
        func create(_ object:Any, primaryKey:String?=nil, autoInc:Bool=false) throws {
            var v = ""
            let mirror = Mirror(reflecting: object)
            var count = mirror.children.count
            
            for case let (label?, value) in mirror.children {
                var type = try mysqlType(value)
                count -= 1
                
                if type != "" {
                    if let pkey = primaryKey, pkey == label {
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
        func create(_ row:MySQL.Row, primaryKey:String?=nil, autoInc:Bool=false) throws {
            var v = ""
            var count = row.count
            
            for (key, val) in row {
                var type = try mysqlType(val)
                count -= 1
                
                if type != "" {
                    if let pkey = primaryKey, pkey == key {
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
        
        open func insert(_ object:Any, exclude:[String]? = nil) throws {
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
        
        fileprivate func excludeColumn(_ colName:String, cols:[String]?) -> Bool {
            
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
        
        open func insert(_ row:Row, exclude:[String]? = nil) throws {
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
        
        open func update(_ row:Row, Where:[String:Any], exclude:[String]? = nil) throws {
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
        
        open func update(_ row:Row, key:String, exclude:[String]? = nil) throws {
            try update(row, Where: [key : row[key] as Any], exclude: exclude)
        }
        
        open func update(_ object:Any, Where:[String:Any], exclude:[String]? = nil) throws {

            let mirror = Mirror(reflecting: object)
            var row = Row()
            
            for case let (label?, value) in mirror.children {
                row[label] = value
            }
            
            try update(row, Where: Where, exclude: exclude)
        }
        
        open func update(_ object:Any, key:String, exclude:[String]? = nil) throws {
            let mirror = Mirror(reflecting: object)
            var row = Row()
            
            for case let (label?, value) in mirror.children {
                row[label] = value
            }
            
            try update(row, key: key, exclude: exclude)
        }
        
        fileprivate func parsePredicate(_ pred:[Any]) throws -> (String, [Any]) {
            
            guard pred.count % 2 == 0 else {
                throw TableError.wrongParamCountInWhereClause
            }
            
            var res = ""
            var values = [Any]()
            
            for i in 0..<pred.count {
                let val = pred[i]
                
                if let k = val as? String, i % 2 == 0 {
                    res += " \(k)?"
                }
                else if i%2 == 1 {
                    values.append(val)
                }
                else {
                    throw TableError.wrongParamInWhereClause
                }
            }
            
            return (res, values)
        }
        
        open func select(_ columns:[String]?=nil, Where:[Any]) throws -> [MySQL.ResultSet]? {
            
            guard Where.count > 0 else {
                throw TableError.nilWhereClause
            }
            
            let (predicate, vals) = try parsePredicate(Where)
            
            var q = ""
            var res : [MySQL.ResultSet]?
            var cols = ""
            
            if let colsArg = columns, colsArg.count > 0 {
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
        
        open func select<T:Codable>(_ columns:[String]?=nil, Where:[Any]) throws -> [T] {
            
            var res = [T]();
            
            if let rs = try select(columns, Where:Where) {
                for rr in rs {
                    for r in rr {
                        let data = try JSONSerialization.data(withJSONObject: r)
                        let tr:T = try JSONDecoder().decode(T.self, from: data)
                        res.append(tr)
                    }
                }
            }
            return res
        }
        
        
        open func getRecord(_ Where:[String: Any], columns:[String]?=nil) throws -> MySQL.Row? {
            
            var q = ""
            var res : MySQL.Row?
            var cols = ""
            
            if let colsArg = columns, colsArg.count > 0 {
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
        
        open func getRecord<T:RowType>(_ Where:[String: Any], columns:[String]?=nil) throws -> T? {
            if let r = try getRecord(Where, columns: columns) {
                return T(dict: r)
            }
            return nil
        }
        
        fileprivate func insertWithText(_ object:Any) throws {
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
        
        open func drop() throws {
            let q = "drop table if exists " + tableName
            try con.exec(q)
        }
        
    }
}
