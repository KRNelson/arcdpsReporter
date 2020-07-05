var http = require('http');
var url = require('url');
var mysql = require('mysql');


var gw2AllStartDates = function(res) {
    var con = mysql.createConnection({
        host: "localhost",
        user: "",
        password: ""
    });

    con.connect(function(err) {
        if(err) {
            con.end();
            return err; 
            // throw err;
        }
        var strSplits = "CALL web.getAllStartDates()";
        console.log(strSplits);
        con.query(strSplits, function(err, result, fields) {
            if(err) {
                con.end();
                return err;
            }
            // set response header
            res.writeHead(200, { 'Content-Type': 'text/html' ,
                                 "Access-Control-Allow-Origin" : "*"
                               }); 

            // set response content
            res.write(JSON.stringify(result));
            con.end();
            res.end();
       })
    });
};

var gw2vue = function(res, intStart, intEnd) {
    var con = mysql.createConnection({
        host: "localhost",
        user: "root",
        password: "password"
    });

    con.connect(function(err) {
        if(err) {
            con.end();
            return err; 
            // throw err;
        }
        var strSplits = "CALL web.vue_details(" + intStart + "," + intEnd + ")";
        console.log(strSplits);
        con.query(strSplits, function(err, result, fields) {
            if(err) {
                con.end();
                return err;
            }
            // set response header
            res.writeHead(200, { 'Content-Type': 'text/html' ,
                                 "Access-Control-Allow-Origin" : "*"
                               }); 

            // set response content
            res.write(JSON.stringify(result));
            con.end();
            res.end();
       })
    });
};


http.createServer(function(req, res) {
    const queryObject = url.parse(req.url, true).query;

    var urlParts = url.parse(req.url);
    console.log(req.url, urlParts);
 
    //direct the request to appropriate function to be processed based on the url pathname
    switch(urlParts.pathname) {
        case "/":
            gw2AllStartDates(res);
            break;
        case "/vue":
            gw2vue(res, queryObject.intStart, queryObject.intEnd)
        default:
            // homepage(req,res);
            break;
    }
}).listen(5000);