//
//  main.swift
//  MySQLSampleOSX
//
//  Created by cipi on 25/12/15.
//
//


print("Hello, World!")

//create the connection object
let con = MySQL.Connection()
let db_name = "swift_test"

struct User:Codable {
    var id: Int
    var name: String
}

do{
    // open a new connection
    try con.open("192.168.1.122", user: "test", passwd: "test")
    
    // create a new database for tests, use exec since we don't expect any results
    try con.exec("DROP DATABASE IF EXISTS " + db_name)
    try con.exec("CREATE DATABASE IF NOT EXISTS " + db_name)
    
    // select the database
    try con.use(db_name)

    // create a table for our tests
    try con.exec("CREATE TABLE User (id INT, name VARCHAR(30), PRIMARY KEY (id))")
    
    try con.exec("INSERT INTO  User(id,name) VALUES (1, 'John')")
    try con.exec("INSERT INTO  User(id,name) VALUES (2, 'Jack')")
    
    let users: [User] = try con.getTable("User").select(Where: ["id>", 0])
    
    for u in users {
        print(u.name)
    }
    
    var user = User(id: 1, name: "John")
    
    let table = MySQL.Table(tableName: "User2", connection: con)
    try table.create(user)
    try table.insert(user)
    
    user = User(id: 2, name: "Jack")
    try table.insert(user)
    
    let users2: [User] = try con.getTable("User2").select(Where: ["id>", 0])
    
    for u in users2 {
        print(u.name)
    }
    
    /*

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
*/
    try con.close()
 }
catch (let e) {
    print(e)
}
