const { createPool } = require('mysql');
const express = require('express');
const chokidar = require('chokidar');
const fileUpload = require('express-fileupload');
const cors = require('cors');
const fs = require('fs-extra');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const _ = require('lodash');

const app = express();

// VI-15-TODO: needs a better method...
chokidar.watch('/etc/reports/*.json').on('add', path => {
    // With Promises:
    const fileLoaded = () => {
        fs.readJson(path)
        .then(log => {
            var data = {
                isCM: log.isCM
                , success: log.success
                , eliteInsightsVersion: log.eliteInsightsVersion
                , triggerID: log.triggerID
                , fightName: log.fightName
                , fightIcon: log.fightIcon
                , arcVersion: log.arcVersion
                , gw2Build: log.gw2Build
                , language: log.language
                , languageID: log.languageID
                , recordedBy: log.recordedBy
                , timeStartStd: log.timeStartStd
                , timeEndStd: log.timeEndStd
                , duration: log.duration

                , players: log.players
                , mechanics: log.mechanics
            };
            myquery(`CALL web.importJSON('${JSON.stringify(data)}');`, (result) => {console.log("RESULT!", result)});
        })
        .catch(err => {
            console.error(err)
        });
    };

    setTimeout(fileLoaded, 10000)
});

app.use(fileUpload({
    createParentPath: true
}));

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.use(morgan('dev'));

const objConn = {
    host: 'arcdpsreporter_backend'
    , port: "3306"
    , user: 'root'
    , password: 'password'
    , database: 'web'
    , insecureAuth: true
    , connecitonLimit: 5
};
Object.freeze(objConn);

//create mysql connection pool
var dbconnection = createPool(objConn);

// Attempt to catch disconnects 
dbconnection.on('connection', function (connection) {
  console.log('DB Connection established');

  connection.on('error', function (err) {
    console.error(new Date(), 'MySQL error', err.code);
  });
  connection.on('close', function (err) {
    console.error(new Date(), 'MySQL close', err);
  });
});

const dbquery = (query, result_callback, query_error_callback, connection_error_callback, db, connect_error_callback) => {
    db.getConnection(function(error, connection) {
        if(error) {
            connect_error_callback(error);
            return;
        }

        connection.query(query, (error, results) => {
            connection.release();
            if(error) {
                query_error_callback(error);
                return;
            }

            result_callback(results);
        });

        connection.on('error', (error) => {
            connection_error_callback(error);
        })
    })
};

const myquery = (query, result_callback) => {
    const query_error_callback = (error) => {console.log(this.name, error)};
    const connection_error_callback = (error) => {console.log(this.name, error)};
    const connect_error_callback = (error) => {console.log(this.name, error)};
    dbquery(query, result_callback, query_error_callback, connection_error_callback, dbconnection, connect_error_callback);
};

app.post('/upload', async (req, res) => {
    try {
        if(!req.files) {
            res.send({
                status: false
                , message: 'No file uploaded'
            });
        } else {
            var logs = req.files.logs;
            if(!Array.isArray(logs)) {
                logs = [logs];
            }
            logs.forEach((log) => {
                log.mv('/etc/logs/' + log.name);
            });

            res.send({
                status: true
                , message: 'Files are uploaded'
                /*, data: {
                    name: log.name
                    , mimetype: log.mimetype
                    , size: log.size
                }*/
            });
        }
    } catch(error) {
        res.status(500).send(error);
    }
})

app.listen(3000);

/*
setInterval(() => {
    myquery("SELECT 1;", (result) => {console.log("RESULT!", result)});
}, 1000);

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
*/