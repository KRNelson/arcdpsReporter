/*---------------------------------------------------------------
-- log schema used for representing the log file being uploaded
----------------------------------------------------------------*/
CREATE TABLE IF NOT EXISTS rpt.IRPTJSON (
	LOG_SYS_ID CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    LOG_PRC_IR BIT DEFAULT(0),
    LOG_JSON_TE JSON
);

-- Log Catalog contains an ID for each log uploaded
CREATE TABLE IF NOT EXISTS log.TLOGCAT (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    AUD_DT DATETIME DEFAULT now(),
    FOREIGN KEY(LOG_SYS_NR) REFERENCES rpt.IRPTJSON(LOG_SYS_ID) 
);

-- Log Catalog contains an ID for each log uploaded
CREATE TABLE IF NOT EXISTS log.TLOGERROR (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    LOG_ERR_TE VARCHAR(1024)
);

-- Log File that was uploaded
/*
CREATE TABLE IF NOT EXISTS log.TLOGFIL (
	LOG_SYS_NR CHAR(36) PRIMARY KEY,
    LOG_FIL_TE NVARCHAR(256),
    -- LOG_HASH_TE CHAR(64),
    
    AUD_DT DATETIME DEFAULT now(),
    FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);
*/

/*--------------------------------------------------------------
-- rpt schema used for representing the results of the Elite Insights Parser 
----------------------------------------------------------------*/
-- Start with just storing the JSON.
-- TODO: Expand on tables as queries on the json develop. 

CREATE TABLE IF NOT EXISTS rpt.ILOGELT_INSIGHTS(
	LOG_SYS_NR CHAR(36) PRIMARY KEY
   ,LOG_ELI_VER CHAR(11) -- string EliteInsightsVersion
   ,LOG_TRG_ID INT -- int TriggerID
   ,LOG_EI_ID INT -- long EIEncounterID (The elite insight id of the log, indicates which encounter the log corresponds to)
   ,LOG_FGT_NA NVARCHAR(256) -- string FightName
   ,LOG_FGT_IC NVARCHAR(256) -- string FightIcon
   ,LOG_ARC_VER CHAR(12) -- string ArcVersion
   ,LOG_GW_VER VARCHAR(256) -- ulong GW2Build
   ,LOG_LANG_TE VARCHAR(256) -- string Language
   ,LOG_LANG_NR INT  -- byte LanguageID
   ,LOG_REC_TE NVARCHAR(256) -- string RecordedBy
   ,LOG_STR_DT DATETIME -- VARCHAR(256) -- string TimeStartStd
   ,LOG_END_DT DATETIME -- VARCHAR(256) -- string TimeEndStd
   ,LOG_DUR_DT VARCHAR(256) -- string Duration
   ,LOG_DUR_MS INT -- long DurationMS (The duration of the fight in ms)
   ,LOG_STR_OFF INT -- long LogStartOffset (Offset between fight start and log start)
   ,LOG_SUC_IR BOOL -- bool Success (The success status of the fight)
   ,LOG_CM_IR  BOOL -- bool IsCM (If the fight is in challenge mode)
   ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- JsonActor
CREATE TABLE IF NOT EXISTS rpt.IRPTACT_ACTORS (
	 LOG_SYS_NR CHAR(36)
	,LOG_ACT_NA VARCHAR(256) CHARACTER SET utf8mb4  -- string Name
    ,LOG_HLT_NR INT -- int TotalHealth

	,LOG_CND_NR INT -- uint Condition (Condition damage score)
    ,LOG_CON_NR INT -- uint Concentration (Concentration score)
	,LOG_HEL_NR INT -- uint Healing (Healing Power score)
	,LOG_TOU_NR INT -- uint Toughness (Toughness score)

    ,LOG_HGT_NR INT -- uint HitboxHeight
    ,LOG_WID_NR INT -- uint HitboxWidth
    ,LOG_INS_ID INT -- ushort InstanceID
    -- [JsonMinions]
    ,LOG_FAK_IR BOOL -- bool IsFake
    -- [JsonStatistics.JsonDPS]
    -- [JsonStatistics.JsonGameplayStatsAll]
    -- [JsonStatistics.JsonDefensesAll]
    -- [JsonStatistics.JsonDamageDist]
    -- [JsonStatistics.JsonRotation]
    -- 
    
    ,PRIMARY KEY(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- [JsonNPC] Targets
CREATE TABLE IF NOT EXISTS rpt.IRPTNPC_NPC (
	 LOG_SYS_NR CHAR(36)
	,LOG_ACT_NA VARCHAR(256) CHARACTER SET utf8mb4 -- string Name
    ,LOG_NPC_ID INT -- int Id
    ,LOG_INS_ID INT

    ,LOG_FNL_NR INT -- int FinalHealth
    ,LOG_BRN_NR FLOAT -- double HealthPercentBurned
    ,LOG_FST_NR INT -- int FirstAware
    ,LOG_LST_NR INT -- int LastAware
    -- [JsonBuffsUptime]
    ,LOG_ENY_IR BOOL -- bool EnemyPlayer
    -- [[double]] BreakbarPercents
   
    ,PRIMARY KEY(LOG_SYS_NR, LOG_NPC_ID, LOG_INS_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) REFERENCES rpt.IRPTACT_ACTORS(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTTGT_TARGETS (
    LOG_SYS_NR CHAR(36)
    ,LOG_IDX_NR INT
    ,LOG_NPC_ID INT
    ,LOG_INS_ID INT

    ,PRIMARY KEY(LOG_SYS_NR, LOG_IDX_NR)
    ,FOREIGN KEY(LOG_SYS_NR, LOG_NPC_ID, LOG_INS_ID) REFERENCES rpt.IRPTNPC_NPC(LOG_SYS_NR, LOG_NPC_ID, LOG_INS_ID) ON DELETE CASCADE
);

-- [JsonPhase] Phases
CREATE TABLE IF NOT EXISTS rpt.IRPTPHS_PHASE (
	 LOG_SYS_NR CHAR(36)
	,LOG_IDX_NR INT
    ,LOG_STR_NR INT -- long Start
    ,LOG_END_NR INT -- long End
    ,LOG_NAM_TE NVARCHAR(256) -- string Name
    -- [int] Targets (Index of targets tracked during the phase)
    -- [int] SubPhases (Index of subphases)
    ,LOG_BRK_IR BOOL -- bool BreakbarPhase

    ,PRIMARY KEY(LOG_SYS_NR, LOG_IDX_NR)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTPHS_TARGETS (
	 LOG_SYS_NR CHAR(36)

    ,LOG_IDX_NR INT
    ,LOG_TGT_NR INT

    ,PRIMARY KEY(LOG_SYS_NR, LOG_IDX_NR, LOG_TGT_NR)
    ,FOREIGN KEY(LOG_SYS_NR, LOG_IDX_NR) REFERENCES rpt.IRPTPHS_PHASE(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_TGT_NR) REFERENCES rpt.IRPTTGT_TARGETS(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTPHS_SUBPHASE (
	 LOG_SYS_NR CHAR(36)

    ,LOG_IDX_NR INT
    ,LOG_PHS_NR INT

    ,PRIMARY KEY(LOG_SYS_NR, LOG_IDX_NR, LOG_PHS_NR)
    ,FOREIGN KEY(LOG_SYS_NR, LOG_IDX_NR) REFERENCES rpt.IRPTPHS_PHASE(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_PHS_NR) REFERENCES rpt.IRPTPHS_PHASE(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS rpt.IRPTPLY_PLAYERS (
	 LOG_SYS_NR CHAR(36)
	,LOG_ACC_NA VARCHAR(256) CHARACTER SET utf8mb4 
    ,LOG_INS_ID INT

	,LOG_CHR_NA VARCHAR(256) CHARACTER SET utf8mb4 
	,LOG_GRP_NR INT
	,LOG_CMD_IR BOOL
	,LOG_PRO_NA VARCHAR(256) CHARACTER SET utf8mb4 
	,LOG_NPC_IR BOOL
	,LOG_NOT_IR BOOL
	,LOG_GLD_NA VARCHAR(256) CHARACTER SET utf8mb4 
    
    ,PRIMARY KEY(LOG_SYS_NR, LOG_ACC_NA)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_CHR_NA, LOG_INS_ID) REFERENCES rpt.IRPTACT_ACTORS(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTPLY_DPSTARGETS (
	 LOG_SYS_NR CHAR(36)
	,LOG_ACC_NA VARCHAR(256) CHARACTER SET utf8mb4 
    ,LOG_TGT_NR INT
    ,LOG_PHS_NR INT

    -- JsonDPS
    ,LOG_DPS_NR INT
    ,LOG_DMG_NR INT
    ,LOG_CND_DPS_NR INT
    ,LOG_CND_DMG_NR INT
    ,LOG_PWR_DPS_NR INT
    ,LOG_PWR_DMG_NR INT
    ,LOG_BRK_DMG_NR FLOAT
    ,LOG_ACT_DPS_NR INT
    ,LOG_ACT_DMG_NR INT
    ,LOG_ACT_CND_DPS_NR INT
    ,LOG_ACT_CND_DMG_NR INT
    ,LOG_ACT_PWR_DPS_NR INT
    ,LOG_ACT_PWR_DMG_NR INT
    ,LOG_ACT_BRK_DMG_NR INT
    
    ,PRIMARY KEY(LOG_SYS_NR, LOG_ACC_NA, LOG_TGT_NR, LOG_PHS_NR)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_ACC_NA) REFERENCES rpt.IRPTPLY_PLAYERS(LOG_SYS_NR, LOG_ACC_NA) ON DELETE CASCADE

    ,FOREIGN KEY(LOG_SYS_NR, LOG_TGT_NR) REFERENCES rpt.IRPTTGT_TARGETS(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_PHS_NR) REFERENCES rpt.IRPTPHS_PHASE(LOG_SYS_NR, LOG_IDX_NR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTMCH_MECHANICS (
    LOG_SYS_NR CHAR(36)
   ,LOG_MCH_NA NVARCHAR(256)
   ,LOG_DSC_TE NVARCHAR(256)
   ,PRIMARY KEY(LOG_SYS_NR, LOG_MCH_NA)
   ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTMCH_DATA (
    LOG_SYS_NR CHAR(36)
   ,LOG_MCH_NA NVARCHAR(256)
   ,LOG_TIM_NR INT
   ,LOG_ACT_NA VARCHAR(256) CHARACTER SET utf8mb4 
   -- ,LOG_INS_ID INT

   ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
   ,FOREIGN KEY(LOG_SYS_NR, LOG_MCH_NA) REFERENCES rpt.IRPTMCH_MECHANICS(LOG_SYS_NR, LOG_MCH_NA) ON DELETE CASCADE
   -- ,FOREIGN KEY(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) REFERENCES rpt.IRPTACT_ACTORS(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTSKL_SKL (
	 LOG_SYS_NR CHAR(36)
    ,LOG_SKL_ID CHAR(10)

    ,PRIMARY KEY(LOG_SYS_NR, LOG_SKL_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- <string, SkillDesc> SkillMap
CREATE TABLE IF NOT EXISTS rpt.IRPTSKL_MAP (
	 LOG_SYS_NR CHAR(36)
    ,LOG_SKL_ID CHAR(10)

    ,LOG_SKL_NA VARCHAR(256) CHARACTER SET utf8mb4 -- string Name
    ,LOG_AUT_IR BOOL -- bool AutoAttack
    ,LOG_CRT_IR BOOL -- bool CanCrit
    ,LOG_ICN_TE VARCHAR(256) -- string Icon
    ,LOG_SWP_IR BOOL -- bool IsSwap
    ,LOG_INS_IR BOOL -- bool IsInstantCast
    ,LOG_NOT_IR BOOL -- bool IsNotAccurate
    ,LOG_CHL_IR BOOL -- bool ConversionBasedHealing
    ,LOG_HHL_IR BOOL -- bool HybridHealing

    ,PRIMARY KEY(LOG_SYS_NR, LOG_SKL_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
    ,FOREIGN KEY(LOG_SYS_NR, LOG_SKL_ID) REFERENCES rpt.IRPTSKL_SKL(LOG_SYS_NR, LOG_SKL_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS rpt.IRPTROT_ROTATION (
    LOG_SYS_NR CHAR(36)
   ,LOG_ACT_NA VARCHAR(256) CHARACTER SET utf8mb4
   ,LOG_INS_ID INT
   ,LOG_SKL_ID CHAR(10) -- ID of the skill (SkillMap)

   -- JsonSkill
   ,LOG_CST_NR INT -- int CastTime
   ,LOG_DUR_NR INT -- int Duration
   ,LOG_TIM_NR INT -- int TimeGainted
   ,LOG_QIK_NR FLOAT -- double Quickness

   ,PRIMARY KEY(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID, LOG_SKL_ID, LOG_CST_NR)
   ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
   ,FOREIGN KEY(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) REFERENCES rpt.IRPTACT_ACTORS(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID) ON DELETE CASCADE
   ,FOREIGN KEY(LOG_SYS_NR, LOG_SKL_ID) REFERENCES rpt.IRPTSKL_MAP(LOG_SYS_NR, LOG_SKL_ID) ON DELETE CASCADE
);

/* TODO: Test below...
-- BuffMap
CREATE TABLE IF NOT EXISTS rpt.IRPTBUF_MAP (
	 LOG_SYS_NR CHAR(36)

    -- string Name
    -- BuffDesc Buff (IRPTBUF_DESC)

    ,PRIMARY KEY(LOG_SYS_NR, LOG_CHR_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- BuffDesc
CREATE TABLE IF NOT EXISTS rpt.IRPTBUF_DESC (
	 LOG_SYS_NR CHAR(36)

    -- string Name
    -- string Icon
    -- bool Stacking
    -- bool ConversionBasedHealing
    -- bool HybridHealing
    -- [string] Descriptions

    ,PRIMARY KEY(LOG_SYS_NR, LOG_CHR_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- DamageModMap
CREATE TABLE IF NOT EXISTS rpt.IRPTDMG_MAP (
	 LOG_SYS_NR CHAR(36)

    -- string Name
    -- DamageDesc Buff (IRPTDMG_DESC)

    ,PRIMARY KEY(LOG_SYS_NR, LOG_CHR_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);

-- DamageDesc
CREATE TABLE IF NOT EXISTS rpt.IRPTDMG_DESC (
	 LOG_SYS_NR CHAR(36)

    -- string Name
    -- string Icon
    -- string Description
    -- bool NonMultiplier
    -- bool SkillBased
    -- bool Approximate

    ,PRIMARY KEY(LOG_SYS_NR, LOG_CHR_ID)
    ,FOREIGN KEY(LOG_SYS_NR) REFERENCES log.TLOGCAT(LOG_SYS_NR) ON DELETE CASCADE
);
*/

-- TODO: PersonalBuffs
-- TODO: PresentInstanceBuffs
-- TODO: LogErrors

/*-----------------------------------------------------------------
-- gw2 schema used for containing values specific for the game
-------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS gw2.TWEBPROF_COLORS (
	ID VARCHAR(256),
    COLOR_LIGHTER VARCHAR(256),
    COLOR_LIGHT VARCHAR(256),
    COLOR_MEDIUM VARCHAR(256),
    COLOR_DARK VARCHAR(256),
    COLOR_WEB VARCHAR(256),
    COLOR_TEMPLATE VARCHAR(256)
);

INSERT INTO gw2.TWEBPROF_COLORS 
VALUES 
('Guardian'		,'#CFEEFD',	'#BCE8FD',	'#72C1D9',	'#186885',	'#8AF7F5'	,'{{g-color}}'),
('Revenant'		,'#EBC9C2',	'#E4AEA3',	'#D16E5A',	'#A66356',	'[TBA]'	    ,'{{re-color}}'),
('Warrior'		,'#FFF5BB',	'#FFF2A4',	'#FFD166',	'#CAAA2A',	'#F4983D'	,'{{w-color}}'),
('Engineer'		,'#E8C89F',	'#E8BC84',	'#D09C59',	'#87581D',	'#f4b362'	,'{{en-color}}'),
('Ranger'		,'#E2F6D1',	'#D2F6BC',	'#8CDC82',	'#67A833',	'#776F1B'	,'{{r-color}}'),
('Thief'		,'#E6D5D7',	'#DEC6C9',	'#C08F95',	'#974550',	'#974550'	,'{{t-color}}'),
('Elementalist'	,'#F6D2D1',	'#F6BEBC',	'#F68A87',	'#DC423E',	'#903B24'	,'{{e-color}}'),
('Mesmer'		,'#D7B2EA',	'#D09EEA',	'#B679D5',	'#69278A',	'#b679d5'	,'{{m-color}}'),
('Necromancer'	,'#D5EDE1',	'#BFE6D0',	'#52A76F',	'#2C9D5D',	'#456C40'	,'{{n-color}}'),
('Any'			,'#EEEEEE',	'#DDDDDD',	'#BBBBBB',	'#666666',	' '         ,'{{any-color}}');
