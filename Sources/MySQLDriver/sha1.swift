//
//  sha1.swift
//  mysql_driver
//
//  Created by cipi on 22/12/15.

//
//  Based on 
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 16/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//




/* array of bytes */
extension Int {
    /** Array of bytes with optional padding (little-endian) */
    public func bytes(_ totalBytes: Int = MemoryLayout<Int>.size) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
}

/// Initialize integer from array of bytes.
/// This method may be slow
func integerWithBytes<T: BinaryInteger>(_ bytes: [UInt8]) -> T where T:ByteConvertible, T: BitshiftOperationsType {
    var bytes = bytes.reversed() as Array<UInt8> //FIXME: check it this is equivalent of Array(...)
    if bytes.count < MemoryLayout<T>.size {
        let paddingCount = MemoryLayout<T>.size - bytes.count
        if (paddingCount > 0) {
            bytes += [UInt8](repeating: 0, count: paddingCount)
        }
    }
    
    if MemoryLayout<T>.size == 1 {
        return T(truncatingBitPattern: UInt64(bytes.first!))
    }
    
    var result: T = 0
    for byte in bytes.reversed() {
        result = result << 8 | T(byte)
    }
    return result
}


protocol BitshiftOperationsType {
    static func <<(lhs: Self, rhs: Self) -> Self
    static func >>(lhs: Self, rhs: Self) -> Self
    static func <<=( lhs: inout Self, rhs: Self)
    static func >>=( lhs: inout Self, rhs: Self)
}

// MARK: - shiftLeft

// helper to be able tomake shift operation on T
func << <T:SignedInteger>(lhs: T, rhs: Int) -> Int {
    let a = lhs as! Int
    let b = rhs
    return a << b
}

func << <T:UnsignedInteger>(lhs: T, rhs: Int) -> UInt {
    let a = lhs as! UInt
    let b = rhs
    return a << b
}


protocol ByteConvertible {
    init(_ value: UInt8)
    init(truncatingBitPattern: UInt64)
}

func arrayOfBytes<T: BinaryInteger>(_ value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value
    
    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
    for j in 0 ..< min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }
    
    valuePointer.deinitialize(count: 1)
    valuePointer.deallocate()
    
    return bytes
}

private func CS_AnyGenerator<Element>(_ body: @escaping () -> Element?) -> AnyIterator<Element> {
    #if os(Linux)
        return AnyGenerator(body)
    #else
        return AnyIterator(body)
    #endif
}

struct BytesSequence: Sequence {
    let chunkSize: Int
    let data: [UInt8]
    
    
    func makeIterator() -> AnyIterator<ArraySlice<UInt8>> {
        
        var offset:Int = 0
        
        return CS_AnyGenerator {
            var end = self.chunkSize
            if self.data.count - offset < end {
                end = self.data.count - offset
            }
            //let end = min(self.chunkSize, (self.data.count - offset))
            let result = self.data[offset..<offset + end]
            offset += result.count
            return result.count > 0 ? result : nil
        }
    }
 
}

func toUInt32Array(_ slice: ArraySlice<UInt8>) -> Array<UInt32> {
    var result = Array<UInt32>()
    result.reserveCapacity(16)

    for idx in stride(from: slice.startIndex, to: slice.endIndex, by: MemoryLayout<UInt32>.size) {
        //let val:UInt32 = (UInt32(slice[idx+3]) << 24) | (UInt32(slice[idx+2]) << 16) | (UInt32(slice[idx+1]) << 8) | UInt32(slice[idx])
        
        var val:UInt32 = (UInt32(slice[idx+3]) << 24)
        val = val | (UInt32(slice[idx+2]) << 16)
        val = val | (UInt32(slice[idx+1]) << 8)
        val = val | UInt32(slice[idx])
        result.append(val)
    }
    return result
}


final class Mysql_SHA1 {
    static let size:Int = 20 // 160 / 8
    let message: [UInt8]
    
    init(_ message: [UInt8]) {
        self.message = message
    }
    
    fileprivate let h:[UInt32] = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
    
    func prepare(_ len:Int) -> Array<UInt8> {
        var tmpMessage = message
        
        // Step 1. Append Padding Bits
        tmpMessage.append(0x80) // append one bit (UInt8 with one bit) to message
        
        // append "0" bit until message length in bits ≡ 448 (mod 512)
        var msgLength = tmpMessage.count
        var counter = 0
        
        while msgLength % len != (len - 8) {
            counter += 1
            msgLength += 1
        }
        
        tmpMessage += Array<UInt8>(repeating:0, count: counter)
        return tmpMessage
    }

    
    func calculate() -> [UInt8] {
        var tmpMessage = self.prepare(64)
        
        // hash values
        var hh = h
        
        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage += (self.message.count * 8).bytes(64 / 8)
        
        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        for chunk in BytesSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 32-bit words into eighty 32-bit words:
            var M:[UInt32] = [UInt32](repeating: 0, count: 80)
            for x in 0..<M.count {
                switch (x) {
                case 0...15:
                    let start = chunk.startIndex + (x * MemoryLayout.size(ofValue: M[x]))
                    let end = start + MemoryLayout.size(ofValue: M[x])
                    let le = toUInt32Array(chunk[start..<end])[0]
                    M[x] = le.bigEndian
                    break
                default:
                    M[x] = self.rotateLeft(M[x-3] ^ M[x-8] ^ M[x-14] ^ M[x-16], 1) //FIXME: n:
                    break
                }
            }
            
            var A = hh[0]
            var B = hh[1]
            var C = hh[2]
            var D = hh[3]
            var E = hh[4]
            
            // Main loop
            for j in 0...79 {
                var f: UInt32 = 0;
                var k: UInt32 = 0
                
                switch (j) {
                case 0...19:
                    f = (B & C) | ((~B) & D)
                    k = 0x5A827999
                    break
                case 20...39:
                    f = B ^ C ^ D
                    k = 0x6ED9EBA1
                    break
                case 40...59:
                    f = (B & C) | (B & D) | (C & D)
                    k = 0x8F1BBCDC
                    break
                case 60...79:
                    f = B ^ C ^ D
                    k = 0xCA62C1D6
                    break
                default:
                    break
                }
                
                let temp = (self.rotateLeft(A,5) &+ f &+ E &+ M[j] &+ k) & 0xffffffff
                E = D
                D = C
                C = self.rotateLeft(B, 30)
                B = A
                A = temp
            }
            
            hh[0] = (hh[0] &+ A) & 0xffffffff
            hh[1] = (hh[1] &+ B) & 0xffffffff
            hh[2] = (hh[2] &+ C) & 0xffffffff
            hh[3] = (hh[3] &+ D) & 0xffffffff
            hh[4] = (hh[4] &+ E) & 0xffffffff
        }
        
        // Produce the final hash value (big-endian) as a 160 bit number:
        var result = [UInt8]()
        result.reserveCapacity(hh.count / 4)
        hh.forEach {
            let item = $0.bigEndian
            result += [UInt8(item & 0xff), UInt8((item >> 8) & 0xff), UInt8((item >> 16) & 0xff), UInt8((item >> 24) & 0xff)]
        }
        return result
    }
    
    func rotateLeft(_ v:UInt32, _ n:UInt32) -> UInt32 {
        return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
    }
    
    func equals(_ val:Mysql_SHA1) -> Bool {
        
        let v1 = self.calculate()
        let v2 = val.calculate()
        
        for i in 0..<v1.count {
            if v1[i] != v2[i] {
                return false
            }
        }
        
        return true
    }
    
}
