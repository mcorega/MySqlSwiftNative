### What is MySQLDriver for Swift?

>Have you ever wanted to connect to a MySQL Database from Swift without using the C client? Well, now you can. MySQLDriver for Swift is a native driver, written in Swift programming language. Using this driver you can connect directly to a MySQL Database Server from your Swift code. You can use it on a Mac, iOS Device and Linux.

### How to start?
```swift
//create the connection object
let con = MySQL.Connection()
let db_name = "swift_test"

do{
  // open a new connection
  try con.open("localhost", user: "test", passwd: "test")

  // create a new database for tests, use exec since we don't expect any results
  try con.exec("DROP DATABASE IF EXISTS " + db_name)
  try con.exec("CREATE DATABASE IF NOT EXISTS " + db_name)

  // select the database
  try con.select(db_name)
  
  // create a table for our tests
  try con.exec("CREATE TABLE test (id INT NOT NULL AUTO_INCREMENT, age INT, cash FLOAT, name VARCHAR(30), PRIMARY KEY (id))")
  
  // prepare a new statement for insert
  let ins_stmt = try con.prepare("INSERT INTO test(age, cash, name) VALUES(?,?,?)")
  
  // prepare a new statement for select
  let select_stmt = try con.prepare("SELECT * FROM test WHERE Id=?")

  // insert 300 rows
  for i in 1...300 {
    // use a int, float and a string
    try ins_stmt.exec(10+i, Float(i)/3.0, "name for \(i)")
  }
  
  // read rows 30 to 60
  for i in 30...60 {
    do {
      // send query
      let res = try select_stmt.query(i)
      
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
```
### License
Copyright (C) 2015 Marius Corega. This software is provided 'as-is', without any express or implied warranty.

In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source or binary distribution.
