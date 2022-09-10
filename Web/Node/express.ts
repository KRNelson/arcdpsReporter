// Import the express in typescript file
import express from 'express';
 
import { createPool , PoolConfig } from 'mysql';
import chokidar from 'chokidar';
import fileUpload from 'express-fileupload';
import cors from 'cors';
import fs from 'fs-extra';
import bodyParser from 'body-parser';
import morgan from 'morgan';
import _ from 'lodash';


// Initialize the express engine
const app: express.Application = express();
 
// Take a port 3000 for running server.
const port: number = 3300;
 
// Handling '/' Request
app.get('/', (_req, _res) => {
    _res.send("TypeScript With Expresss");
});
 
// Server setup
/*
app.listen(port, () => {
    console.log(`TypeScript with Express
         http://localhost:${port}/`);
});
*/

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
            myquery(`CALL web.importJSON('${JSON.stringify(data)}');`, (result : any) => {console.log("RESULT!", result)});
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

const objConn : PoolConfig = {
    host: 'arcdpsreporter_backend'
    , port: 3306
    , user: 'root'
    , password: 'password'
    , database: 'web'
    , insecureAuth: true
    , connectionLimit: 5
};

//create mysql connection pool
var dbconnection = createPool(objConn);

// Attempt to catch disconnects 
dbconnection.on('connection', function (connection) {
  console.log('DB Connection established');

  connection.on('error', function (err : any) {
    console.error(new Date(), 'MySQL error', err.code);
  });
  connection.on('close', function (err : any) {
    console.error(new Date(), 'MySQL close', err);
  });
});

const dbquery = (query : any, result_callback : any, query_error_callback : any, connection_error_callback : any, db : any, connect_error_callback : any) => {
    db.getConnection(function(error : any, connection : any) {
        if(error) {
            connect_error_callback(error);
            return;
        }

        connection.query(query, (error : any, results : any) => {
            connection.release();
            if(error) {
                query_error_callback(error);
                return;
            }

            result_callback(results);
        });

        connection.on('error', (error : any) => {
            connection_error_callback(error);
        })
    })
};

const myquery = (query : any, result_callback : any) => {
    const query_error_callback = (error : any) => {console.log(error)};
    const connection_error_callback = (error : any) => {console.log(error)};
    const connect_error_callback = (error : any) => {console.log(error)};
    dbquery(query, result_callback, query_error_callback, connection_error_callback, dbconnection, connect_error_callback);
};

// TODO: A "Type" that contains RegEx validation for database responses
const Player = {
    LOG_ACC_NA: ""
    // , LOG_CHR_NA: ""
    // , LOG_PRO_NA: ""
};
Object.freeze(Player);

const _player = (obj : any) => {
    const keys = Object.keys(Player);
    return keys.reduce((result : any, key : any) => {
        // TODO: Check RegEx for this object. 
        // ...

        if(obj[key]===undefined) {
            // error! 
        } else {
            result[key] = obj[key];
        }
        return result;
    }, {});
}

app.get('/players', (req, res) => {
    myquery(`CALL web.getPlayers()`
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , headers: Object.keys(Player)
                , data: rows.map((row : any) => _player(row))
            });
        });
});

// TODO: A "Type" that contains RegEx validation for database responses
const Mechanics = {
    LOG_ACC_NA: ""
    , LOG_CHR_NA: ""
    , LOG_PRO_NA: ""
    , LOG_MCH_TE: ""
    , TOT_NR: ""
    , TOT_DSC_TE: ""
};
Object.freeze(Mechanics);

const _mechanics = (obj : any) => {
    const keys = Object.keys(Mechanics);
    return keys.reduce((result : any, key : any) => {
        // TODO: Check RegEx for this object. 
        // ...

        if(obj[key]===undefined) {
            // error! 
        } else {
            result[key] = obj[key];
        }
        return result;
    }, {});
}

app.get('/mechanics', (req, res) => {
    myquery(`CALL web.getMechanicCounts()`
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , headers: Object.keys(Mechanics)
                , data: rows.map((row : any) => _mechanics(row))
            })
        });
})

app.post('/upload', async (req, res) => {
    try {
        console.log("/upload!", req.files)
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
            });
        }
    } catch(error) {
        console.log("Error!", error);
        res.status(500).send(error);
    }
})

app.listen(3000);
