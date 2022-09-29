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
const port: number = 3000;

var files : any = [];

/**
 * Chokidar is used to watch for any new parsed log files. 
 * Waits 10 seconds before actually attempting to upload.
 *      Since after the 1st add there are additional 'change' events
 * 
 * "Side effect": If the same file is uploaded it will be skipped over. 
 * 
 * VI-15-TODO: Needs a better method than waiting 10 seconds...
 */
var paths : Record<string, NodeJS.Timeout>= {};
const delay: number = 2000;
chokidar.watch('/etc/reports/*.json').on('all', (eventName : string, path : string) => {

    const fileLoaded = () => {
        fs.readJson(path)
        .then(log => {
            const players = log.players.map((player : any) => {
                return { instanceID : player.instanceID
                        , account : player.account.replace("'", "") // Remove '
                        , name : player.name.replace("'", "") // Remove '
                        , profession : player.profession
                        , hasCommanderTag : player.hasCommanderTag
                        , group : player.group
                        , condition : player.condition
                        , concentration : player.concentration
                        , healing : player.healing
                        , toughness : player.toughness
                        }
                });

            /*
            const rotations = log.players.map((player : any) => {
                return player.rotation.map((rotation : any) => {
                    return rotation.skills.map((skill : any) => {
                        return { account : player.account.replace("'", "")
                               , id : rotation.id
                               , name : log.skillMap["s" + rotation.id].name.replace("'", "")
                               , castTime : skill.castTime
                               , duration : skill.duration
                               , timeGained : skill.timeGained
                               , quickness : skill.quickness
                               }
                    });
                });
            }).flat(Infinity);
            */

            const mechanics = log.mechanics.map((mechanic : any) => {
                return { name : mechanic.name.replace("'", "")
                       , description : mechanic.description.replace("'", "")
                       , mechanicsData : mechanic.mechanicsData.map((mechanicsData : any) => {
                            return { time : mechanicsData.time
                                   , actor : mechanicsData.actor.replace("'", "")
                                   }
                       })
                       }
            });

            const data = {
                isCM: log.isCM
                , success: log.success
                , eliteInsightsVersion: log.eliteInsightsVersion
                , triggerID: log.triggerID
                , fightName: log.fightName
                , arcVersion: log.arcVersion
                , gw2Build: log.gw2Build
                , language: log.language
                , languageID: log.languageID
                , recordedBy: log.recordedBy
                , timeStartStd: log.timeStartStd
                , timeEndStd: log.timeEndStd
                , duration: log.duration

                , players: players 
                , mechanics: mechanics 
                // , rotations : rotations
                , file : path
            };
            myquery(`CALL web.importJSON('${JSON.stringify(data)}');`
                , (result : any) => {
                    // Used to communicated between the web log upload and server parsing/uploading. 
                    files = files.filter((file : any) => {
                        const fileName = (file.name).split('.')[0]; 
                        const pathName = ((path.split('/')[3]).split('.')[0]).split('_')[0]; 
                        return fileName!=pathName;
                    });
                })
                ;
        })
        .catch(err => {
            console.error(err)
        });

        console.log('timeout', path)
        delete paths[path];
    };

    switch(eventName) {
        case 'add': paths[path] = setTimeout(fileLoaded, delay);
                    console.log('add', path)
                    break;
        case 'change': 
                    paths[path].refresh();
                    console.log('change', path)
                    break;
    }
});

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
    _res.send("TypeScript With Express");
});
 
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

type Player = {
    account : string;
};

const _player = (player : any) : Player => {
    return {account : player.LOG_ACC_NA};
}

app.get('/players', (req, res) => {
    myquery(`CALL web.getAllPlayers()`
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
    myquery(`CALL web.postPlayers('${JSON.stringify(logs)}')`
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _player(row))
            });
        });
});

type Mechanics = {
    account : string
    , character : string
    , profession : string
    , mechanics : string
    , total : number
    , descriptive : string
};

const _mechanics = (mechanics : any) : Mechanics => {
    return { account : mechanics.LOG_ACC_NA
           , character : mechanics.LOG_CHR_NA
           , profession : mechanics.LOG_PRO_NA
           , mechanics : mechanics.LOG_MCH_TE
           , total : mechanics.TOT_NR
           , descriptive : mechanics.TOT_DSC_TE
        }
}

app.get('/mechanics', (req, res) => {
    myquery(`CALL web.getMechanics()`
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
    myquery(`CALL web.postMechanics('${JSON.stringify(logs)}')`
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
    , is_cm : boolean
    , is_win : boolean
    , elite_version : string
    , trigger_id : number 
    , fight : string
    , arc_version : string
    , gw2_version : string
    , language : string
    , language_nr : number
    , recorded_by : string
    , start : string // datetime type?
    , end : string // datetime type?
    , duration : string

};

const _log = (log : any) : Log => {
    return { identifier : log.LOG_SYS_NR
           , is_cm : (log.LOG_CM_IR==1)?true:false
           , is_win : (log.LOG_SUC_IR==1)?true:false
           , elite_version : log.LOG_ELI_VER
           , trigger_id : log.LOG_TRG_ID
           , fight : log.LOG_FGT_NA
           , arc_version : log.LOG_ARC_VER
           , gw2_version : log.LOG_GW_VER
           , language : log.LOG_LANG_TE
           , language_nr : log.LOG_LANG_NR
           , recorded_by : log.LOG_REC_TE
           , start : log.LOG_STR_DT
           , end : log.LOG_END_DT
           , duration : log.LOG_DUR_DT
        }
}

app.get('/logs', (req, res) => {
    myquery(`CALL web.getLogs()`
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
        console.log("/upload!", req.files)
        if(!req.files) {
            res.send({
                status: false
                , message: 'No file uploaded'
            });
        } else {
            var logs = req.files.logs;

            files = files.concat(logs);

            if(!Array.isArray(logs)) {
                logs = [logs];
            }
            logs.forEach((log) => {
                log.mv('/etc/logs/' + log.name);
            });

            const thsInterval = setInterval(() => {
                if(files.length==0) {
                    res.send({
                        status: true
                        , message: 'Files are uploaded'
                    });

                    clearInterval(thsInterval);
                }
            }, 5000);
        }
    } catch(error) {
        console.log("Error!", error);
        res.status(500).send(error);
    }
});


// Server setup
export const server = app.listen(port, () => {
    console.log(`TypeScript with Express
         http://localhost:${port}/`);
});

export default app