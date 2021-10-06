//
//  ConnectionPool.swift
//  swift_fork_server
//
//  Created by cipi on 20/01/16.
//  Copyright © 2016 Marius Corega. All rights reserved.
//


import Foundation

public extension MySQL {
    
	class ConnectionPool {
    
    struct ConStruct {
        var con : MySQL.Connection
        var connected : Bool
    }
    
    let numCon : Int
    var cons : [ConStruct]
    let q = DispatchQueue(label: "conpoolqueue", attributes: [])
    let conn : MySQL.Connection
    
    public init(num:Int, connection: MySQL.Connection) throws {
        numCon = num
        conn = connection
        cons = [ConStruct]()
        
        for _ in 0..<numCon {
            let c = try MySQL.Connection(addr: connection.addr!, user: connection.user!, passwd: connection.passwd, dbname: connection.dbname)
            try c.open()
            cons.append(ConStruct(con: c, connected: false))
        }
    }
    
    open func getConnection() -> MySQL.Connection? {
        
        var con : MySQL.Connection? = nil
        
        q.sync { 
            for i in 0..<self.cons.count {
                if !self.cons[i].connected {
                    self.cons[i].connected = true
                    con  = self.cons[i].con
                    break
                }
            }
            if (con == nil) {
                let c = try? MySQL.Connection(addr: self.conn.addr!, user: self.conn.user!, passwd: self.conn.passwd, dbname: self.conn.dbname)
                try? c?.open()
                    let cs = ConStruct(con: c!, connected: false)
                    self.cons.append(cs)
                    con = cs.con
                
            }
        }
        
        return con
    }
    
    open func free(_ con: MySQL.Connection?) {
        
        if (con != nil) {
            q.sync {
                for i in 0..<self.cons.count {
                    if self.cons[i].con.conID == con!.conID {
                        self.cons[i].connected = false
                        break
                    }
                }
            }
        }
    }
}
}
