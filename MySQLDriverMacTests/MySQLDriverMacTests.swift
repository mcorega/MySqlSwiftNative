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

    func testQueryReadRowResultInt() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest4")
            try con.exec("create table xctest4(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val INT)")
            try con.exec("insert into xctest4(val) VALUES(1)")
            let res = try con.query("select * from xctest4")
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

    func testQueryReadRowResultFloat() {
        let con = MySQL.Connection()
        do {
            try con.open("localhost", user: "test", passwd: "test", dbname: "swift_test")
            try con.exec("drop table if exists xctest4")
            try con.exec("create table xctest4(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY (id), val FLOAT)")
            try con.exec("insert into xctest4(val) VALUES(1)")
            let res = try con.query("select * from xctest4")
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
