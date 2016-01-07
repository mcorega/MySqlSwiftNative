//
//  Constants.swift
// static let MYsql_driver
//
//  Created by Marius Corega on 18/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//


struct MysqlClientCaps {
    static let CLIENT_LONG_PASSWORD     :UInt32 = 0x00000001   // new more secure passwords
    static let CLIENT_FOUND_ROWS        :UInt32 = 0x00000002             // Found instead of affected rows
    static let CLIENT_LONG_FLAG         :UInt32 = 0x00000004             // Get all column flags
    static let CLIENT_CONNECT_WITH_DB   :UInt32 = 0x00000008            // One can specify db on connect
    static let CLIENT_NO_SCHEMA         :UInt32 = 0x00000010            // Don't allow database.table.column
    static let CLIENT_COMPRESS          :UInt32 = 0x00000020            // Can use compression protocol
    static let CLIENT_ODBC              :UInt32 = 0x00000040            // Odbc client
    static let CLIENT_LOCAL_FILES       :UInt32 = 0x00000080            // Can use LOAD DATA LOCAL
    static let CLIENT_IGNORE_SPACE      :UInt32 = 0x00000100            // Ignore spaces before '('
    static let CLIENT_PROTOCOL_41       :UInt32 = 0x00000200           // New 4.1 protocol
    static let CLIENT_INTERACTIVE       :UInt32 = 0x00000400            // This is an interactive client
    static let CLIENT_SSL               :UInt32 = 0x00000800            // Switch to SSL after handshake
    static let CLIENT_IGNORE_SIGPIPE    :UInt32 = 0x00001000            // IGNORE sigpipes
    static let CLIENT_TRANSACTIONS      :UInt32 = 0x00002000            // Client knows about transactions
    static let CLIENT_RESERVED          :UInt32 = 0x00004000            // Old flag for 4.1 protocol
    static let CLIENT_SECURE_CONN       :UInt32 = 0x00008000            // New 4.1 authentication
    static let CLIENT_MULTI_STATEMENTS  :UInt32 = 0x00010000            // Enable/disable multi-stmt support
    static let CLIENT_MULTI_RESULTS     :UInt32 = 0x00020000             // Enable/disable multi-results
}

struct MysqlFieldFlag {
    static let NOT_NULL         : UInt16 = 0x0001
    static let PRI_KEY          : UInt16 = 0x0002
    static let UNIQUE_KEY       : UInt16 = 0x0004
    static let MULTI_KEY        : UInt16 = 0x0008
    static let BLOB             : UInt16 = 0x0010
    static let UNSIGNED         : UInt16 = 0x0020
    static let ZERO_FILL        : UInt16 = 0x0040
    static let BINARY           : UInt16 = 0x0080
    static let ENUM             : UInt16 = 0x0100
    static let AUTOINCREMENT    : UInt16 = 0x0200
    static let TIMESTAMP        : UInt16 = 0x0400
    static let SET              : UInt16 = 0x0800
}

struct MysqlCommands  {
    static let COM_QUIT                 : UInt8 = 0x01
   static let COM_INIT_DB               : UInt8 = 0x02
   static let COM_QUERY                 : UInt8 = 0x03
   static let COM_FIELD_LIST            : UInt8 = 0x04
   static let COM_CREATE_DB             : UInt8 = 0x05
   static let COM_DROP_DB               : UInt8 = 0x06
   static let COM_REFRESH               : UInt8 = 0x07
   static let COM_SHUTDOWN              : UInt8 = 0x08
   static let COM_STATISTICS            : UInt8 = 0x09
   static let COM_PROCESS_INFO          : UInt8 = 0x0a
   static let COM_CONNECT               : UInt8 = 0x0b
   static let COM_PROCESS_KILL          : UInt8 = 0x0c
   static let COM_DEBUG                 : UInt8 = 0x0d
   static let COM_PING                  : UInt8 = 0x0e
   static let COM_TIME                  : UInt8 = 0x0f
   static let COM_DELAYED_INSERT        : UInt8 = 0x10
   static let COM_CHANGE_USER           : UInt8 = 0x11
   static let COM_BINLOG_DUMP           : UInt8 = 0x12
   static let COM_TABLE_DUMP            : UInt8 = 0x13
   static let COM_CONNECT_OUT           : UInt8 = 0x14
   static let COM_REGISTER_SLAVE        : UInt8 = 0x15
   static let COM_STMT_PREPARE          : UInt8 = 0x16
   static let COM_STMT_EXECUTE          : UInt8 = 0x17
   static let COM_STMT_SEND_LONG_DATA   : UInt8 = 0x18
   static let COM_STMT_CLOSE            : UInt8 = 0x19
   static let COM_STMT_RESET            : UInt8 = 0x1a
   static let COM_SET_OPTION            : UInt8 = 0x1b
   static let COM_STMT_FETCH            : UInt8 = 0x1c
}

struct MysqlTypes {
   static let MYSQL_TYPE_DECIMAL    : UInt8  = 0x00
   static let MYSQL_TYPE_TINY       : UInt8  = 0x01 // int8, uint8, bool
   static let MYSQL_TYPE_SHORT      : UInt8  = 0x02 // int16, uint16
   static let MYSQL_TYPE_LONG       : UInt8  = 0x03 // int32, uint32
   static let MYSQL_TYPE_FLOAT      : UInt8  = 0x04 // float32
   static let MYSQL_TYPE_DOUBLE     : UInt8  = 0x05 // float64
   static let MYSQL_TYPE_NULL       : UInt8  = 0x06 // nil
   static let MYSQL_TYPE_TIMESTAMP  : UInt8  = 0x07 // Timestamp
   static let MYSQL_TYPE_LONGLONG   : UInt8  = 0x08 // int64, uint64
   static let MYSQL_TYPE_INT24      : UInt8  = 0x09
   static let MYSQL_TYPE_DATE       : UInt8  = 0x0a // Date
   static let MYSQL_TYPE_TIME       : UInt8  = 0x0b // Time
   static let MYSQL_TYPE_DATETIME   : UInt8  = 0x0c // time.Time
   static let MYSQL_TYPE_YEAR       : UInt8  = 0x0d
   static let MYSQL_TYPE_NEWDATE    : UInt8  = 0x0e
   static let MYSQL_TYPE_VARCHAR    : UInt8  = 0x0f
   static let MYSQL_TYPE_BIT        : UInt8  = 0x10
   static let MYSQL_TYPE_NEWDECIMAL : UInt8  = 0xf6
   static let MYSQL_TYPE_ENUM       : UInt8  = 0xf7
   static let MYSQL_TYPE_SET        : UInt8  = 0xf8
   static let MYSQL_TYPE_TINY_BLOB  : UInt8  = 0xf9
   static let MYSQL_TYPE_MEDIUM_BLOB : UInt8 = 0xfa
   static let MYSQL_TYPE_LONG_BLOB  : UInt8  = 0xfb
   static let MYSQL_TYPE_BLOB       : UInt8  = 0xfc // Blob
   static let MYSQL_TYPE_VAR_STRING : UInt8  = 0xfd // []byte
   static let MYSQL_TYPE_STRING     : UInt8  = 0xfe // string
   static let MYSQL_TYPE_GEOMETRY   : UInt8  = 0xff
    
   static let MYSQL_UNSIGNED_MASK = 0x200000
}

struct MysqlServerStatus {
    static let SERVER_MORE_RESULTS_EXISTS : UInt16 = 0x0008
}
