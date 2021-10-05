//
//  Connection.swift
//  mysql_driver
//
//  Created by Marius Corega on 18/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//

import Foundation

public extension MySQL.Connection {

	enum ConnectionError : Error {
        case addressNotSet
        case usernameNotSet
        case notConnected
        case statementPrepareError(String)
        case dataReadingError
        case queryInProgress
        case wrongHandshake
    }
    
	func open() throws {
        
        guard self.addr != nil else {
            throw ConnectionError.addressNotSet
        }
        
        guard self.user != nil else {
            throw ConnectionError.usernameNotSet
        }
        
        try self.open(self.addr!, user: self.user!, passwd: self.passwd, dbname: self.dbname)
    }
    
	func open(_ addr:String, user:String, passwd:String? = nil, dbname:String? = nil) throws {
        
        self.addr = addr
        self.user = user
        self.passwd = passwd
        self.dbname = dbname
        
        try self.connect()
        try self.auth()
        try self.readResultOK()
        self.isConnected = true
    }
    
	func close() throws {
        try writeCommandPacket(MysqlCommands.COM_QUIT)
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
    
	func reopen() throws {
        try self.connect()
        try self.auth()
        try self.readResultOK()
        self.isConnected = true
    }
    
	func getTable(_ name: String) -> MySQL.Table {
        return MySQL.Table(tableName: name, connection: self)
    }
    
    private func readHandshake() throws -> MySQL.mysql_handshake {
        
        var msh = MySQL.mysql_handshake()
        
        if let data = try socket?.readPacket() {
            
            var pos = 0
            msh.proto_version = data[pos]
            pos += 1
            msh.server_version = data[pos..<data.count].string()
            pos += (msh.server_version?.utf8.count)! + 1
            msh.conn_id = data[pos...pos+4].uInt32()
            pos += 4
            msh.scramble = Array(data[pos..<pos+8])
            pos += 8 + 1
            msh.cap_flags = data[pos...pos+2].uInt16()
            pos += 2
            msh.server_lang = data[pos];
            pos += 1;
            msh.server_status = data[pos...pos+2].uInt16()
            pos += 2
            msh.ext_cap_flags = data[pos...pos+2].uInt16()
            pos += 2
            let auth_len = Int(data[pos]);
            pos += 1;

            // unused 10 bytes
            pos += 10

            let salt2 = Array(data[pos..<pos+12])
            msh.scramble?.append(contentsOf:salt2)
            
            pos += 12+1;
            
            msh.auth_plugin = data[pos...pos+auth_len].string()
        }
        return msh
    }
    
    private func connect() throws {
        self.socket = try Socket(host: self.addr!, port: self.port ?? 3306)
        try self.socket?.Connect()
        self.mysql_Handshake = try readHandshake()
    }
    
    private func sendAuthSwitchResponse() throws {
        
        if self.mysql_authSwitch?.auth_name == "mysql_native_password" {
            var epwd = [UInt8]()
            
            if self.passwd != nil {
                guard mysql_Handshake != nil else {
                    throw ConnectionError.wrongHandshake
                }
                guard mysql_Handshake!.scramble != nil else {
                    throw ConnectionError.wrongHandshake
                }
                epwd = MySQL.Utils.encPasswd(self.passwd!, scramble: self.mysql_Handshake!.scramble!)
            }

            try socket?.writePacket(epwd)
        }
        if self.mysql_authSwitch?.auth_name == "caching_sha2_password" {
                        
            var token = MySQL.Utils.calculateToken(self.passwd!, scramble: self.mysql_Handshake!.scramble!);
            
            try socket?.writePacket(token)
            
            try self.readAuthResponse()

        }
        if self.mysql_authSwitch?.auth_name == "sha256_password" {
            // tbd
        }

    }

    private func readAuthSwitch() throws -> MySQL.mysql_auth_switch {
        var msh = MySQL.mysql_auth_switch()

        if let data = try socket?.readPacket() {
            var pos = 0;
            msh.status = data[pos]
            pos += 1;
            let name_start = pos;
            while data[pos] != 0 {
                pos += 1;
            }
            msh.auth_name = data[name_start..<pos+1].string()
            msh.auth_data = Array(data[pos..<data.count])
        }
        return msh;
    }
    

    private func readAuthResponse() throws {
        if let data = try socket?.readPacket() {
            if data[1] == 3 {
                // fast auth
            }
            if data[1] == 4 {
                // full auth
                try self.requestServerKey();
            }
        }
    }

    private func requestServerKey() throws {
        var arr:[UInt8] = [2];
        try socket?.writePacket(arr);

        try readServerKey();
        
    }

    private func readServerKey() throws {

        if let data = try socket?.readPacket() {

            let serverPublicKey = Array(data[1..<data.count]);

            var epwd = MySQL.Utils.encPasswd(self.passwd!, scramble: self.mysql_Handshake!.scramble!, key:serverPublicKey);
             
            try socket?.writePacket(epwd)
            
        }
    }

    private func auth() throws {
        
        var flags :UInt32 = MysqlClientCaps.CLIENT_PROTOCOL_41 |
            MysqlClientCaps.CLIENT_LONG_PASSWORD |
            MysqlClientCaps.CLIENT_TRANSACTIONS |
            MysqlClientCaps.CLIENT_SECURE_CONN |
            
            MysqlClientCaps.CLIENT_LOCAL_FILES |
            MysqlClientCaps.CLIENT_MULTI_STATEMENTS |
            MysqlClientCaps.CLIENT_MULTI_RESULTS |
            MysqlClientCaps.CLIENT_PLUGIN_AUTH

        flags &= UInt32((mysql_Handshake?.cap_flags)!) | 0xffff0000
        
        if self.dbname != nil {
            flags |= MysqlClientCaps.CLIENT_CONNECT_WITH_DB
        }
        
        var epwd = [UInt8]()
        
        if self.passwd != nil {
            
            guard mysql_Handshake != nil else {
                throw ConnectionError.wrongHandshake
            }

            guard mysql_Handshake!.scramble != nil else {
                throw ConnectionError.wrongHandshake
            }

            epwd = MySQL.Utils.encPasswd(self.passwd!, scramble: self.mysql_Handshake!.scramble!)
        }
        
        //let pay_len = 4 + 4 + 1 + 23 + user!.utf8.count + 1 + 1 + epwd.count + 21 + 1
        
        var arr = [UInt8]()
        
        //write flags
        arr.append(contentsOf: [UInt8].UInt32Array(UInt32(flags)))
        
        //write max len packet
        arr.append(contentsOf:[UInt8].UInt32Array(16777215))
        
        //  socket!.writeUInt8(33) //socket!.writeUInt8(mysql_Handshake!.lang!)
        arr.append(UInt8(33))
        
        arr.append(contentsOf:[UInt8](repeating:0, count: 23))
        
        //send username
        arr.append(contentsOf:user!.utf8)
        arr.append(0)
        
        //send hashed password
        arr.append(UInt8(epwd.count))
        arr.append(contentsOf:epwd)
        
        //db name
        if self.dbname != nil {
            arr.append(contentsOf:self.dbname!.utf8)
        }
        arr.append(0)
        
        arr.append(contentsOf:"mysql_native_password".utf8)
        arr.append(0)
        
        try socket?.writePacket(arr)
        
        if mysql_Handshake?.auth_plugin == "mysql_native_password" {
            // don't do auth switch
        }
        else {
            self.mysql_authSwitch = try self.readAuthSwitch()
            try self.sendAuthSwitchResponse();
        }


    }
    
    
    func readColumns(_ count:Int) throws ->[Field]? {
        
        self.columns = [Field](repeating:Field(), count: count)
        
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



