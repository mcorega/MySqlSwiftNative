//
//  Packets.swift
//  mysql_driver
//
//  Created by Marius Corega on 24/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


extension MySQL.Connection {
    
    func readResultOK() throws {
        
        if let data = try socket?.readPacket() {
            switch data[0] {
            case 0x00:
                handleOKPacket(data)
                break
            case 0xfe:
                break
            case 0xff:
                throw handleErrorPacket(data)
            default: break
            }
        }
    }
    
    private func handleOKPacket(data:[UInt8]) -> Int {
        var n, m : Int
        var ar, insId : UInt64?
        
        // 0x00 [1 byte]
        
        // Affected rows [Length Coded Binary]
        (ar, n) = MySQL.Utils.lenEncInt(Array(data[1...data.count-1]))
        self.affectedRows = ar ?? 0
        
        // Insert id [Length Coded Binary]
        (insId, m) = MySQL.Utils.lenEncInt(Array(data[1+n...data.count-1]))
        self.insertId = insId ?? 0
        
        self.status = UInt16(data[1+n+m]) | UInt16(data[1+n+m+1]) << 8
        
        return 0
    }
    
    func handleErrorPacket(data:[UInt8]) -> MySQL.Error {
        
        if data[0] != 0xff {
            return MySQL.Error.Error(-1, "EOF encountered")
        }
        
        let errno = data[1...3].uInt16()
        var pos = 3
        
        print("MySQL errno: \(errno)")
        
        if data[3] == 0x23 {
            pos = 9
        }
        var d1 = Array(data[pos..<data.count])
        d1.append(0)
        let errStr = d1.string()
        //let errStr = String.fromCString(UnsafePointer<CChar>(Array(data[pos...data.count-1])))! //data[pos..<data.count].string()
        
        print("MySQL errstr: \(errStr)")
        
        return MySQL.Error.Error(Int(errno), errStr!)
    }
    
    
    func readUntilEOF() throws {
        while let data = try socket?.readPacket() {
            //is EOF
            if data[0] == 0xfe {
                return
            }
        }
    }
    
    func writeCommandPacketStr(cmd:UInt8, q:String) throws {
        socket?.packnr = -1
        
        var data = [UInt8]()
        
        data.append(cmd)
        data.appendContentsOf(q.utf8)
        
        try socket?.writePacket(data)
    }
    
    func readResultSetHeaderPacket() throws ->Int {
        self.EOFfound = false
        if let data = try socket?.readPacket() {
            
            switch data[0] {
            case 0x00:
                return handleOKPacket(data)
            case 0xff:
                throw handleErrorPacket(data)
            default:break
            }
            
            //column count
            let (num, n) = MySQL.Utils.lenEncInt(data)
            
            guard num != nil else {
                return 0
            }
            
            if (n - data.count) == 0 {
                return Int(num!)
            }
            
            return 0
        }
        return 0
    }

}