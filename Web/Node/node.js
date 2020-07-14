var http = require('http');
var url = require('url');
var mysql = require('mysql');
var objConn = {
    host: "",
    user: "",
    password: "",
    charset: ''
};

var gw2AllStartDates = function(res) {
    var con = mysql.createConnection(objConn);

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
    var con = mysql.createConnection(objConn);

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

var gw2attendence = function(res, jsonObject) {
    var con = mysql.createConnection(objConn);

    con.connect(function(err) {
        if(err) {
            con.end();
            return err; 
            // throw err;
        }
        con.query("CALL web.vue_attendence(?)", [jsonObject], function(err, result, fields) {
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
}

var gw2historicalRoles = function(res) {
    var con = mysql.createConnection(objConn);

    con.connect(function(err) {
        if(err) {
            con.end();
            return err; 
            // throw err;
        }
        con.query("CALL web.vue_historicalRoles()", function(err, result, fields) {
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
}

http.createServer(function(req, res) {
    const queryObject = url.parse(req.url, true).query;

    var urlParts = url.parse(req.url);
    //direct the request to appropriate function to be processed based on the url pathname
    switch(urlParts.pathname) {
        case "/":
            gw2AllStartDates(res);
            break;
        case "/vue":
            gw2vue(res, queryObject.intStart, queryObject.intEnd);
            break;
        case "/attendence":
            gw2attendence(res, queryObject.jsonObject);
            break;
        case "/historical":
            gw2historicalRoles(res);
            break;
        default:
            // homepage(req,res);
            break;
    }
}).listen(5000);