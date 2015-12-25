//
//  Statement.swift
//  mysql_driver
//
//  Created by cipi on 23/12/15.
//  Copyright © 2015 cipi. All rights reserved.
//

public extension MySQL {
    
    public class Statement {

        enum Error : ErrorType {
            case ArgsCountMismatch
            case StmtIdNotSet
            case UnknownType
            case NilConnection
        }
    
        var con:Connection?
        var id:UInt32?
        var paramCount:Int?
        var columnCount:UInt16?
        var columns: [Field]?
        
        init(con:Connection){
            self.con = con
        }
        
       public func query(args:Any...) throws -> Result{
            
            guard self.con != nil else {
                throw Error.NilConnection
            }
            
      //      if con!.EOFfound && !con!.hasMoreResults {
                try writeExecutePacket(args)
                
                let resLen = try con!.readResultSetHeaderPacket()
                self.columns = try con!.readColumns(resLen)
                
                return BinaryRow(con: con!)

       //     }
       //     throw Connection.Error.QueryInProgress
         }
        
        public func exec(args:Any...) throws {
            
            guard self.con != nil else {
                throw Error.NilConnection
            }
            
          //  if con!.EOFfound && !con!.hasMoreResults {
                try writeExecutePacket(args)
                
                let resLen = try con!.readResultSetHeaderPacket()
                if resLen > 0 {
                    try con!.readUntilEOF()
                    try con!.readUntilEOF()
                }
                
                return
                
           // }
         //   throw Connection.Error.QueryInProgress
        }
        
        func readPrepareResultPacket() throws -> UInt16? {
            
            if let data = try con?.socket?.readPacket() {
                if data[0] != 0x00 {
                    throw (con?.handleErrorPacket(data))!
                }
                
                // statement id [4 bytes]
                self.id = data[1..<5].uInt32()
                
                // Column count [16 bit uint]
                self.columnCount = data[5..<7].uInt16()
                
                // Param count [16 bit uint]
                self.paramCount = Int(data[7..<9].uInt16())
                
                return self.columnCount
            }
            
            return 0
        }
    
        func writeExecutePacket(args: [Any]) throws {
            if args.count != paramCount {
                throw Error.ArgsCountMismatch
            }
            
            //let pktLen = 4 + 1 + 4 + 1 //+ 4
            con?.socket?.packnr = -1
            
            var data = [UInt8]()
            
            // command [1 byte]
            data.append(MysqlCommands.COM_STMT_EXECUTE)
            
            guard self.id != nil else {
                throw Error.StmtIdNotSet
            }
            
            // statement_id [4 bytes]
            data.appendContentsOf([UInt8].UInt32Array(self.id!))
            
            // flags (0: CURSOR_TYPE_NO_CURSOR) [1 byte]
            data.append(0)
            
            // iteration_count (uint32(1)) [4 bytes]
            data.appendContentsOf([1,0,0,0])
            
            if args.count > 0 {
                let nmLen = (args.count + 7)>>3 //(args.count + 7)/8 //(args.count + 7)>>3
                var nullBitmap = [UInt8](count: nmLen, repeatedValue: 0)
                
                for ii in 0..<args.count {
                    //let arg = args[ii]
                    let parLen = sizeof(Int)
                    if parLen == 0 {
                        let nullByte = ii >> 3
                        let nullMask = UInt8(UInt(1) << UInt(ii-(nullByte<<3)))
                        nullBitmap[nullByte] |= nullMask
                    }
                }
                
                //null Mask
                data.appendContentsOf(nullBitmap)
                //Types
                data.append(1)
                //Data Type
                
                var dataTypeArr = [UInt8]()
                var argsArr = [UInt8]()
                
                /*
                for _ in 0..<args.count {
                    data.appendContentsOf([UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_LONGLONG)))
                }
                */
                
                for v in args {
                    switch v {
                    case let vv as UInt64:
                        dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_LONGLONG))
                        argsArr += [UInt8].UInt64Array(vv)
                        break
                    
                    case let vv as Int:
                        dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_LONG))
                        argsArr += [UInt8].Int32Array(vv)
                        break
                    
                    case let vv as Double:
                        dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_DOUBLE))
                        argsArr += [UInt8].DoubleArray(vv)
                        break
                        
                    case let vv as Float:
                        dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_FLOAT))
                        argsArr += [UInt8].FloatArray(vv)
                        break

                    case let arr as [UInt8]:
                        if arr.count < MySQL.maxPackAllowed - 1024*1024 {
                            let lenArr = MySQL.Utils.lenEncIntArray(UInt64(arr.count))
                            dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_STRING))
                            argsArr += lenArr
                            argsArr += arr
                        }
                        break
                        
                    case let str as String:
                        if str.characters.count < MySQL.maxPackAllowed - 1024*1024 {
                            let lenArr = MySQL.Utils.lenEncIntArray(UInt64(str.characters.count))
                            dataTypeArr += [UInt8].UInt16Array(UInt16(MysqlTypes.MYSQL_TYPE_STRING))
                            argsArr += lenArr
                            argsArr += [UInt8](str.utf8)
                        }
                        break
                    default:
                        throw Error.UnknownType
                    }
                }
                
                data += dataTypeArr
                data += argsArr
            }
            try con!.socket?.writePacket(data)
        }
    }
    
}
