//
//  main.swift
//  MySQLSampleOSX
//
//  Created by cipi on 25/12/15.
//
//

#if os(Linux)
import XCTest
import Foundation
    
    XCTMain([MySQLDriverLinuxTests()])
#endif

/*
print("Hello, World!")

//create the connection object
let con = MySQL.Connection()
let db_name = "swift_test"

do{
    // open a new connection
    try con.open("localhost", user: "root", passwd: "vasilica")
    
    // create a new database for tests, use exec since we don't expect any results
    try con.exec("DROP DATABASE IF EXISTS " + db_name)
    try con.exec("CREATE DATABASE IF NOT EXISTS " + db_name)
    
    // select the database
    try con.use(db_name)
    
    // create a table for our tests
    try con.exec("CREATE TABLE test (id INT NOT NULL AUTO_INCREMENT, age INT, cash FLOAT, name VARCHAR(30), PRIMARY KEY (id))")
    
    // prepare a new statement for insert
    let ins_stmt = try con.prepare("INSERT INTO test(age, cash, name) VALUES(?,?,?)")
   
    // prepare a new statement for select
    let select_stmt = try con.prepare("SELECT * FROM test WHERE Id=?")
    
    // insert 300 rows
    for i in 1...300 {
        // use a int, float and a string
        try ins_stmt.exec([10-i, Float(i)/3.0, "name for \(i)"])
    }
    
    // read rows 30 to 60
    for i in 30...60 {
        do {
            // send query
            let res = try select_stmt.query([i])
            
            //read all rows from the resultset
            let rows = try res.readAllRows()
            
            // print the rows
            print(rows)
        }
        catch (let err) {
            // if we get a error print it out
            print(err)
        }
    }

    try con.close()
 }
catch (let e) {
    print(e)
}
*/