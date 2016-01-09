//
//  Rows.swift
//  mysql_driver
//
//  Created by Marius Corega on 23/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//

import Foundation

public protocol Result {
    init(con:MySQL.Connection)
    func readRow() throws -> MySQL.Row?
    func readAllRows() throws -> [MySQL.ResultSet]?
}

extension MySQL {
    
    public typealias Row = [String:Any]
    public typealias ResultSet = [Row]
    
    class TextRow: Result {
        
        var con:Connection
        
        required init(con:Connection) {
            self.con = con
        }
        
        func readRow() throws -> MySQL.Row?{
            
            guard con.isConnected == true else {
                throw Connection.Error.NotConnected
            }
            
            if con.columns?.count == 0 {
                con.hasMoreResults = false
                con.EOFfound = true
            }
            
            if !con.EOFfound, let cols = con.columns where cols.count > 0, let data = try con.socket?.readPacket()  {
                
       /*
                for val in data {
                    let u = UnicodeScalar(val)
                    print(Character(u))
                }
*/
                
                // EOF Packet
                if (data[0] == 0xfe) && (data.count == 5) {
                    con.EOFfound = true
                    let flags = Array(data[3..<5]).uInt16()
                    
                    if flags & MysqlServerStatus.SERVER_MORE_RESULTS_EXISTS == MysqlServerStatus.SERVER_MORE_RESULTS_EXISTS {
                        con.hasMoreResults = true
                    }
                    else {
                        con.hasMoreResults = false
                    }

                    return nil
                }
                
                if data[0] == 0xff {
                    throw con.handleErrorPacket(data)
                }
                
                var row = Row()
                var pos = 0
                
                if cols.count > 0 {
                    for i in 0...cols.count-1 {
                        let (name, n) = MySQL.Utils.lenEncStr(Array(data[pos..<data.count]))
                        pos += n
                        
                        if let val = name {
                            switch cols[i].fieldType {
                            
                            case MysqlTypes.MYSQL_TYPE_VAR_STRING:
                                row[cols[i].name] = name
                                break
                            
                            case MysqlTypes.MYSQL_TYPE_LONGLONG:
                                if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                                    row[cols[i].name] = UInt64(val)
                                    break
                                }
                                row[cols[i].name] = Int64(val)
                                break

                                
                            case MysqlTypes.MYSQL_TYPE_LONG, MysqlTypes.MYSQL_TYPE_INT24:
                                if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                                    row[cols[i].name] = UInt(val)
                                    break
                                }
                                row[cols[i].name] = Int(val)
                                break

                            case MysqlTypes.MYSQL_TYPE_SHORT:
                                if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                                    row[cols[i].name] = UInt16(val)
                                    break
                                }
                                row[cols[i].name] = Int16(val)
                                break

                            case MysqlTypes.MYSQL_TYPE_TINY:
                                if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                                    row[cols[i].name] = UInt8(val)
                                    break
                                }
                                row[cols[i].name] = Int8(val)
                                break

                                
                            case MysqlTypes.MYSQL_TYPE_DOUBLE:
                                row[cols[i].name] = Double(val)
                                break

                            case MysqlTypes.MYSQL_TYPE_FLOAT:
                                row[cols[i].name] = Float(val)
                                break

                            case MysqlTypes.MYSQL_TYPE_DATE:
                                row[cols[i].name] = NSDate(dateString: String(val))
                                break

                            case MysqlTypes.MYSQL_TYPE_TIME:
                                row[cols[i].name] = NSDate(timeString: String(val))
                                break

                            case MysqlTypes.MYSQL_TYPE_DATETIME:
                                row[cols[i].name] = NSDate(dateTimeString: String(val))
                                break

                            case MysqlTypes.MYSQL_TYPE_TIMESTAMP:
                                
                                row[cols[i].name] = NSDate(dateTimeString: String(val))
                                break
                                
                            case MysqlTypes.MYSQL_TYPE_NULL:
                                row[cols[i].name] = NSNull()
                                break
                            
                            default:
                                row[cols[i].name] = NSNull()
                                break
                            }
                            
                        }
                        else {
                            row[cols[i].name] = NSNull()
                        }
                    }
                }
                
                return row
            }
            
            return nil

        }
        
        func readAllRows() throws -> [ResultSet]? {
            
            var arr = [ResultSet]()
            
            repeat {
                
                if con.hasMoreResults {
                    try con.nextResult()
                }
                
                var rows = ResultSet()
                
                while let row = try readRow() {
                    rows.append(row)
                }
                
                if (rows.count > 0){
                    arr.append(rows)
                }
                
            } while con.hasMoreResults
            
            return arr
        }
    }
    
    class BinaryRow: Result {
        
        private var con:Connection
        
        required init(con:Connection) {
            self.con = con
        }
        
        func readRow() throws -> MySQL.Row?{
            
            guard con.isConnected == true else {
                throw Connection.Error.NotConnected
            }
            
            if con.columns?.count == 0 {
                con.hasMoreResults = false
                con.EOFfound = true
            }
            
            if !con.EOFfound, let cols = con.columns where cols.count > 0, let data = try con.socket?.readPacket() {
                //OK Packet
                if data[0] != 0x00 {
                    // EOF Packet
                    if (data[0] == 0xfe) && (data.count == 5) {
                        con.EOFfound = true
                        let flags = Array(data[3..<5]).uInt16()
                        
                        if flags & MysqlServerStatus.SERVER_MORE_RESULTS_EXISTS == MysqlServerStatus.SERVER_MORE_RESULTS_EXISTS {
                            con.hasMoreResults = true
                        }
                        else {
                            con.hasMoreResults = false
                        }
                        
                        return nil
                    }
                    
                    //Error packet
                    if data[0] == 0xff {
                        throw con.handleErrorPacket(data)
                    }
                    
                    if data[0] > 0 && data[0] < 251 {
                        //Result set header packet
                        //Utils.le
                    }
                    else {
                        return nil
                    }
                    
                }
                
                var pos = 1 + (cols.count + 7 + 2)>>3
                let nullBitmap = Array(data[1..<pos])
                var row = Row()
                
                for i in 0..<cols.count {
                    
                    let idx = (i+2)>>3
                    let shiftval = UInt8((i+2)&7)
                    let val = nullBitmap[idx] >> shiftval
                    
                    if (val & 1) == 1 {
                        row[cols[i].name] = NSNull()
                        continue
                    }
                    
                    switch cols[i].fieldType {
                        
                    case MysqlTypes.MYSQL_TYPE_NULL:
                        row[cols[i].name] = NSNull()
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_TINY:
                        if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                            row[cols[i].name] = UInt8(data[pos..<pos+1])
                            pos += 1
                            break
                        }
                        row[cols[i].name] = Int8(data[pos..<pos+1])
                        
                        pos += 1
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_SHORT:
                        if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                            row[cols[i].name] = UInt16(data[pos..<pos+2])
                            pos += 2
                            break
                        }
                        row[cols[i].name] = Int16(data[pos..<pos+2])
                        
                        pos += 2
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_INT24, MysqlTypes.MYSQL_TYPE_LONG:
                        if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                            row[cols[i].name] = UInt(UInt32(data[pos..<pos+4]))
                            pos += 4
                            break
                        }
                        row[cols[i].name] = Int(Int32(data[pos..<pos+4]))
                        
                        pos += 4
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_LONGLONG:
                        if cols[i].flags & MysqlFieldFlag.UNSIGNED == MysqlFieldFlag.UNSIGNED {
                            row[cols[i].name] = UInt64(data[pos..<pos+8])
                            pos += 8
                            break
                        }
                        row[cols[i].name] = Int64(data[pos..<pos+8])
                        
                        pos += 8
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_FLOAT:
                        row[cols[i].name] = data[pos..<pos+4].float32()
                        pos += 4
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_DOUBLE:
                        row[cols[i].name] = data[pos..<pos+8].float64()
                        pos += 8
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_TINY_BLOB, MysqlTypes.MYSQL_TYPE_MEDIUM_BLOB, MysqlTypes.MYSQL_TYPE_VARCHAR,
                        MysqlTypes.MYSQL_TYPE_VAR_STRING, MysqlTypes.MYSQL_TYPE_STRING, MysqlTypes.MYSQL_TYPE_LONG_BLOB,
                        MysqlTypes.MYSQL_TYPE_BLOB:
                        
                        if cols[i].charSetNr == 63 {
                            let (bres, n) = MySQL.Utils.lenEncBin(Array(data[pos..<data.count]))
                            row[cols[i].name] = bres
                            pos += n

                        }
                        else {
                            let (str, n) = MySQL.Utils.lenEncStr(Array(data[pos..<data.count]))
                            row[cols[i].name] = str
                            pos += n
                        }
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_DECIMAL, MysqlTypes.MYSQL_TYPE_NEWDECIMAL,
                        MysqlTypes.MYSQL_TYPE_BIT, MysqlTypes.MYSQL_TYPE_ENUM, MysqlTypes.MYSQL_TYPE_SET,
                        MysqlTypes.MYSQL_TYPE_GEOMETRY:
                        
                        let (str, n) = MySQL.Utils.lenEncStr(Array(data[pos..<data.count]))
                        row[cols[i].name] = str
                        pos += n
                        break
                        
                    case MysqlTypes.MYSQL_TYPE_DATE://, MysqlTypes.MYSQL_TYPE_NEWDATE:
                        let (dlen, n) = MySQL.Utils.lenEncInt(Array(data[pos..<data.count]))
                        
                        guard dlen != nil else {
                            row[cols[i].name] = NSNull()
                            break
                        }
                        var y = 0, mo = 0, d = 0//, h = 0, m = 0, s = 0, u = 0
                        var res = NSDate()
                        
                        switch Int(dlen!) {
                        case 11:
                            // 2015-12-02 12:03:15.000 001
                            //u = Int(data[pos+8..<pos+10].uInt32())
                            //res += String(format: ".%09d", u)
                            fallthrough
                        case 7:
                            // 2015-12-02 12:03:15
                            //h = Int(data[pos+5])
                            //m = Int(data[pos+6])
                            //s = Int(data[pos+7])
                            //res = String(format: "%02d:%02d:%02d", arguments: [h, m, s]) + res
                            fallthrough
                        case 4:
                            // 2015-12-02
                            y = Int(data[pos+1..<pos+3].uInt16())
                            mo = Int(data[pos+3])
                            d = Int(data[pos+4])
                            res = NSDate(dateString: String(format: "%4d-%02d-%02d", arguments: [y, mo, d]))
                            break
                        default:break
                        }
                        
                        row[cols[i].name] = res
                        pos += n + Int(dlen!)
                        
                        break

                    case MysqlTypes.MYSQL_TYPE_TIME:
                        let (dlen, n) = MySQL.Utils.lenEncInt(Array(data[pos..<data.count]))
                        
                        guard dlen != nil else {
                            row[cols[i].name] = NSNull()
                            break
                        }
                        var h = 0, m = 0, s = 0, u = 0
                        var res = NSDate()
                        
                        switch Int(dlen!) {
                        case 12:
                            //12:03:15.000 001
                            u = Int(data[pos+8..<pos+10].uInt32())
                            //res += String(format: ".%09d", u)
                            fallthrough
                        case 8:
                            //12:03:15
                            h = Int(data[pos+6])
                            m = Int(data[pos+7])
                            s = Int(data[pos+8])
                            res = NSDate(timeString:String(format: "%02d:%02d:%02d", arguments: [h, m, s]))
                            break
                        default:
                            res = NSDate(timeString: "00:00:00")
                            break
                        }
                        
                        row[cols[i].name] = res
                        pos += n + Int(dlen!)
                        
                        break

                    case MysqlTypes.MYSQL_TYPE_TIMESTAMP, MysqlTypes.MYSQL_TYPE_DATETIME:
                        
                        let (dlen, n) = MySQL.Utils.lenEncInt(Array(data[pos..<data.count]))
                        
                        guard dlen != nil else {
                            row[cols[i].name] = NSNull()
                            break
                        }
                        var y = 0, mo = 0, d = 0, h = 0, m = 0, s = 0, u = 0
                        var res = ""
                        
                        switch Int(dlen!) {
                        case 11:
                            // 2015-12-02 12:03:15.001004005
                            u = Int(data[pos+8..<pos+10].uInt32())
                            res += String(format: ".%09d", arguments: [u])
                            fallthrough
                        case 7:
                            // 2015-12-02 12:03:15
                            h = Int(data[pos+5])
                            m = Int(data[pos+6])
                            s = Int(data[pos+7])
                            res = String(format: "%02d:%02d:%02d", arguments: [h, m, s]) + res
                            fallthrough
                        case 4:
                            // 2015-12-02
                            y = Int(data[pos+1..<pos+3].uInt16())
                            mo = Int(data[pos+3])
                            d = Int(data[pos+4])
                            res = String(format: "%4d-%02d-%02d", arguments: [y, mo, d]) + " " + res
                            break
                        default:break
                        }
                        
                        
                        row[cols[i].name] = NSDate(dateTimeString: res)
                        pos += n + Int(dlen!)
                        break
                    default:
                        row[cols[i].name] = NSNull()
                        break
                    }
                    
                }
                return row
            }
            
            return nil
        }
        
        func readAllRows() throws -> [ResultSet]? {
            
            var arr = [ResultSet]()
            
            repeat {
            
                if con.hasMoreResults {
                    try con.nextResult()
                }
            
                var rows = ResultSet()
                
                while let row = try readRow() {
                    rows.append(row)
                }
                if (rows.count > 0){
                    arr.append(rows)
                }
                
                
            } while con.hasMoreResults
            
            return arr
        }
    }
}