var fs = require('fs');
var mysql = require('mysql');
const con = mysql.createConnection({
        host: "localhost",
        user: "",
        password: "",
    })

var stream;
stream = process.stdin;
var strData = '';
    
stream.on("data", function(data) {
    var chunk = data.toString();
    strData+=chunk;
}); 

stream.on("end", function() {
    start_database_entry(JSON.parse(strData));
})

var start_database_entry = function(jsonObject) {
    con.connect(function(err) {
        if(err) throw err;

        console.log(jsonObject)
        con.query("CALL log.importJSON(?)", [ JSON.stringify(jsonObject) ], function(err, result, fields) {
            if(err) {throw err;}
            console.log("Result", result)
            con.end();
        });
    });
}
