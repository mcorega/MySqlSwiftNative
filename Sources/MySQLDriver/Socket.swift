//
//  Socket.swift
//  mysql_driver
//
//  Created by Marius Corega on 18/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

extension Socket {
    enum SocketError: Error {
        case socketCreationFailed(String)
        case socketShutdownFailed(String)
        case socketSettingReUseAddrFailed(String)
        case connectFailed(String)
        case bindFailed(String)
        case listenFailed(String)
        case writeFailed(String)
        case getPeerNameFailed(String)
        case convertingPeerNameFailed
        case getNameInfoFailed(String)
        case acceptFailed(String)
        case recvFailed(String)
        case setSockOptFailed(String)
        case getHostIPFailed
    }
}

open class Socket {
 
    let s : Int32
    var bytesToRead : UInt32
    var packnr : Int
    var socketInUse = false
    var addr : sockaddr_in?
    
    // ---- [ setup ] ---------------------------------------------------------
    
    
    init(host : String, port : Int) throws {
        // create socket to MySQL Server
        bytesToRead = 0
        packnr = 0
        #if os(Linux)
            s = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
            s = socket(AF_INET, SOCK_STREAM, Int32(0))
        #endif
        
        guard self.s != -1 else {
            throw SocketError.socketCreationFailed(Socket.descriptionOfLastError())
        }
        
        // set socket options
        var value : Int32 = 1;
        guard setsockopt(self.s, SOL_SOCKET, SO_REUSEADDR, &value,
            socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                throw SocketError.setSockOptFailed(Socket.descriptionOfLastError())
        }
        
        guard setsockopt(self.s, SOL_SOCKET,  SO_KEEPALIVE, &value,
            socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                throw SocketError.setSockOptFailed(Socket.descriptionOfLastError())
        }
        
        let hostIP = try getHostIP(host)
        
        #if os(Linux)
            
            // bind socket to host and port
            addr = sockaddr_in(
                sin_family: sa_family_t(AF_INET),
                sin_port: Socket.porthtons(in_port_t(port)),
                sin_addr: in_addr(s_addr: inet_addr(hostIP)),
                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            
            signal(SIGPIPE, SIG_IGN);
            
        #else
            
            addr = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
                sin_family: sa_family_t(AF_INET),
                sin_port: Socket.porthtons(in_port_t(port)),
                sin_addr: in_addr(s_addr: inet_addr(hostIP)),
                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            
            guard setsockopt(self.s, SOL_SOCKET,  SO_NOSIGPIPE, &value,
                socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                    throw SocketError.setSockOptFailed(Socket.descriptionOfLastError())
            }
            
        #endif
    }
    
    func Connect() throws {
        #if os(Linux)
            var saddr = sockaddr( sa_family: 0,
                sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
         #else
            var saddr = sockaddr(sa_len: 0, sa_family: 0,
                sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

        #endif
        
        memcpy(&saddr, &addr, Int(MemoryLayout<sockaddr_in>.size))
        guard connect(self.s, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else {
            throw SocketError.connectFailed(Socket.descriptionOfLastError())
        }

    }
    
    func close() throws {
        guard shutdown(self.s, 2) == 0 else {
            throw SocketError.socketShutdownFailed(Socket.descriptionOfLastError())
        }
    }
    
    func getHostIP(_ host:String) throws ->String{
        let he = gethostbyname(host)
        
        guard he != nil else {
            throw SocketError.getHostIPFailed
        }
        
        let p1 = he?.pointee.h_addr_list[0]
        let p2 = UnsafeRawPointer(p1)?.assumingMemoryBound(to: in_addr.self)
        
        let p3 = inet_ntoa(p2!.pointee)
        
        return String(cString:p3!)
    }

    fileprivate class func descriptionOfLastError() -> String {
        return String(cString:UnsafePointer(strerror(errno))) //?? "Error: \(errno)"
    }
    
    func readNUInt8(_ n:UInt32) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: Int(n))
        var read = 0
        
        while read < Int(n) {
            read += recv(s, &buffer[read], Int(n) - read, 0)
            
            if read <= 0 {
                throw SocketError.recvFailed(Socket.descriptionOfLastError())
            }
        }
        
        if bytesToRead >= UInt32(n) {
            bytesToRead -= UInt32(n)
        }
        
        return buffer
    }
    
    
    func readHeader() throws -> (UInt32, Int) {
        let b = try readNUInt8(3).uInt24()
        
        let pn = try readNUInt8(1)[0]
        bytesToRead = b
        
        return (b, Int(pn))
    }
    
    func readPacket() throws -> [UInt8] {
        let (len, pknr) = try readHeader()
        bytesToRead = len
        self.packnr = pknr
        return try readNUInt8(len)
    }
    
    func writePacket(_ data:[UInt8]) throws {
        try writeHeader(UInt32(data.count), pn: UInt8(self.packnr + 1))
        try  writeBuffer(data)
    }
    
    func writeBuffer(_ buffer:[UInt8]) throws  {
        
        try buffer.withUnsafeBufferPointer {
            var sent = 0
            while sent < buffer.count {
                #if os(Linux)
                    let s = send(self.s, $0.baseAddress + sent, Int(buffer.count - sent), Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.s, $0.baseAddress! + sent, Int(buffer.count - sent))
                #endif
                if s <= 0 {
                    throw SocketError.writeFailed(Socket.descriptionOfLastError())
                    
                }
                sent += s
            }
        }
    }
    
    func writeHeader(_ len:UInt32, pn:UInt8) throws {
        var ph = [UInt8].UInt24Array(len)
        ph.append(pn)
        try writeBuffer(ph)
    }
    
    fileprivate static func porthtons(_ port: in_port_t) -> in_port_t {
        #if os(Linux)
            return htons(port)
        #else
            let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return isLittleEndian ? _OSSwapInt16(port) : port
        #endif
    }
    
    /*
    func lockSocket() {
    while socketInUse {
    
    }
    socketInUse = true
    }
    
    func unlockSocket() {
    socketInUse = false
    }
    
    func socketLocked() -> Bool {
    return socketInUse
    }
    */

}
