DELIMITER //
CREATE PROCEDURE log.importJSON(jsonObject JSON)
BEGIN

	-- Check if the file has already been imported.
	-- First check that the hashs match. 
	SET @newID = uuid();
	
	INSERT INTO log.TLOGCAT(LOG_SYS_NR)
	VALUES(@newID);
	
	INSERT INTO rpt.ILOGELT_INSIGHTS(LOG_SYS_NR, LOG_CM_IR, LOG_SUC_IR, LOG_ELI_VER, LOG_TRG_ID, LOG_FGT_NA, LOG_FGT_IC, LOG_ARC_VER, LOG_GW_VER, LOG_LANG_TE, LOG_LANG_NR, LOG_REC_TE, LOG_STR_DT, LOG_END_DT, LOG_DUR_DT)
	VALUES(@newID
			,CASE (jsonObject->>'$.isCM') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
			,CASE (jsonObject->>'$.success') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
			,jsonObject->>'$.eliteInsightsVersion'
			,jsonObject->>'$.triggerID'
			,jsonObject->>'$.fightName'
			,jsonObject->>'$.fightIcon'
			,jsonObject->>'$.arcVersion'
			,jsonObject->>'$.gW2Build'
			,jsonObject->>'$.language'
			,jsonObject->>'$.languageID'
			,jsonObject->>'$.recordedBy'
			,jsonObject->>'$.timeStartStd'
			,jsonObject->>'$.timeEndStd'
			,jsonObject->>'$.duration'
	);
	
	INSERT INTO rpt.IRPTPLY_PLAYERS(LOG_SYS_NR, LOG_CHR_ID, LOG_ACT_ID, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, LOG_TAG_IR, LOG_GRP_NR, LOG_CND_NR, LOG_CON_NR, LOG_HEL_NR, LOG_TOU_NR)
	SELECT @newID AS LOG_SYS_NR
			,SHA(Players.LOG_CHR_NA) AS LOG_CHR_ID        
			,Players.LOG_ACT_ID
			,Players.LOG_ACC_NA
			,Players.LOG_CHR_NA
			,Players.LOG_PRO_NA
			,Players.LOG_TAG_IR
			,Players.LOG_GRP_NR
			,Players.LOG_CND_NR
			,Players.LOG_CON_NR
			,Players.LOG_HEL_NR
			,Players.LOG_TOU_NR
	FROM JSON_TABLE(jsonObject->> '$.players'
					,'$[*]' COLUMNS (
					LOG_ACT_ID INT PATH '$.instanceID'
					,LOG_ACC_NA NVARCHAR(256) PATH '$.account'
					,LOG_CHR_NA NVARCHAR(256) PATH '$.name'
					,LOG_PRO_NA NVARCHAR(256) PATH '$.profession'
					,LOG_TAG_IR BOOL PATH '$.hasCommanderTag'
					,LOG_GRP_NR INT PATH '$.group'
					,LOG_CND_NR INT PATH '$.condition'
					,LOG_CON_NR INT PATH '$.concentration'
					,LOG_HEL_NR INT PATH '$.healing'
					,LOG_TOU_NR INT PATH '$.toughness'
					)) AS Players;
	
	INSERT INTO rpt.IRPTMCH_MECHANICS(LOG_SYS_NR, LOG_MCH_ID, LOG_MCH_NA, LOG_DSC_TE)
	SELECT @newID AS LOG_SYS_NR
			,SHA(Mechanics.LOG_MCH_NA) AS LOG_MCH_ID
			,Mechanics.LOG_MCH_NA
			,Mechanics.LOG_DSC_TE
	FROM JSON_TABLE(jsonObject->>'$.mechanics'
			,'$[*]' COLUMNS(
				LOG_MCH_NA NVARCHAR(256) PATH '$.name'
				,LOG_DSC_TE NVARCHAR(256) PATH '$.description'
	)) Mechanics;
	
	INSERT INTO rpt.IRPTMCH_PLAYERS(LOG_SYS_NR, LOG_MCH_ID, LOG_CHR_ID, LOG_MCH_DT)
	SELECT @newID AS LOG_SYS_NR
			,SHA(Mechanics.LOG_MCH_NA) AS LOG_MCH_ID
			,SHA(Players.LOG_CHR_NA) AS LOG_CHR_ID
			,Players.LOG_MCH_DT             
	FROM JSON_TABLE(jsonObject->>'$.mechanics'
			,'$[*]' COLUMNS(
				LOG_MCH_NA NVARCHAR(256) PATH '$.name'
				,LOG_MCH_TBL JSON PATH '$.mechanicsData'
		)) Mechanics
		,JSON_TABLE(Mechanics.LOG_MCH_TBL->>'$'
			,'$[*]' COLUMNS(
				LOG_MCH_DT INT PATH '$.time'
				,LOG_CHR_NA NVARCHAR(256) PATH '$.actor'
		)) Players
	-- Needed to exclude boss mechanics from being recorded in the player mechanics table. 
	WHERE EXISTS(SELECT 1 FROM rpt.IRPTPLY_PLAYERS WHERE LOG_SYS_NR=@newID AND LOG_CHR_ID=SHA(Players.LOG_CHR_NA));

END//






























































CREATE PROCEDURE web.vue_details(intStart BIGINT, intEnd BIGINT)
BEGIN
	SELECT FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') AS 'Date' FROM smp.ILOGSER_SERVERTIME GROUP BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') ORDER BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d');
    
    SELECT Splits.LOG_SYS_NR AS Log, ServerTime.LOG_START_NR AS unixStart, ReportFiles.LOG_HTML_TE , dpsReport.LOG_JSON_TE AS Json_Log, ReportFiles.LOG_HTML_TE AS strFile
    FROM 
		(SELECT ServerTime.LOG_SYS_NR, ServerTime.LOG_START_NR, ServerTime.LOG_END_NR
		FROM smp.ILOGSER_SERVERTIME ServerTime
		INNER JOIN log.TLOGCAT Catalog
			ON ServerTime.LOG_SYS_NR=Catalog.LOG_SYS_NR
		WHERE ServerTime.LOG_START_NR > intStart
		  AND ServerTime.LOG_END_NR < intEnd) Splits 
    INNER JOIN smp.ILOGSER_SERVERTIME ServerTime 
		ON Splits.LOG_SYS_NR=ServerTime.LOG_SYS_NR
	INNER JOIN smp.ILOGBOS_BOSS Boss
		ON Boss.LOG_SYS_NR=Splits.LOG_SYS_NR
    INNER JOIN log.TLOGFIL Files
		ON Boss.LOG_SYS_NR=Files.LOG_SYS_NR
	LEFT JOIN rpt.TRPTFIL ReportFiles
		ON Files.LOG_SYS_NR=ReportFiles.LOG_SYS_NR
    LEFT JOIN rpt.IRPTJSON dpsReport
		ON Splits.LOG_SYS_NR=dpsReport.LOG_SYS_NR
    ORDER BY ServerTime.LOG_START_NR;
    
    SET SESSION group_concat_max_len=1000000;

	DROP TABLE IF EXISTS tblPlayers;
	CREATE TEMPORARY TABLE IF NOT EXISTS tblPlayers (
		LOG_SYS_NR CHAR(36),
		LOG_START_NR BIGINT,
		LOG_ACC_TE VARCHAR(256)
	);

	INSERT INTO tblPlayers
	SELECT Players.LOG_SYS_NR, ServerTime.LOG_START_NR, LOG_ACC_TE 
	FROM smp.ILOGPLY_PLAYERS Players 
	INNER JOIN smp.ILOGSER_SERVERTIME ServerTime
	ON Players.LOG_SYS_NR=ServerTime.LOG_SYS_NR
	WHERE ServerTime.LOG_START_NR > intStart
	  AND ServerTime.LOG_END_NR < intEnd;

	-- Use as parameters to function. 
	SET @strRow = 'LOG_SYS_NR';
	SET @strField = 'LOG_ACC_TE';
	SET @strTable = 'tblPlayers';
	SET @strOrder = 'LOG_START_NR';

	SET @strSQL = "SUM(CASE WHEN @field='@value' THEN 1 ELSE 0 END) AS \"@value\"";
	SET @strTemp = NULL;
	-- SET @foo hides the output of the executed string concate. 
	SET @strTemp = CONCAT("SET @foo = (SELECT @strTemp := GROUP_CONCAT(A01.strSQL SEPARATOR ', ') FROM (SELECT REPLACE(REPLACE(@strSQL, '@field', '", @strField, "'), '@value', ", @strField, ") AS strSQL FROM ", @strTable, " GROUP BY ", @strField, " ORDER BY COUNT(*) DESC, MIN(", @strOrder, "), ", @strField,") A01);");
	PREPARE strSQL FROM @strTemp;
	EXECUTE strSQL;
	SET @foo = (SELECT @strTemp:=CONCAT("SELECT Logs.LOG_SYS_NR AS Log, ", @strOrder, " AS Start, Bosses.LOG_BOS_TE AS Boss, ", @strTemp));
	SET @foo = (SELECT @strTemp:=CONCAT(" ", @strTemp, " FROM ", @strTable, " Logs INNER JOIN smp.ILOGBOS_BOSS Bosses ON Logs.LOG_SYS_NR=Bosses.LOG_SYS_NR GROUP BY Logs.", @strRow, ", Bosses.LOG_BOS_TE, ", @strOrder," ORDER BY ", @strOrder,";"));
	PREPARE strSQL FROM @strTemp;
	EXECUTE strSQL;

	WITH ReportPlayers AS (
		SELECT ReportJSON.LOG_SYS_NR, Players.LOG_ACC_NA, Players.LOG_PRO_NA, Players.LOG_CHR_NA -- ReportJSON.LOG_JSON_TE->>'$.players[*].name' AS PlayerNames
		FROM rpt.IRPTJSON ReportJSON, JSON_TABLE(ReportJSON.LOG_JSON_TE->>'$.players'
                      ,'$[*]' COLUMNS (
						LOG_ACC_NA NVARCHAR(256) PATH '$.account'
					   ,LOG_PRO_NA NVARCHAR(256) PATH '$.profession'
					   ,LOG_CHR_NA NVARCHAR(256) PATH '$.name'
                      )) AS Players
    )
	SELECT ReportPlayers.LOG_SYS_NR AS 'Log', 
		   ServerTime.LOG_START_NR AS 'Start', 
           ReportPlayers.LOG_ACC_NA AS 'Account', 
           ReportPlayers.LOG_PRO_NA AS 'Class', 
           Colors.COLOR_LIGHTER AS 'Color_lighter', 
           Colors.COLOR_LIGHT AS 'Color_light', 
           Colors.COLOR_MEDIUM AS 'Color_medium', 
           Colors.COLOR_DARK AS 'Color_dark'
	FROM ReportPlayers ReportPlayers 
	INNER JOIN smp.ILOGSER_SERVERTIME ServerTime 
	ON ReportPlayers.LOG_SYS_NR=ServerTime.LOG_SYS_NR

	LEFT JOIN gw2.TWEBPROF_COLORS Colors
	ON ReportPlayers.LOG_PRO_NA = Colors.ID

	WHERE ServerTime.LOG_START_NR>intStart
	  AND ServerTime.LOG_END_NR<intEnd 
	GROUP BY ReportPlayers.LOG_SYS_NR, ServerTime.LOG_START_NR, ReportPlayers.LOG_ACC_NA, ReportPlayers.LOG_PRO_NA, Colors.COLOR_MEDIUM, Colors.COLOR_DARK -- ,iconUrls.Icon, iconUrls.Icon_Big
	ORDER BY ServerTime.LOG_START_NR;

	SELECT Players.LOG_SYS_NR AS 'Log', Players.LOG_ACC_TE AS 'Account', CASE WHEN Roles.LOG_ROL_TE IS NULL THEN 'None' ELSE Roles.LOG_ROL_TE END AS 'Role'
	FROM tblPlayers Players
	LEFT JOIN rol.TPULROL_ROLES Roles 
	ON  Roles.LOG_SYS_NR=Players.LOG_SYS_NR
	AND Roles.LOG_ACC_TE=Players.LOG_ACC_TE;
    
    SELECT Players.LOG_ACC_TE AS 'Account', FROM_UNIXTIME(ServerTime.LOG_START_NR, '%Y-%m-%d') AS 'Date'
    FROM (
		SELECT LOG_ACC_TE
		FROM tblPlayers
		GROUP BY LOG_ACC_TE) Players
	INNER JOIN smp.ILOGPLY_PLAYERS LoggedPlayers
		ON Players.LOG_ACC_TE=LoggedPlayers.LOG_ACC_TE 
	INNER JOIN smp.ILOGSER_SERVERTIME ServerTime
		ON LoggedPlayers.LOG_SYS_NR=ServerTime.LOG_SYS_NR
	GROUP BY Players.LOG_ACC_TE, FROM_UNIXTIME(ServerTime.LOG_START_NR, '%Y-%m-%d')
    ORDER BY Players.LOG_ACC_TE, FROM_UNIXTIME(ServerTime.LOG_START_NR, '%Y-%m-%d');

	DROP TABLE IF EXISTS tblPlayers;
END//

CREATE PROCEDURE web.getAllStartDates()
BEGIN
	SELECT FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') AS 'Date' FROM smp.ILOGSER_SERVERTIME GROUP BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') ORDER BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d');
END//

CREATE PROCEDURE web.vue_attendence(jsonObject JSON)
BEGIN
	SELECT Players.LOG_ACC_TE, FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') AS 'Date', GROUP_CONCAT(DISTINCT ReportJSON.LOG_JSON_TE->>'$.fightName' ORDER BY ReportJSON.LOG_JSON_TE->>'$.fightName') AS 'Fights'
    FROM smp.ILOGSER_SERVERTIME ServerTime
    INNER JOIN smp.ILOGPLY_PLAYERS Players
    ON ServerTime.LOG_SYS_NR=Players.LOG_SYS_NR
    INNER JOIN rpt.IRPTJSON ReportJSON
    ON ServerTime.LOG_SYS_NR=ReportJSON.LOG_SYS_NR
	WHERE   ((JSON_EXTRACT(jsonObject, '$.selection')='NONE')
		OR (JSON_EXTRACT(jsonObject, '$.selection')='ACCOUNTS' AND Players.LOG_ACC_TE IN (SELECT Accounts.LOG_ACC_NA
											FROM JSON_TABLE(JSON_EXTRACT(jsonObject, '$.accounts') ,'$[*]' COLUMNS ( LOG_ACC_NA NVARCHAR(256) PATH '$' )) AS Accounts))
        OR (JSON_EXTRACT(jsonObject, '$.selection')='DATES' AND FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') IN (SELECT Dates.LOG_DATE
																  FROM JSON_TABLE(JSON_EXTRACT(jsonObject, '$.dates') ,'$[*]' COLUMNS ( LOG_DATE NVARCHAR(256) PATH '$' )) AS Dates))
        OR (JSON_EXTRACT(jsonObject, '$.selection')='BOTH' AND Players.LOG_ACC_TE IN (SELECT Accounts.LOG_ACC_NA
											FROM JSON_TABLE(JSON_EXTRACT(jsonObject, '$.accounts') ,'$[*]' COLUMNS ( LOG_ACC_NA NVARCHAR(256) PATH '$' )) AS Accounts) 
				 AND FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') IN (SELECT Dates.LOG_DATE
																 FROM JSON_TABLE(JSON_EXTRACT(jsonObject, '$.dates') ,'$[*]' COLUMNS ( LOG_DATE NVARCHAR(256) PATH '$' )) AS Dates)))
		
		 AND (NOT JSON_CONTAINS(jsonObject, 'true', '$.exclusions.raids')      OR NOT EXISTS(SELECT 1 FROM rpt.TRPTBOS WHERE BOS_NAM_TE=ReportJSON.LOG_JSON_TE->>'$.fightName' AND BOS_TYP_CD=0))
         AND (NOT JSON_CONTAINS(jsonObject, 'true', '$.exclusions.strikes')    OR NOT EXISTS(SELECT 1 FROM rpt.TRPTBOS WHERE BOS_NAM_TE=ReportJSON.LOG_JSON_TE->>'$.fightName' AND BOS_TYP_CD=1))
		 AND (NOT JSON_CONTAINS(jsonObject, 'true', '$.exclusions.fractals')   OR NOT EXISTS(SELECT 1 FROM rpt.TRPTBOS WHERE BOS_NAM_TE=ReportJSON.LOG_JSON_TE->>'$.fightName' AND BOS_TYP_CD=2))   
         AND (NOT JSON_CONTAINS(jsonObject, 'true', '$.exclusions.others')     OR NOT EXISTS(SELECT 1 FROM rpt.TRPTBOS WHERE BOS_NAM_TE=ReportJSON.LOG_JSON_TE->>'$.fightName' AND BOS_TYP_CD=3))
		
    GROUP BY Players.LOG_ACC_TE, FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d')
    ORDER BY Players.LOG_ACC_TE, FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d');
END//

CREATE PROCEDURE web.importJson(jsonObject JSON)
BEGIN
	CALL log.importJSON(jsonObject);
END//