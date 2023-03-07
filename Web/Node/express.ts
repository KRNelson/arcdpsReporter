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

import { env, send } from 'node:process';
import path from 'path';

import {v4 as uuidv4 } from 'uuid';
import { ApisEvents_k8s_io } from 'kubernetes-client';
import { Http2ServerRequest } from 'node:http2';
import https from 'https';

// import k8s from '@kubernetes/client-node';
// const k8s = require('@kubernetes/client-node');
import * as k8s from '@kubernetes/client-node';

// Initialize the express engine
const app: express.Application = express();

// Take a port 3000 for running server.
const port: number = 3000;
const sport: number = 3443;

const kc = new k8s.KubeConfig();
kc.loadFromDefault();

console.log("KC", JSON.stringify(kc));

const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
console.log("k8sApi", JSON.stringify(k8sApi));


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

const user = fs.readFileSync(_user, 'utf8').replace('\n', '')
const password = fs.readFileSync(_password, 'utf8').replace('\n', '');
 
const objConn : PoolOptions = {
    host: 'localhost'
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

type Rotations = {
    identifier : string
    , fight : string
    , fight_icon : string
    , start : string 
    , account : string
    , character : string
    , profession : string
    , skill_id : string
    , cast : number
    , duration : number
};

const _rotations = (rotations : any) : Rotations => {
    return { identifier : rotations.LOG_SYS_NR
           , fight : rotations.LOG_FGT_NA
           , fight_icon : rotations.LOG_FGT_IC
           , start : rotations.LOG_STR_DT
           , account : rotations.LOG_ACC_NA
           , character : rotations.LOG_CHR_NA
           , profession : rotations.LOG_PRO_NA
           , skill_id : rotations.LOG_SKL_ID
           , cast : Number(rotations.LOG_CST_NR)
           , duration : Number(rotations.LOG_DUR_NR)
        }
}

app.get('/rotations', (req, res) => {
    myquery(`CALL web.getRotations()`, []
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _rotations(row))
            })
        });
});

app.post('/rotations', (req, res) => {
    const logs = {logs: (((r) => {return (Array.isArray(r)?r:[r])})(req.body.id || [])).map((id : string) => {return {id: id}})};
    myquery(`CALL web.postRotations(?)`, [JSON.stringify(logs)]
        , (result : any) => {
            const rows = result[0];
            res.send({
                status: true
                , data: rows.map((row : any) => _rotations(row))
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

            const unqFolder : string = uuidv4();

            // Moves the uploaded log files into a watched folder by the Parser
            // The Parser then parses those logs, and that .json output to sent
            // to another watched folder to be uploaded to MySQL. 
            logs.forEach((log, index, array) => {
                log.mv(`/etc/logs/${unqFolder}/${log.name}`);
            });

            const k8sJob = kc.makeApiClient(k8s.BatchV1Api);
            const appParseJob : any = {
                metadata: {
                    name: `job-parse-${unqFolder}`
                    , labels: {
                        app: `job-${unqFolder}`, 
                    }
                }
                , spec: {
                    template: {
                        spec: {
                            /*subdomain: 'venerable-job-service'
                            ,*/ containers: [
                                {
                                    name: 'parser'
                                    , image: 'venerablenelson/projects:parser'
                                    , imagePullPolicy: 'Always'
                                    , command: ['wine', '/GuildWars2EliteInsights.exe', '-p', '-c', '/report.conf'].concat(logs.map(log=>`/etc/logs/${unqFolder}/${log.name}`))  // `/etc/logs/${unqFolder}/*`]
                                    // , command: ['ls', '/etc/logs']
                                    , volumeMounts: [{name: `logs`, mountPath: `/etc/logs`} /*, {name: `reports`, mountPath: `/etc/reports`} */]
                                }
                            ]
                            , volumes: [
                                {name: `logs`, persistentVolumeClaim: {claimName: "logs-pvc"}}
                                // , {name: `reports`, persistentVolumeClaim: {claimName: "reports-pvc"}}
                            ]
                            , restartPolicy: 'Never'
                            , imagePullSecrets: [
                                    {
                                        name: 'venerablenelson'
                                    }
                                ]
                        }
                    }
                    , ttlSecondsAfterFinished: 1
                    , backoffLimit: 1
                }
            }

            /*
            const k8sWatch : any = new k8s.Watch(kc);
            k8sWatch.watch('/apis/batch/v1/jobs', {}, 
                (type : any, apiObj : any, watchObj : any) => {
                    console.log("WATCHING", type, JSON.stringify(apiObj), JSON.stringify(watchObj))
                }, (err : any) => {console.log("ERROR!!!", JSON.stringify(err)); res.status(500).send("Error")}
            )
            .then((__res : any) => {
                console.log("?!?!?!?!", JSON.stringify(__res));
            })
            */


            k8sJob.createNamespacedJob('default', appParseJob)
                .then((_res : any) => {
                    const kc = new k8s.KubeConfig();
                    kc.loadFromDefault();
                    const k8sWatch : any = new k8s.Watch(kc);

                    k8sWatch.watch('/apis/batch/v1/jobs', {}, 
                        (type : any, apiObj : any, watchObj : any) => {
                            console.log("WATCHING", type, JSON.stringify(apiObj), JSON.stringify(watchObj))
                        }, (err : any) => {console.log("ERROR!!!", JSON.stringify(err), err); res.status(500).send("Error");}
                    )
                    .then((__res : any) => {
                        console.log("?!?!?!?!", JSON.stringify(__res));
                    })

                    /*
                    // console.log("Job Created!", JSON.stringify(k8sJob))
                    // console.log("Creating watcher!", JSON.stringify(k8sWatch))
                    console.log("AFTER JOB!", JSON.stringify(_res))
                    // console.log("KC", JSON.stringify(kc))

                    const k8sWatch : any = new k8s.Watch(kc);
                    k8sWatch.watch('/apis/batch/v1/jobs', {}
                    // k8sWatch.watch('/apis/batch/v1/watch/jobs', {}
                    // k8sWatch.watch('/api/v1/namespaces', {allowWatchBookmarks: true, }
                    , (type : any, apiObj : any, watchObj : any) => {
                        console.log("type && watchObj", type, watchObj);
                        if(type=="DELETED" && watchObj.object.metadata.name==`job-parse-${unqFolder}`) {

                            if(watchObj.object.status.succeeded==1) {
                                k8sApi.listNamespacedPod('default')
                                    .then((pods : any) => {
                                        console.log("PODS", pods);
                                        const pod : any = pods.body.items.filter((item : any) => item.metadata.labels.app).map((item : any) => item.metadata.name);
                                        console.log("POD", pod);

                                        const exec = new k8s.Exec(kc);
                                        exec.exec('default', pod, 'database', ['/bin/bash', 'process.sh', `/etc/logs/${unqFolder}`], process.stdout, process.stderr, process.stdin, true
                                                , (_status : any) => {
                                                    res.send(_status)
                                                })
                                                .catch((_execErr : any) => {
                                                    res.status(500).send("Error");
                                                })

                                    })
                                    .catch((_podErr : any) => {
                                        res.status(500).send("Error");
                                    })
                            } 
                            else {
                                res.status(500).send(JSON.stringify(watchObj));
                            }
                        }
                    }, (err:any) => {console.log("ERROR OCCURRED", err); res.status(500).send("Forbidden")})
                    .then((_req : any) => {
                        // Timeout the watcher...
                    })
                    */
                })
                .catch((e : any) => {
                    res.status(500).send("Error");
                })
        }
    } catch(error) {
        res.status(500).send(error);
    }
});

app.get('/reprocess', (req, res) => {

    k8sApi.listNamespacedPod('default')
        .then((pods : any) => {
            // console.log("PODS", pods);
            // pods.body.items.forEach((pod : any) => {console.log("POD", pod)});
            const pod : any = pods.body.items.filter((item : any) => {try{return item.metadata.labels.app==='venerable-report'} catch(err:any) {return false}}).map((item : any) => item.metadata.name);

            console.log("POD!!!", pod);

            const exec = new k8s.Exec(kc);
            // exec.exec('default', pod, 'parser', ['wine', '/GuildWars2EliteInsights.exe', '-p', '-c', '/report.conf', '$TARGET/$FILENAME'], process.stdout, process.stderr, process.stdin, true, (status : any) => res.send(JSON.stringify(status, null, 2)))
            exec.exec('default', pod, 'database', ['./reprocess.sh'], process.stdout, process.stderr, process.stdin, true, (status : any) => res.send(JSON.stringify(status, null, 2)))
        })
        .catch((_podErr : any) => {
            console.log("CATCH?", _podErr);
            res.send(_podErr);
        })

});


// Server setup
/*
export const server = app.listen(port, () => {
});
*/

const privateKey = fs.readFileSync(__dirname + '/../server.key', 'utf8');
const certificate = fs.readFileSync(__dirname + '/../server.crt', 'utf8');

console.log("privateKey", privateKey);
console.log("certificate", certificate);

export const server = https.createServer({
    key: privateKey
    , cert: certificate
}, app).listen(sport, () => {
    console.log("Express server listening to port " + sport);
});

export default app