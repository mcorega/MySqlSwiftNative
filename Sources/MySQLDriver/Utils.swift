//
//  Utils.swift
//  mysql_driver
//
//  Created by Marius Corega on 19/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


#if os(Linux)
    import Glibc
#endif

import CommonCrypto

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


extension MySQL {
    
    internal struct Utils {
        
        static func mysqlType(_ val:Any) ->String {
            
            //var optional = false
            //var value = val
            
            let m = Mirror(reflecting: val)
            if m.displayStyle == .optional {
              //  let desc = m.description
             //   optional = true
                //value = value!
            }

            
            switch val {
            case is Int8:
                return "TINYINT"
            case is UInt8:
                return "TINYINT UNSIGNED"
            case is Int16:
                return "SMALLINT"
            case is UInt16:
                return "SMALLINT UNSIGNED"
            case is Int:
                return "INT"
            case is UInt:
                return "INT UNSIGNED"
            case is Int64:
                return "BIGINT"
            case is UInt64:
                return "BIGINT UNSIGNED"
            case is Float:
                return "FLOAT"
            case is Double:
                return "DOUBLE"
            case is String:
                return "MEDIUMTEXT"
            case is Date:
                return "DATETIME"
            case is Data:
                return "LONGBLOB"
            default:
                return ""
            }
        }

        fileprivate static func escapeData(_ data:[UInt8]) -> String {
            
            var res = [UInt8]()
            //var resStr = ""
            
            for v in data {
                // let s = Character(UnicodeScalar(v))
                // switch s {
                switch v {
                case 0:
                    // case Character("\0"):
                    res += [UInt8]("\\0".utf8)
                    //    resStr += "\\0"
                    break
                    
                case 10:
                    //case Character("\n"):
                    res += [UInt8]("\\n".utf8)
                    // resStr += "\\n"
                    break
                    
                case 92:
                    //case Character("\\"):
                    res += [UInt8]("\\\\".utf8)
                    //  resStr += "\\\\"
                    break
                    
                case 13:
                    //case Character("\r"):
                    res += [UInt8]("\\r".utf8)
                    //    resStr += "\\r"
                    break
                    
                case 39:
                    //case Character("\'"):
                    res += [UInt8]("\\'".utf8)
                    //   resStr += "\\'"
                    break
                    
                case 34:
                    //case Character("\""):
                    res += [UInt8]("\\\"".utf8)
                    //  resStr += "\\\""
                    break
                    
                case 0x1A:
                    //case Character(UnicodeScalar(0x1a)):
                    res += [UInt8]("\\Z".utf8)
                    //    resStr += "\\Z"
                    break
                    
                default:
                    res.append(v)
                    //resStr.append(Character(UnicodeScalar(v)))
                }
            }
            
            //        res.append(0)
            if let str = NSString(bytes: res, length: res.count, encoding: String.Encoding.ascii.rawValue) {
                //        if let str = String(bytes: res, encoding: NSASCIIStringEncoding) {
                #if os(Linux)
                    return str.bridge()
                #else
                    return str as String
                #endif
            }
            
            //return resStr
            return ""
        }
        
        static func stringValue(_ val:Any) -> String {
            switch val {
            case is UInt8, is Int8, is Int, is UInt, is UInt16, is Int16, is UInt32, is Int32,
            is UInt64, is Int64, is Float, is Double:
                return "\(val)"
            case is String:
                return "\"\(val)\""
            case is Data:
                let v = val as! Data
                
                let count = v.count / MemoryLayout<UInt8>.size
                
                // create an array of Uint8
                var array = [UInt8](repeating:0, count: count)
                
                // copy bytes into array
                v.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
                
                
                let str = escapeData(array)
                
                return "\"\(str)\""
                
                
            default:
                return ""
            }
        }

        static func skipLenEncStr(_ data:[UInt8]) -> Int {
            var (num, n) = lenEncInt(data)
            
            guard num != nil else {
                return 0
            }
            
            if num < 1 {
                return n
            }
            
            n += Int(num!)
            
            if data.count >= n {
                return n
            }
            return n
        }
        
        static func lenEncBin(_ b:[UInt8]) ->([UInt8]?, Int) {
            
            var (num, n) = lenEncInt(b)
            
            guard num != nil else {
                return (nil, 0)
            }
            
            if num < 1 {
                
                return (nil, n)
            }
            
            n += Int(num!)
            
            if b.count >= n {
                let str = Array(b[n-Int(num!)...n-1])
                return (str, n)
            }
            
            return (nil, n)
        }

        
        static func lenEncStr(_ b:[UInt8]) ->(String?, Int) {
            
            var (num, n) = lenEncInt(b)
            
            guard num != nil else {
                return (nil, n)
            }
            
            if num < 1 {
                
                return ("", n)
            }
            
            n += Int(num!)
            
            if b.count >= n {
                var str = Array(b[n-Int(num!)...n-1])
                str.append(0)
                return (str.string(), n)
            }
            
            return ("", n)
        }
        
        static func lenEncIntArray(_ v:UInt64) -> [UInt8] {
      
            if v <= 250 {
                return [UInt8(v & 0xff)]
            }
            else if v <= 0xffff {
                return [0xfc, UInt8(v & 0xff), UInt8((v>>8)&0xff)]
            }
            else if v <= 0xffffff {
                return [0xfd, UInt8(v & 0xff), UInt8((v>>8)&0xff), UInt8((v>>16)&0xff)]
            }
            
            return [0xfe, UInt8(v & 0xff), UInt8((v>>8) & 0xff), UInt8((v>>16) & 0xff), UInt8((v>>24) & 0xff),
                UInt8((v>>32) & 0xff), UInt8((v>>40) & 0xff), UInt8((v>>48) & 0xff), UInt8((v>>56) & 0xff)]
        }
        
        static func lenEncInt(_ b: [UInt8]) -> (UInt64?, Int) {
            
            if b.count == 0 {
                return (nil, 1)
            }
            
            switch b[0] {
                
                // 251: NULL
            case 0xfb:
                return (nil, 1)
                
                // 252: value of following 2
            case 0xfc:
                return (UInt64(b[1]) | UInt64(b[2])<<8, 3)
                
                // 253: value of following 3
            case 0xfd:
                return (UInt64(b[1]) | UInt64(b[2])<<8 | UInt64(b[3])<<16, 4)
                
                // 254: value of following 8
            case 0xfe:
               /* return (UInt64(b[1]) | UInt64(b[2])<<8 | UInt64(b[3])<<16 |
                    UInt64(b[4])<<24 | UInt64(b[5])<<32 | UInt64(b[6])<<40 |
                    UInt64(b[7])<<48 | UInt64(b[8])<<56, 9)
 */
                var a = UInt64(b[1]) | UInt64(b[2])<<8 | UInt64(b[3])<<16
                a = a | UInt64(b[4])<<24 | UInt64(b[5])<<32
                a = a | UInt64(b[6])<<40
                a = a | UInt64(b[7])<<48 | UInt64(b[8])<<56
                
                return(a, 9)
                
            default: break
            }
            
            // 0-250: value of first byte
            return (UInt64(b[0]), 1)
        }
        
        static func encPasswd(_ pwd:String, scramble:[UInt8]) -> [UInt8]{
            
            if pwd.count == 0 {
                return [UInt8]()
            }
            
            let uintpwd = [UInt8](pwd.utf8)
            
            let s1 = Mysql_SHA1(uintpwd).calculate()
            let s2 = Mysql_SHA1(s1).calculate()
            
            var scr = scramble
            scr.append(contentsOf:s2)
            
            var s3 = Mysql_SHA1(scr).calculate()
            
            for i in 0..<s3.count {
                s3[i] ^= s1[i]
            }
            
            return s3
        }

        static func sha256(bytes:[UInt8]) -> [UInt8] {
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes, CC_LONG(bytes.count), &hash)
            return hash;
        }
        
        static func xor(_ b1:[UInt8], _ b2:[UInt8]) -> [UInt8] {
            var b3 = b1;
            for i in 0..<b3.count {
                b3[i] ^= b2[i]
            }
            return b3;
        }

        static func xorRotating(_ b1:[UInt8], _ b2:[UInt8]) -> [UInt8] {
            var b3 = b1;
            for i in 0..<b3.count {
                b3[i] ^= b2[i % b2.count]
            }
            return b3;
        }

        static func rsaEncrypt(key:[UInt8], data:[UInt8]) -> [UInt8] {
            if #available(iOS 10.0, *) {
                let str = String(bytes: key, encoding: .ascii);
                let bstr = str?.components(separatedBy: "-----")[2].trimmingCharacters(in: .whitespacesAndNewlines);
                print(bstr!);
                let dbstr = Data(base64Encoded: bstr!, options: .ignoreUnknownCharacters);
                                
                let d2 = dbstr! as CFData;
                
                let publickeysi = SecKeyCreateWithData(d2,
                               [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary, nil)
            
                let key_size = SecKeyGetBlockSize(publickeysi!)

                var encrypt_bytes = [UInt8](repeating: 0, count: key_size)

                var output_size : Int = key_size
                                
                SecKeyEncrypt(publickeysi!, SecPadding.OAEP, data, data.count, &encrypt_bytes, &output_size)
                            
                return encrypt_bytes;
            }
            return [];
        }

        static func calculateToken(_ pwd:String, scramble:[UInt8]) -> [UInt8]{

            let uintpwd = [UInt8](pwd.utf8)

            let stage1 = sha256(bytes: uintpwd);
            let stage2 = sha256(bytes: stage1);
            let stage3 = sha256(bytes: stage2 + scramble);
            
            let token = xor(stage1, stage3);

            return token;
        }

        static func encPasswd(_ pwd:String, scramble:[UInt8], key:[UInt8]) -> [UInt8]{
            
            if pwd.count == 0 {
                return [UInt8]()
            }
            
            let uintpwd = [UInt8](pwd.utf8)

            var uintpwdZero = uintpwd;
            uintpwdZero.append(0);
            let stage1 = xorRotating(uintpwdZero, scramble);
            
            let output = rsaEncrypt(key: key, data: stage1);

            return output;
        }
    }
}

public extension Date
{
    
    init?(dateString:String?) {
        guard dateString != nil else {
            return nil
        }
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let d = dateStringFormatter.date(from: dateString!) {
            self.init(timeInterval:0, since:d)
            return
        }
        return nil
    }

    
    init?(timeString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "HH-mm-ss"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = dateStringFormatter.date(from: timeString) {
            self.init(timeInterval:0, since:d)
            return
        }
        return nil
    }

    
    init?(timeStringUsec:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "HH-mm-ss.SSSSSS"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = dateStringFormatter.date(from: timeStringUsec) {
            self.init(timeInterval:0, since:d)
            return
        }
        return nil
    }

    
    
    init?(dateTimeString:String) {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = dateStringFormatter.date(from: dateTimeString) {
            self.init(timeInterval:0, since:d)
        }
        else {
            return nil
        }
    }

    
    init?(dateTimeStringUsec:String) {

        struct statDFT {
            static var dateStringFormatter :  DateFormatter? = nil
            static var token : Int = 0
        }
        
       // dispatch_once(&statDFT.token) {
            statDFT.dateStringFormatter = DateFormatter()
            statDFT.dateStringFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
            statDFT.dateStringFormatter!.locale = Locale(identifier: "en_US_POSIX")
      //  }
        
        if let d = statDFT.dateStringFormatter!.date(from: dateTimeStringUsec) {
            self.init(timeInterval:0, since:d)
        }
        else {
            return nil
        }
    }

    func dateString() -> String {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(from: self)
    }

    
    func timeString() -> String {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "hh-mm-ss"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter.string(from: self)
    }
    
    func dateTimeString() -> String {
        
        struct statDFT {
            static var dateStringFormatter :  DateFormatter? = nil
            static var token : Int = 0
        }
        
      //  dispatch_once(&statDFT.token) {
            statDFT.dateStringFormatter = DateFormatter()
            statDFT.dateStringFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
            statDFT.dateStringFormatter!.locale = Locale(identifier: "en_US_POSIX")
     //   }

        return statDFT.dateStringFormatter!.string(from: self)
    }

}

extension Int8 {
    init(_ arr:ArraySlice<UInt8>) {
        var val:Int8 = 0
        let arrr = Array(arr)
        memccpy(&val, arrr, 1, 1)
        self = val
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension UInt8 {
    init(_ arr:ArraySlice<UInt8>) {
        self = UInt8(arr[arr.startIndex])
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}


extension Int16 {
    init(_ arr:ArraySlice<UInt8>) {
        self = Int16(arr[arr.startIndex + 1])<<8 | Int16(arr[arr.startIndex])
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension UInt16 {
    init(_ arr:ArraySlice<UInt8>) {
        self = UInt16(arr[arr.startIndex + 1])<<8 | UInt16(arr[arr.startIndex])
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension UInt32 {
    init(_ arr:ArraySlice<UInt8>) {
        var res : UInt32 = 0
        for i in 0..<4 {
            res |= UInt32(arr[arr.startIndex + i]) << UInt32(i*8)
        }
        self = res
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension UInt {
    init(_ arr:ArraySlice<UInt8>) {
        var res : UInt = 0
        for i in 0..<4 {
            res |= UInt(arr[arr.startIndex + i]) << UInt(i*8)
        }
        self = res
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension Int {
    init(_ arr:ArraySlice<UInt8>) {
        var res : Int = 0
        for i in 0..<4 {
            res |= Int(arr[arr.startIndex + i]) << Int(i*8)
        }
        //self = res
       // self = Int(arr[arr.startIndex + 3])<<24 | Int(arr[arr.startIndex + 2])<<16 | Int(arr[arr.startIndex + 1])<<8 | Int(arr[arr.startIndex])
        var a =  Int(arr[arr.startIndex + 3])<<24
        a = a | Int(arr[arr.startIndex + 2])<<16
        a = a | Int(arr[arr.startIndex + 1])<<8
        a = a | Int(arr[arr.startIndex])
        
        self = a
        
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension Int32 {
    init(_ arr:ArraySlice<UInt8>) {
        var res : Int32 = 0
        for i in 0..<4 {
            res |= Int32(arr[arr.startIndex + i]) << Int32(i*8)
        }
        self = res
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension Int64 {
    init(_ arr:ArraySlice<UInt8>) {
        var res : Int64 = 0
        for i in 0..<8 {
            res |= Int64(arr[arr.startIndex + i]) << Int64(i*8)
        }
        self = res
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}

extension UInt64 {
    init(_ arr:ArraySlice<UInt8>) {
        var res : UInt64 = 0
        for i in 0..<8 {
            res |= UInt64(arr[arr.startIndex + i]) << UInt64(i*8)
        }
        self = res
    }
    
    func array() ->[UInt8] {
        return arrayOfBytes(self)
    }
}


extension Sequence where Iterator.Element == UInt8 {
    func uInt16() -> UInt16 {
       let arr = self.map { (elem) -> UInt8 in
        return elem
        }
        return UInt16(arr[1])<<8 | UInt16(arr[0])
    }

    func int16() -> Int16 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        return Int16(arr[1])<<8 | Int16(arr[0])
    }

    
    func uInt24() -> UInt32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        return UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }

    func int32() -> Int32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var a: Int32 = Int32(arr[3])<<24
        a = a | Int32(arr[2])<<16
        a = a | Int32(arr[1])<<8
        a = a | Int32(arr[0])

       // return Int32(arr[3])<<24 | Int32(arr[2])<<16 | Int32(arr[1])<<8 | Int32(arr[0])
        return a
    }
    
    func uInt32() -> UInt32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var a: UInt32 = UInt32(arr[3])<<24
        a = a | UInt32(arr[2])<<16
        a = a | UInt32(arr[1])<<8
        a = a | UInt32(arr[0])
        
       // return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
        return a
    }
    
    func uInt64() -> UInt64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var res : UInt64 = 0
        
        for i in 0..<arr.count {
            res |= UInt64(arr[i]) << UInt64(i*8)
        }
        
        return res
        
        //return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }
    
    func int64() -> Int64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var res : Int64 = 0
        
        for i in 0..<arr.count {
            res |= Int64(arr[i]) << Int64(i*8)
        }
        
        return res
        
        //return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }

    /*
    func number<Element>() -> Element  {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        let t = Element.
        
    }
*/
    
    func float32() -> Float32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var f:Float32 = 0.0
        
        memccpy(&f, arr, 4, 4)

        return f
    }

    func float64() -> Float64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var f:Float64 = 0.0
        
        memccpy(&f, arr, 8, 8)
        
        return f
    }

    func string() -> String? {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }

        guard (arr.count > 0) && (arr[arr.count-1] == 0) else {
            return ""
        }
        
        return String(cString: UnsafePointer<UInt8>(arr))
    }
    
    static func UInt24Array(_ val: UInt32) -> [UInt8]{
        
        
        var byteArray = [UInt8](repeating: 0, count: 3)
        
        for i in 0...2 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt32((i) * 8))
        }
        
        return byteArray
        
        /*
        
        var buf = [UInt8](count: 3, repeatedValue: 0)
        
        buf[0] = UInt8(0x0000FF & val)
        buf[1] = UInt8(val >> 8)
        buf[2] = UInt8(val >> 16)
        
        return buf
*/
    }
    
    static func DoubleArray(_ val: Double) -> [UInt8]{
        var d = val
        var arr = [UInt8](repeating:0, count: 8)
        memccpy(&arr, &d, 8, 8)
        return arr
    }
    
    static func FloatArray(_ val: Float) -> [UInt8]{
        var d = val
        var arr = [UInt8](repeating: 0, count: 4)
        memccpy(&arr, &d, 4, 4)
        return arr
    }
    
    static func Int32Array(_ val: Int32) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 4)
        
        for i in 0...3 {
            byteArray[i] = UInt8(0x0000FF & val >> Int32((i) * 8))
        }
        
        return byteArray

    }

    static func Int64Array(_ val: Int64) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 8)
        
        for i in 0...7 {
            byteArray[i] = UInt8(0x0000FF & val >> Int64((i) * 8))
        }
        
        return byteArray
    }

    
    static func UInt32Array(_ val: UInt32) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 4)
        
        for i in 0...3 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt32((i) * 8))
        }
        
        return byteArray
    }
    
    static func Int16Array(_ val: Int16) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 2)
        
        for i in 0...1 {
            byteArray[i] = UInt8(0x0000FF & val >> Int16((i) * 8))
        }
        
        return byteArray
    }
    
    static func UInt16Array(_ val: UInt16) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 2)
        
        for i in 0...1 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt16((i) * 8))
        }
        
        return byteArray
    }

    
    static func IntArray(_ val: Int) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 4)
        
        for i in 0...3 {
            byteArray[i] = UInt8(0x0000FF & val >> Int((i) * 8))
        }
        
        return byteArray
    }
    
    static func UIntArray(_ val: UInt) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 4)
        
        for i in 0...3 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt((i) * 8))
        }
        
        return byteArray
    }
    
    static func UInt64Array(_ val: UInt64) -> [UInt8]{
        var byteArray = [UInt8](repeating:0, count: 8)
        
        for i in 0...7 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt64((i) * 8))
        }
        
        return byteArray
    }

}
