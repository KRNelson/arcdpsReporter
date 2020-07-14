var fs = require('fs');
var mysql = require('mysql');
const con = mysql.createConnection({
        host: "",
        user: "",
        password: "",
        charset: '',
    })

var stream;
stream = process.stdin;
var strData = '';

stream.setEncoding('utf8')
    
stream.on("data", function(data) {
    var chunk = data.toString('utf8');
    strData+=chunk;
}); 

stream.on("end", function() {
    start_database_entry(JSON.parse(strData.trim()));
})

var start_database_entry = function(jsonObject) {
    con.connect(function(err) {
        // if(err) throw err;
        if(err) {
            console.log("Error", Object.keys(err))
            return;
        }

        con.query("CALL log.importJSON(?)", [ JSON.stringify(jsonObject) ], function(err, result, fields) {
            if(err) {
                console.log("Error", Object.keys(err), err.sqlMessage)
                con.end();
                return;
            }
            console.log("Result", result)
            con.end();
        });
    });
}