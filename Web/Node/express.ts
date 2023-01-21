// Import the express in typescript file
import express from 'express';
 
import { createPool , PoolOptions } from 'mysql2';
import chokidar from 'chokidar';
import fileUpload from 'express-fileupload';
import cors from 'cors';
import fs from 'fs-extra';
import bodyParser from 'body-parser';
import morgan from 'morgan';
import _ from 'lodash';

import { env } from 'node:process';
import path from 'path';


// Initialize the express engine
const app: express.Application = express();

// Take a port 3000 for running server.
const port: number = 3000;

// Setup
app.use(fileUpload({
    createParentPath: true
}));

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.use(morgan('dev'));

// Handling '/' Request
app.get('/', (_req, _res) => {
    _res.send("TypeScript With Express?");
});

// Handling '/test' Request
app.get('/test', (_req, _res) => {
    _res.send("Successful test!");
});

const user_file : string = env['MYSQL_USER_FILE'] as string;
const password_file : string = env['MYSQL_PASSWORD_FILE'] as string;

const _user = path.resolve(user_file);
const _password = path.resolve(password_file);

const user = fs.readFileSync(_user, 'utf8');
const password = fs.readFileSync(_password, 'utf8');
 
const objConn : PoolOptions = {
    host: 'backend'
    , port: 3306
    , user: user
    , password: password
    , database: 'web'
    , insecureAuth: true
    , connectionLimit: 5
};

//create mysql connection pool
var dbconnection : any = createPool(objConn);

// Attempt to catch disconnects 
dbconnection.on('connection', function (connection : any) {
  console.log('DB Connection established');

  connection.on('error', function (err : any) {
    console.error(new Date(), 'MySQL error', err.code);
  });
  connection.on('close', function (err : any) {
    console.error(new Date(), 'MySQL close', err);
  });
});

const dbquery = (query : any, prepared : any, result_callback : any, query_error_callback : any, connection_error_callback : any, db : any, connect_error_callback : any) => {
    db.getConnection(function(error : any, connection : any) {
        if(error) {
            connect_error_callback(error);
            return;
        }

        connection.execute(query, prepared, (error : any, results : any) => {
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

const myquery = (query : any, prepared : any, result_callback : any) => {
    const query_error_callback = (error : any) => {console.log(error)};
    const connection_error_callback = (error : any) => {console.log(error)};
    const connect_error_callback = (error : any) => {console.log(error)};
    dbquery(query, prepared, result_callback, query_error_callback, connection_error_callback, dbconnection, connect_error_callback);
};

type Player = {
    account : string;
};

const _player = (player : any) : Player => {
    return {account : player.LOG_ACC_NA};
}

app.get('/players', (req, res) => {
    myquery(`CALL web.getAllPlayers()`, []
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _player(row))
            });
        });
});

app.post('/players', (req, res) => {
    const logs = {logs: (((r) => {return (Array.isArray(r)?r:[r])})(req.body.id || [])).map((id : string) => {return {id: id}})};
    myquery(`CALL web.postPlayers(?)`, [JSON.stringify(logs)]
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _player(row))
            });
        });
});

type Mechanics = {
    identifier : string
    , fight : string
    , fight_icon : string
    , start : string 
    , account : string
    , character : string
    , profession : string
    , mechanic : string
    , description : string
    , total : number
};

const _mechanics = (mechanics : any) : Mechanics => {
    return { identifier : mechanics.LOG_SYS_NR
           , fight : mechanics.LOG_FGT_NA
           , fight_icon : mechanics.LOG_FGT_IC
           , start : mechanics.LOG_STR_DT
           , account : mechanics.LOG_ACC_NA
           , character : mechanics.LOG_CHR_NA
           , profession : mechanics.LOG_PRO_NA
           , mechanic : mechanics.LOG_MCH_NA
           , description : mechanics.LOG_DSC_TE
           , total : Number(mechanics.TOT_NR)
        }
}

app.get('/mechanics', (req, res) => {
    myquery(`CALL web.getMechanics()`, []
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _mechanics(row))
            })
        });
});

app.post('/mechanics', (req, res) => {
    const logs = {logs: (((r) => {return (Array.isArray(r)?r:[r])})(req.body.id || [])).map((id : string) => {return {id: id}})};
    myquery(`CALL web.postMechanics(?)`, [JSON.stringify(logs)]
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _mechanics(row))
            })
        });
});

type Log = {
    identifier : string
    , elite_version : string
    , trigger_id : number 
    , ei_encounter_id : number
    , fight : string
    , fight_icon : string
    , arc_version : string
    , gw2_version : string
    , language : string
    , language_nr : number
    , recorded_by : string
    , start : string // datetime type?
    , end : string // datetime type?
    , duration : string
    , duration_ms : number
    , log_start_offset : number
    , is_win : boolean
    , is_cm : boolean
};

const _log = (log : any) : Log => {
    return { identifier : log.LOG_SYS_NR
           , elite_version : log.LOG_ELI_VER
           , trigger_id : Number(log.LOG_TRG_ID)
           , ei_encounter_id : Number(log.LOG_EI_ID)
           , fight : log.LOG_FGT_NA
           , fight_icon : log.LOG_FGT_IC
           , arc_version : log.LOG_ARC_VER
           , gw2_version : log.LOG_GW_VER
           , language : log.LOG_LANG_TE
           , language_nr : Number(log.LOG_LANG_NR)
           , recorded_by : log.LOG_REC_TE
           , start : log.LOG_STR_DT
           , end : log.LOG_END_DT
           , duration : log.LOG_DUR_DT
           , duration_ms : Number(log.LOG_DUR_MS)
           , log_start_offset : Number(log.LOG_STR_OFF)
           , is_win : (log.LOG_SUC_IR==1)?true:false
           , is_cm : (log.LOG_CM_IR==1)?true:false
        }
}

app.get('/logs', (req, res) => {
    myquery(`CALL web.getLogs()`, []
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _log(row))
            })
        });
});

app.post('/upload', async (req, res) => {
    try {
        if(!req.files) {
            res.send({
                status: false
                , message: 'No file uploaded'
            });
        } else {
            var logs : Array<fileUpload.UploadedFile> = [];

            if(!Array.isArray(req.files.logs)) {
                logs = [req.files.logs];
            } else {
                logs = req.files.logs
            }

            // Moves the uploaded log files into a watched folder by the Parser
            // The Parser then parses those logs, and that .json output to sent
            // to another watched folder to be uploaded to MySQL. 
            logs.forEach((log) => {
                log.mv('/etc/logs/' + log.name);
            });

            var arrLogs : Array<string> = logs.map((log) => log.name.split('.')[0])

            const strDirectory : string = '/etc/reports/'
            const watcher = chokidar.watch(strDirectory);
            watcher.on('add', (path : string) => {
                arrLogs = arrLogs.filter((log) => strDirectory+log !== path.split('_')[0])
                if(arrLogs.length===0) {
                    watcher.close().then(() => {
                        setTimeout(() => {
                            res.send({
                                status: true
                                , message: 'Files are uploaded'
                            });
                        }, 1000)
                        return;
                    })
                }
            });
        }
    } catch(error) {
        console.log("Error!", error);
        res.status(500).send(error);
    }
});


// Server setup
export const server = app.listen(port, () => {
});

export default app