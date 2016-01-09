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
    enum Error: ErrorType {
        case SocketCreationFailed(String)
        case SocketShutdownFailed(String)
        case SocketSettingReUseAddrFailed(String)
        case ConnectFailed(String)
        case BindFailed(String)
        case ListenFailed(String)
        case WriteFailed(String)
        case GetPeerNameFailed(String)
        case ConvertingPeerNameFailed
        case GetNameInfoFailed(String)
        case AcceptFailed(String)
        case RecvFailed(String)
        case SetSockOptFailed(String)
        case GetHostIPFailed
    }
}

public class Socket {
 
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
            throw Error.SocketCreationFailed(Socket.descriptionOfLastError())
        }
        
        // set socket options
        var value : Int32 = 1;
        guard setsockopt(self.s, SOL_SOCKET, SO_REUSEADDR, &value,
            socklen_t(sizeof(Int32))) != -1 else {
                throw Error.SetSockOptFailed(Socket.descriptionOfLastError())
        }
        
        guard setsockopt(self.s, SOL_SOCKET,  SO_KEEPALIVE, &value,
            socklen_t(sizeof(Int32))) != -1 else {
                throw Error.SetSockOptFailed(Socket.descriptionOfLastError())
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
            
            addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)),
                sin_family: sa_family_t(AF_INET),
                sin_port: Socket.porthtons(in_port_t(port)),
                sin_addr: in_addr(s_addr: inet_addr(hostIP)),
                sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            
            guard setsockopt(self.s, SOL_SOCKET,  SO_NOSIGPIPE, &value,
                socklen_t(sizeof(Int32))) != -1 else {
                    throw Error.SetSockOptFailed(Socket.descriptionOfLastError())
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
        
        memcpy(&saddr, &addr, Int(sizeof(sockaddr_in)))
        guard connect(self.s, &saddr, socklen_t(sizeof(sockaddr_in))) != -1 else {
            throw Error.ConnectFailed(Socket.descriptionOfLastError())
        }

    }
    
    func close() throws {
        guard shutdown(self.s, 2) == 0 else {
            throw Error.SocketShutdownFailed(Socket.descriptionOfLastError())
        }
    }
    
    func getHostIP(host:String) throws ->String{
        let he = gethostbyname(host)
        
        guard he != nil else {
            throw Error.GetHostIPFailed
        }
        
        let p1 = he.memory.h_addr_list[0]
        let p2 = UnsafePointer<in_addr>(p1)
        
        let p3 = inet_ntoa(p2.memory)
        
        return String.fromCString(p3)!
    }

    private class func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
    
    func readNUInt8(n:UInt32) throws -> [UInt8] {
        var buffer = [UInt8](count: Int(n), repeatedValue: 0)
        var read = 0
        
        while read < Int(n) {
            read += recv(s, &buffer + read, Int(n) - read, 0)
            
            if read <= 0 {
                throw Error.RecvFailed(Socket.descriptionOfLastError())
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
    
    func writePacket(data:[UInt8]) throws {
        try writeHeader(UInt32(data.count), pn: UInt8(self.packnr + 1))
        try  writeBuffer(data)
    }
    
    func writeBuffer(buffer:[UInt8]) throws  {
        
        try buffer.withUnsafeBufferPointer {
            var sent = 0
            while sent < buffer.count {
                #if os(Linux)
                    let s = send(self.s, $0.baseAddress + sent, Int(buffer.count - sent), Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.s, $0.baseAddress + sent, Int(buffer.count - sent))
                #endif
                if s <= 0 {
                    throw Error.WriteFailed(Socket.descriptionOfLastError())
                    
                }
                sent += s
            }
        }
    }
    
    func writeHeader(len:UInt32, pn:UInt8) throws {
        var ph = [UInt8].UInt24Array(len)
        ph.append(pn)
        try writeBuffer(ph)
    }
    
    private static func porthtons(port: in_port_t) -> in_port_t {
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
