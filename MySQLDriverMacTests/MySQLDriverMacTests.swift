//
//  MySQLDriverMacTests.swift
//  MySQLDriverMacTests
//
//  Created by cipi on 25/12/15.
//
//

import XCTest

@testable import MySQLDriverMac

class MySQLDriverMacTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCreateConnection() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            XCTAssertNotNil(con)
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testCloseConnection() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.close()
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testUse() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test")
            try con.use("swift_test")
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testExec() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest")
            try con.exec("create table xctest(id INT NOT NULL AUTO_INCREMENT, val INT, PRIMARY KEY (id))")
            try con.exec("insert into xctest(val) VALUES(1)")
            XCTAssertEqual( con.affectedRows, 1)
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQuery() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest1")
            try con.exec("create table xctest1(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id))")
            let res = try con.query("select * from xctest1")
            XCTAssertNotNil(res)
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRow() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest2")
            try con.exec("create table xctest2(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val INT)")
            try con.exec("insert into xctest2(val) VALUES(1)")
            let res = try con.query("select * from xctest2")
            let row = try res.readRow()
            try con.close()
            XCTAssertNotNil(row)
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRowResult() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest3")
            try con.exec("create table xctest3(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val INT)")
            try con.exec("insert into xctest3(val) VALUES(1)")
            let res = try con.query("select * from xctest3")
            let row = try res.readRow()
            try con.close()
            let val = row!["val"]
            XCTAssertNotNil(val)
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultInt64() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_int64")
            try con.exec("create table xctest_int64(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val BIGINT)")
            try con.exec("insert into xctest_int64(val) VALUES(1)")
            let res = try con.query("select * from xctest_int64")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Int64 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultUInt64() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_uint64")
            try con.exec("create table xctest_uint64(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val BIGINT UNSIGNED)")
            try con.exec("insert into xctest_uint64(val) VALUES(1)")
            let res = try con.query("select * from xctest_uint64")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? UInt64 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRowResultInt() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_int")
            try con.exec("create table xctest_int(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val INT)")
            try con.exec("insert into xctest_int(val) VALUES(1)")
            let res = try con.query("select * from xctest_int")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Int where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultUInt() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_uint")
            try con.exec("create table xctest_uint(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val INT UNSIGNED)")
            try con.exec("insert into xctest_uint(val) VALUES(1)")
            let res = try con.query("select * from xctest_uint")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? UInt where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultInt16() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_int16")
            try con.exec("create table xctest_int16(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val SMALLINT)")
            try con.exec("insert into xctest_int16(val) VALUES(1)")
            let res = try con.query("select * from xctest_int16")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Int16 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultUInt16() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_uint16")
            try con.exec("create table xctest_uint16(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val SMALLINT UNSIGNED)")
            try con.exec("insert into xctest_uint16(val) VALUES(1)")
            let res = try con.query("select * from xctest_uint16")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? UInt16 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRowResultInt8() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_int8")
            try con.exec("create table xctest_int8(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val TINYINT)")
            try con.exec("insert into xctest_int8(val) VALUES(1)")
            let res = try con.query("select * from xctest_int8")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Int8 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultUInt8() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_uint8")
            try con.exec("create table xctest_uint8(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val TINYINT UNSIGNED)")
            try con.exec("insert into xctest_uint8(val) VALUES(1)")
            let res = try con.query("select * from xctest_uint8")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? UInt8 where val == 1 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultDate() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_date")
            try con.exec("create table xctest_date(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val DATE)")
            try con.exec("insert into xctest_date(val) VALUES('2015-12-02')")
            let res = try con.query("select * from xctest_date")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? NSDate where val == NSDate(dateString: "2015-12-02") {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRowResultTime() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_time")
            try con.exec("create table xctest_time(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val TIME)")
            try con.exec("insert into xctest_time(val) VALUES('12:02:24')")
            let res = try con.query("select * from xctest_time")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? NSDate where val == NSDate(timeString: "12:02:24") {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    func testQueryReadRowResultDateTime() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_datetime")
            try con.exec("create table xctest_datetime(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val DATETIME)")
            try con.exec("insert into xctest_datetime(val) VALUES('2015-12-02 12:02:24')")
            let res = try con.query("select * from xctest_datetime")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? NSDate where val == NSDate(dateTimeString: "2015-12-02 12:02:24") {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultFloat() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_float")
            try con.exec("create table xctest_float(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val FLOAT)")
            try con.exec("insert into xctest_float(val) VALUES(1)")
            let res = try con.query("select * from xctest_float")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Float  where val == Float(1) {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }
    
    func testQueryReadRowResultDouble() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest_double")
            try con.exec("create table xctest_double(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val DOUBLE)")
            try con.exec("insert into xctest_double(val) VALUES(1)")
            let res = try con.query("select * from xctest_double")
            let row = try res.readRow()
            try con.close()
            if let val = row!["val"] as? Double  where val == Double(1) {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }


    func testQueryReadRowResultString() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest4")
            try con.exec("create table xctest4(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val VARCHAR(5))")
            try con.exec("insert into xctest4(val) VALUES('val')")
            let res = try con.query("select * from xctest4")
            let row = try res.readRow()
            try con.close()
            if let _ = row!["val"] as? String {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }
        catch(let e) {
            XCTAssertNil(e)
        }
    }

    
}
