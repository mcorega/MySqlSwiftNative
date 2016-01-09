//
//  Connection.swift
//  mysql_driver
//
//  Created by Marius Corega on 18/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//

import Foundation

public extension MySQL.Connection {

    public enum Error:ErrorType {
        case AddressNotSet
        case UsernameNotSet
        case NotConnected
        case StatementPrepareError(String)
        case DataReadingError
        case QueryInProgress
        case WrongHandshake
    }
    
   public func open() throws {
        
        guard self.addr != nil else {
            throw Error.AddressNotSet
        }
        
        guard self.user != nil else {
            throw Error.UsernameNotSet
        }
        
        try self.open(self.addr!, user: self.user!, passwd: self.passwd, dbname: self.dbname)
    }
    
    public func open(addr:String, user:String, passwd:String? = nil, dbname:String? = nil) throws {
        
        self.addr = addr
        self.user = user
        self.passwd = passwd
        self.dbname = dbname
        
        try self.connect()
        try self.auth()
        try self.readResultOK()
        self.isConnected = true
    }
    
    public func close() throws {
        try self.socket?.close()
        self.hasMoreResults = false
        self.EOFfound = true
        self.isConnected = false
        /*
        self.user = nil
        self.passwd = nil
        self.addr = nil
        self.dbname = nil
        */
    }
    
    public func reopen() throws {
        try self.connect()
        try self.auth()
        try self.readResultOK()
        self.isConnected = true
    }
    
    private func readHandshake() throws -> MySQL.mysql_handshake {
        
        var msh = MySQL.mysql_handshake()
        
        if let data = try socket?.readPacket() {
            
            var pos = 0
            //print(data)
            msh.proto_version = data[pos]
            pos += 1
            msh.server_version = data[pos..<data.count].string()
            pos += (msh.server_version?.utf8.count)! + 1
   //         let v1 = UInt32(data[pos...pos+4])
   //         let v2 = data[pos...pos+4].uInt32()
            msh.conn_id = data[pos...pos+4].uInt32()
            pos += 4
            msh.scramble = Array(data[pos..<pos+8])
            pos += 8 + 1
            msh.cap_flags = data[pos...pos+2].uInt16()
            pos += 2
            
            if data.count > pos {
                pos += 1 + 2 + 2 + 1 + 10
                
                let c = Array(data[pos..<pos+12])
                msh.scramble?.appendContentsOf(c)
            }
        }
        
        
        
        /*
        var (len, pn) = (socket?.readHeader())!
        
        
        msh.proto_version = socket?.readUInt8()
        msh.server_version = String.fromCString(UnsafeMutablePointer<CChar>((socket?.readNTB())!))
        
        msh.conn_id = socket?.readUInt32()
        msh.filler = socket?.readNUInt8(8)
        socket?.readUInt8()
        msh.cap_flags = socket?.readUInt16()
        msh.lang = socket?.readUInt8()
        msh.status = socket?.readUInt16()
        socket?.readNUInt8(13)
        
        if msh.cap_flags! & UInt16(MysqlClientCaps.CLIENT_PROTOCOL_41) != 0 {
        msh.scramble2 = [UInt8]()
        while socket?.bytesToRead > 0 {
        let b = socket?.readUInt8()
        msh.scramble2?.append(b!)
        }
        
        }
        
        socket?.skipAll()
        // (len, pn) = (socket?.readHeader())!
        */
        return msh
    }
    
    private func connect() throws {
        self.socket = try Socket(host: self.addr!, port: 3306)
        try self.socket?.Connect()
        self.mysql_Handshake = try readHandshake()
    }
    
    private func auth() throws {
        
        var flags :UInt32 = MysqlClientCaps.CLIENT_PROTOCOL_41 |
            MysqlClientCaps.CLIENT_LONG_PASSWORD |
            MysqlClientCaps.CLIENT_TRANSACTIONS |
            MysqlClientCaps.CLIENT_SECURE_CONN |
            
            MysqlClientCaps.CLIENT_LOCAL_FILES |
            MysqlClientCaps.CLIENT_MULTI_STATEMENTS |
            MysqlClientCaps.CLIENT_MULTI_RESULTS
        
        flags &= UInt32((mysql_Handshake?.cap_flags)!) | 0xffff0000
        //flags = 238213
        
        if self.dbname != nil {
            flags |= MysqlClientCaps.CLIENT_CONNECT_WITH_DB
        }
        
        var epwd = [UInt8]()
        
        if self.passwd != nil {
            
            guard mysql_Handshake != nil else {
                throw Error.WrongHandshake
            }

            guard mysql_Handshake!.scramble != nil else {
                throw Error.WrongHandshake
            }

            epwd = MySQL.Utils.encPasswd(self.passwd!, scramble: self.mysql_Handshake!.scramble!)
        }
        
        //let pay_len = 4 + 4 + 1 + 23 + user!.utf8.count + 1 + 1 + epwd.count + 21 + 1
        
        var arr = [UInt8]()
        
        //write flags
        arr.appendContentsOf([UInt8].UInt32Array(UInt32(flags)))
        //write max len packet
        arr.appendContentsOf([UInt8].UInt32Array(16777215))
        
        //  socket!.writeUInt8(33) //socket!.writeUInt8(mysql_Handshake!.lang!)
        arr.append(UInt8(33))
        
        arr.appendContentsOf([UInt8](count: 23, repeatedValue: 0))
        
        //send username
        arr.appendContentsOf(user!.utf8)
        arr.append(0)
        
        //send hashed password
        arr.append(UInt8(epwd.count))
        arr.appendContentsOf(epwd)
        
        //db name
        if self.dbname != nil {
            arr.appendContentsOf(self.dbname!.utf8)
        }
        arr.append(0)
        
        arr.appendContentsOf("mysql_native_password".utf8)
        arr.append(0)
        
        //print(arr)
        
        try socket?.writePacket(arr)
        
    }
    
    
    func readColumns(count:Int) throws ->[Field]? {
        
        self.columns = [Field](count: count, repeatedValue: Field())
        
        if count > 0 {
            var i = 0
            while true {
                if let data = try socket?.readPacket() {
                    
                    //EOF Packet
                    if (data[0] == 0xfe) && ((data.count == 5) || (data.count == 1)) {
                        return columns
                    }
                    
                    //Catalog
                    var pos = MySQL.Utils.skipLenEncStr(data)
                    
                    // Database [len coded string]
                    var n = MySQL.Utils.skipLenEncStr(Array(data[pos..<data.count]))
                    pos += n
                    
                    // Table [len coded string]
                    n = MySQL.Utils.skipLenEncStr(Array(data[pos..<data.count]))
                    pos += n
                    
                    // Original table [len coded string]
                    n = MySQL.Utils.skipLenEncStr(Array(data[pos..<data.count]))
                    pos += n
                    
                    // Name [len coded string]
                    var name :String?
                    (name, n) = MySQL.Utils.lenEncStr(Array(data[pos..<data.count]))
                    columns![i].name = name ?? ""
                    pos += n
                    
                    // Original name [len coded string]
                    (name,n) = MySQL.Utils.lenEncStr(Array(data[pos..<data.count]))
                    columns![i].origName = name ?? ""
                    pos += n
                    
                    // Filler [uint8]
                    pos +=  1
                    // Charset [charset, collation uint8]
                    columns![i].charSetNr = data[pos]
                    columns![i].collation = data[pos + 1]
                    // Length [uint32]
                    pos +=  2 + 4
                    
                    // Field type [uint8]
                    columns![i].fieldType = data[pos]
                    pos += 1
                    
                    // Flags [uint16]
                    columns![i].flags = data[pos...pos+1].uInt16()
                    pos += 2
                    
                    // Decimals [uint8]
                    columns![i].decimals = data[pos]
                    
                }
                i += 1
            }
        }
        
        return columns
    }
}



