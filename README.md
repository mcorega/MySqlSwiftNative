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
    try ins_stmt.exec([10+i, Float(i)/3.0, "name for \(i)"])
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
```
### CocoaPods.
```
use_frameworks!
pod 'MySqlSwiftNative', '~> 1.0.9'
```

### Carthage.
```
github "mcorega/MySqlSwiftNative" == 1.0.9
```

### License
Copyright (c) 2015, Marius Corega
All rights reserved.

Permission is granted to anyone to use this software for any purpose, 
including commercial applications, and to alter it and redistribute it freely.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

* If you use this software in a product, an acknowledgment in the product 
  documentation is required.Altered source versions must be plainly marked 
  as such, and must not be misrepresented as being the original software. 
  This notice may not be removed or altered from any source or binary distribution.
  

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
