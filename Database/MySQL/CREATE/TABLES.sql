----------------------------------------------------------------
-- log schema used for representing the log file being uploaded
----------------------------------------------------------------

-- Log Catalog contains an ID for each log uploaded
CREATE TABLE IF NOT EXISTS log.TLOGCAT (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    AUD_DT DATETIME DEFAULT now()
);

-- Log File that was uploaded
CREATE TABLE IF NOT EXISTS log.TLOGFIL (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    LOG_FIL_TE NVARCHAR(256),
    
    AUD_DT DATETIME DEFAULT now(),
    FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- Used for matching identical logs in the catalog.
-- Only the Master Log will be used storing values in the database. 
CREATE TABLE IF NOT EXISTS log.TLOGMAT_BRIDGE (
	LOG_SYS_NR CHAR(36),
    LOG_SYS_MAT_NR CHAR(36),
    
    AUD_DT DATETIME DEFAULT now(),
    PRIMARY KEY(LOG_SYS_NR, LOG_SYS_MAT_NR),
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE,
	FOREIGN KEY(LOG_SYS_MAT_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);
----------------------------------------------------------------
-- smp schema used for representing the results of the Simple Parser
-- Values are determined based on Enums in the C++ code for the parser. 
----------------------------------------------------------------

-- Simple boss header details. 
CREATE TABLE IF NOT EXISTS smp.ILOGBOS_BOSS (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    
    -- DURATION
    LOG_DUR_NR BIGINT,
    -- ID
    LOG_BOS_ID INT,
    -- IS_CM
    LOG_CM_IR BIT,
    -- LOCATION
    LOG_LOC_NR VARCHAR(26),
    -- MAXHEALTH
    LOG_BOS_HP_NR BIGINT,
    -- NAME
    LOG_BOS_TE NVARCHAR(256),
    -- SUCCESS
    LOG_SUC_IR BIT,
    
    FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);


-- Simple Log Headers version details. 
CREATE TABLE IF NOT EXISTS smp.ILOGHED_HEADER (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    
    -- ARCDPS_VERSION
    LOG_ARC_VER_TE VARCHAR(100),
    -- REVISION
    LOG_REV_NR INT8,
    
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);


-- Simple log start/end times. 
CREATE TABLE IF NOT EXISTS smp.ILOGLOC_LOCALTIME (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    
    -- END
    LOG_END_NR BIGINT,
    -- LAST_EVENT
    LOG_LST_EVT_NR BIGINT,
    -- LOG_END
    LOG_LOG_END_NR BIGINT,
    -- REWARD
    LOG_RWD_NR BIGINT,
    -- START
    LOG_START_NR BIGINT,
    
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- Simple Parser players recorded in log. 
CREATE TABLE IF NOT EXISTS smp.ILOGPLY_PLAYERS (
	LOG_SYS_NR CHAR(36),
    
    -- ACCOUNT
    LOG_ACC_TE NVARCHAR(256),
    -- CHARACTER
    LOG_CHR_TE NVARCHAR(256),
    -- GUID
    LOG_GUID_TE VARCHAR(100),
    -- SUBGROUP
    LOG_SUB_NR INT,
    -- ADDR
    LOG_ACC_NR INT,
    
    PRIMARY KEY(LOG_SYS_NR, LOG_ACC_TE),
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE 
);

-- iff enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_IFF (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_IFF
VALUES
    (0,"IFF_FRIEND", "friend"),
    (1,"IFF_FOE", "foe"),
    (2,"IFF_UNKNOWN", "uncertain");


-- cbtresult enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_RESULT (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_RESULT
VALUES
    (0, "CBTR_NORMAL", "good physical hit"),
    (1, "CBTR_CRIT", "physical hit was crit"),
    (2, "CBTR_GLANCE", "physical hit was glance"),
    (3, "CBTR_BLOCK", "physical hit was blocked eg. mesmer shield 4"),
    (4, "CBTR_EVADE", "physical hit was evaded, eg. dodge or mesmer sword 2"),
    (5, "CBTR_INTERRUPT", "physical hit interrupted something"),
    (6, "CBTR_ABSORB", "physical hit was 'invlun' or absorbed eg. guardian elite"),
    (7, "CBTR_BLIND", "physical hit missed"),
    (8, "CBTR_KILLINGBLOW", "hit was killing hit"),
    (9, "CBTR_DOWNED", "hit was downing hit");

-- cbtactivation enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_ACTIVATION (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_ACTIVATION
VALUES
    (0, "ACTV_NONE", "not used - not this kind of event"),
    (1, "ACTV_NORMAL", "started skill activation without quickness"),
    (2, "ACTV_QUICKNESS", "started skill activation with quickness"),
    (3, "ACTV_CANCEL_FIRE", "stopped skill activation with reaching tooltip time"),
    (4, "ACTV_CANCEL_CANCEL", "stopped skill activation without reaching tooltip time"),
    (5, "ACTV_RESET", "animation completed fully");

-- cbtstatechange enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_STATECHANGE (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_STATECHANGE
VALUES
    (0, "CBTS_NONE","not used - not this kind of event"),
    (1, "CBTS_ENTERCOMBAT","src_agent entered combat, dst_agent is subgroup"),
    (2, "CBTS_EXITCOMBAT","src_agent left combat"),
    (3, "CBTS_CHANGEUP","src_agent is now alive"),
    (4, "CBTS_CHANGEDEAD","src_agent is now dead"),
    (5, "CBTS_CHANGEDOWN","src_agent is now downed"),
    (6, "CBTS_SPAWN","src_agent is now in game tracking range (not in realtime api)"),
    (7, "CBTS_DESPAWN","src_agent is no longer being tracked (not in realtime api)"),
    (8, "CBTS_HEALTHUPDATE","src_agent has reached a health marker. dst_agent = percent * 10000 (eg. 99.5% will be 9950) (not in realtime api)"),
    (9, "CBTS_LOGSTART","log start. value = server unix timestamp **uint32**. buff_dmg = local unix timestamp. src_agent = 0x637261 (arcdps id)"),
    (10, "CBTS_LOGEND","log end. value = server unix timestamp **uint32**. buff_dmg = local unix timestamp. src_agent = 0x637261 (arcdps id)"),
    (11, "CBTS_WEAPSWAP","src_agent swapped weapon set. dst_agent = current set id (0/1 water, 4/5 land)"),
    (12, "CBTS_MAXHEALTHUPDATE","src_agent has had it's maximum health changed. dst_agent = new max health (not in realtime api)"),
    (13, "CBTS_POINTOFVIEW","src_agent is agent of 'recording' player"),
    (14, "CBTS_LANGUAGE","src_agent is text language"),
    (15, "CBTS_GWBUILD","src_agent is game build"),
    (16, "CBTS_SHARDID","src_agent is sever shard id"),
    (17, "CBTS_REWARD","src_agent is self, dst_agent is reward id, value is reward type. these are the wiggly boxes that you get"),
    (18, "CBTS_BUFFINITIAL","combat event that will appear once per buff per agent on logging start (statechange==18, buff==18, normal cbtevent otherwise)"),
    (19, "CBTS_POSITION","src_agent changed, cast float* p = (float*)&dst_agent, access as x/y/z (float[3]) (not in realtime api)"),
    (20, "CBTS_VELOCITY","src_agent changed, cast float* v = (float*)&dst_agent, access as x/y/z (float[3]) (not in realtime api)"),
    (21, "CBTS_FACING","src_agent changed, cast float* f = (float*)&dst_agent, access as x/y (float[2]) (not in realtime api)"),
    (22, "CBTS_TEAMCHANGE","src_agent change, dst_agent new team id"),
    (23, "CBTS_ATTACKTARGET","src_agent is an attacktarget, dst_agent is the parent agent (gadget type), value is the current targetable state (not in realtime api)"),
    (24, "CBTS_TARGETABLE","dst_agent is new target-able state (0 = no, 1 = yes. default yes) (not in realtime api)"),
    (25, "CBTS_MAPID","src_agent is map id"),
    (26, "CBTS_REPLINFO","internal use, won't see anywhere"),
    (27, "CBTS_STACKACTIVE","src_agent is agent with buff, dst_agent is the stackid marked active"),
    (28, "CBTS_STACKRESET","src_agent is agent with buff, value is the duration to reset to (also marks inactive), pad61- is the stackid"),
    (29, "CBTS_GUILD","src_agent is agent, dst_agent through buff_dmg is 16 byte guid (client form, needs minor rearrange for api form)");

-- cbtbuffremove enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_BUFFREMOVE (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_BUFFREMOVE
VALUES
    (0, "CBTB_NONE","not used - not this kind of event"),
    (1, "CBTB_ALL","last/all stacks removed (sent by server)"),
    (2, "CBTB_SINGLE","single stack removed (sent by server). will happen for each stack on cleanse"),
    (3, "CBTB_MANUAL","single stack removed (auto by arc on ooc or all stack, ignore for strip/cleanse calc, use for in/out volume)");

-- cbtcustomskill enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_CUSTOMSKILL (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_CUSTOMSKILL
VALUES
    (1066, "CSK_RESURRECT", "not custom but important and unnamed"),
    (1175, "CSK_BANDAGE", "personal healing only"),
    (65001, "CSK_DODGE", "will occur in is_activation==normal event");

-- gwlanguage enum (see C++ code)
CREATE TABLE IF NOT EXISTS smp.TLOGCBT_LANGUAGE (
	LOG_ENU_NR INT PRIMARY KEY,
    LOG_ENU_TE VARCHAR(126),
    LOG_ENU_DSC VARCHAR(512)
);

INSERT INTO smp.TLOGCBT_LANGUAGE
VALUES
    (0, "GWL_ENG", "English"),
    (2, "GWL_FRE", "French"),
    (3, "GWL_GEM", "German"),
    (4, "GWL_SPA", "Spanish");


-- ArcDPS Combat log event parsing. 
CREATE TABLE IF NOT EXISTS smp.ILOGCBT_EVENTS (
	LOG_SYS_NR CHAR(36), -- Log System Number
    LOG_EVT_TIME_NR VARCHAR(36), -- Time
    LOG_EVT_SRC_AGENT_NR VARCHAR(36), -- unique ID
    
	LOG_EVT_DST_AGENT_NR VARCHAR(36), -- unique ID
    
    LOG_EVT_VAL_NR INT, -- Event specific
    
    LOG_EVT_BUF_DMG_NR INT, -- Estimated buff damage. 0 on application event
    
    LOG_EVT_OVRSTK_NR INT, -- Estimated overwritten stack duration of buff application
    LOG_EVT_SKILLID_NR INT, -- Skill ID
    LOG_EVT_SRCINST_NR INT, -- Agent map instance ID
    LOG_EVT_DST_INST_NR INT, -- Agent map instance ID
    LOG_EVT_SRC_MASTER_NR INT, -- Master source agent map instance id
    LOG_EVT_IFF_NR INT8, -- From IFF Enum (see C++ code)
    LOG_EVT_BUFF_NR INT8, -- Buff application, removal, or damage event.check
    LOG_EVT_RESULT_NR INT8, -- From cbtresult enum (see C++ code)
    LOG_EVT_ACTIVATION_NR INT8, -- From cbtactivation enum (see C++ code)
    LOG_EVT_BUFFREMOVE_NR INT8, -- buff removed. src=relevant, dst=caused it (for strips/cleanses). from cbtr enum
    LOG_EVT_NINETY_NR INT8, -- Source Agent Health was over 90%. 
    LOG_EVT_FIFTY_NR INT8, -- Source agent health was under 50%
    LOG_EVT_MOVING_NR INT8, -- Source agent was moving
    LOG_EVT_STATECHANGE_NR INT8, -- From cbtstatechange enum (see C++ code)
    LOG_EVT_FLANKING_NR INT8, -- Target was not facing source
    LOG_EVT_SHIELDS_NR INT8, -- All or part of damage was vs barrier/shield
    LOG_EVT_OFFCYCLE_NR INT8, -- Zero if buff damage happened during tick, non-zero otherwise. 
    
    PRIMARY KEY(LOG_SYS_NR, LOG_EVT_TIME_NR),
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);


-- Simple parser server time start/end. 
CREATE TABLE IF NOT EXISTS smp.ILOGSER_SERVERTIME (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    
    -- END
    LOG_END_NR INT,
    -- START
    LOG_START_NR INT,
    
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- Simple Arc version. 
CREATE TABLE IF NOT EXISTS smp.ILOGVER_SIMPLEARCVERSION (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    
    -- VERSION
    LOG_VER_TE VARCHAR(100),
    
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);


----------------------------------------------------------------
-- rpt schema used for representing the results of the Elite Insights Parser 
----------------------------------------------------------------

-- Start with just storing the JSON.
-- TODO: Expand on tables as queries on the json develop. 
CREATE TABLE IF NOT EXISTS rpt.IRPTJSON (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    LOG_JSON_TE JSON,
	FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);