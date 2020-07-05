DELIMITER //
CREATE PROCEDURE log.importJSON(jsonObject JSON)
BEGIN

	-- Check if the file has already been imported.
	-- First check that the hashs match. 
	IF NOT EXISTS(SELECT 1
			  FROM log.TLOGFIL
			  WHERE LOG_HASH_TE=jsonObject->>'$.file.hash')
	THEN
		SET @newID = uuid();
        
        INSERT INTO log.TLOGCAT(LOG_SYS_NR)
        VALUES(@newID);
        
        INSERT INTO log.TLOGFIL(LOG_SYS_NR, LOG_FIL_TE, LOG_HASH_TE)
        VALUES(@newID
              ,jsonObject->>'$.file.name'
              ,jsonObject->>'$.file.hash'
		);
        
		INSERT INTO rpt.IRPTJSON(LOG_SYS_NR, LOG_JSON_TE)
		VALUES(@newID
              ,jsonObject->>'$.parsers.elite'
		);
        
        INSERT INTO rpt.TRPTFIL(LOG_SYS_NR, LOG_LOG_TE, LOG_HTML_TE)
        VALUES(@newID
              ,jsonObject->>'$.file.log'
              ,jsonObject->>'$.file.html'
        );
        
        INSERT INTO smp.ILOGBOS_BOSS(LOG_SYS_NR, LOG_DUR_NR, LOG_BOS_ID, LOG_CM_IR, LOG_LOC_NR, LOG_BOS_HP_NR, LOG_BOS_TE, LOG_SUC_IR)
        VALUES(@newID
			  ,jsonObject->>'$.parsers.simple.boss.duration'
              ,jsonObject->>'$.parsers.simple.boss.id'
              ,CASE WHEN jsonObject->> '$.parsers.simple.boss.is_cm'="YES" THEN 1
			  WHEN jsonObject->> '$.parsers.simple.boss.is_cm'="NO" THEN 0
			  WHEN jsonObject->>'$.parsers.simple.boss.is_cm'="UNKNOWN" THEN NULL 
                    ELSE NULL END
              ,jsonObject->>'$.parsers.simple.boss.location'
              ,jsonObject->>'$.parsers.simple.boss.maxhealth'
              ,jsonObject->>'$.parsers.simple.boss.name'
              ,CASE WHEN jsonObject->>'$.parsers.simple.boss.success'='true' THEN 1
                    WHEN jsonObject->>'$.parsers.simple.boss.success'='false' THEN 0
                    ELSE NULL END
		);
        
        INSERT INTO smp.ILOGHED_HEADER(LOG_SYS_NR, LOG_ARC_VER_TE, LOG_REV_NR)
        VALUES(@newID
              ,jsonObject->>'$.parsers.simple.header.arcdps_version'
              ,jsonObject->>'$.parsers.simple.header.revision'
		);
        
        INSERT INTO smp.ILOGLOC_LOCALTIME(LOG_SYS_NR, LOG_END_NR, LOG_LST_EVT_NR, LOG_LOG_END_NR, LOG_RWD_NR, LOG_START_NR)
        VALUES(@newID
              ,jsonObject->>'$.parsers.simple.local_time.end'
              ,jsonObject->>'$.parsers.simple.local_time.last_event'
              ,jsonObject->>'$.parsers.simple.local_time.log_end'
              ,jsonObject->>'$.parsers.simple.local_time.reward' -- TODO: Confirm this field
              ,jsonObject->>'$.parsers.simple.local_time.start'
		);
        
        INSERT INTO smp.ILOGPLY_PLAYERS(LOG_SYS_NR, LOG_ACC_TE, LOG_CHR_TE, LOG_GUID_TE, LOG_SUB_NR)
        SELECT @newID AS LOG_SYS_NR, Players.LOG_ACC_TE, Players.LOG_CHR_TE, Players.LOG_GUID_TE, Players.LOG_SUB_NR
        FROM JSON_TABLE(jsonObject->>'$.parsers.simple.players'
                       ,'$[*]' COLUMNS(
						LOG_ACC_TE NVARCHAR(256) PATH '$.account'
					     ,LOG_CHR_TE NVARCHAR(256) PATH '$.character'
                                   ,LOG_GUID_TE NVARCHAR(100) PATH '$.guid'
                                   ,LOG_SUB_NR INT PATH '$.subgroup'
								)
                       ) AS Players;
        -- VALUES(@newID
        --       ,jsonObject->>'$.parsers.simple.players');
        
        INSERT INTO smp.ILOGSER_SERVERTIME(LOG_SYS_NR, LOG_END_NR, LOG_START_NR)
        VALUES(@newID
              ,jsonObject->>'$.parsers.simple.server_time.end'
              ,jsonObject->>'$.parsers.simple.server_time.start'
        );
        
        INSERT INTO smp.ILOGVER_SIMPLEARCVERSION(LOG_SYS_NR, LOG_VER_TE)
        VALUES(@newID
              ,jsonObject->>'$.parsers.simple.simpleArcParse.version'
        );
        
	END IF;

END//

CREATE PROCEDURE web.vue_details(intStart BIGINT, intEnd BIGINT)
BEGIN
	SELECT FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') AS 'Date' FROM smp.ilogser_servertime GROUP BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') ORDER BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d');
    
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
           -- iconUrls.Icon AS 'Icon', 
           -- iconUrls.Icon_Big ,
           Colors.COLOR_LIGHTER AS 'Color_lighter', 
           Colors.COLOR_LIGHT AS 'Color_light', 
           Colors.COLOR_MEDIUM AS 'Color_medium', 
           Colors.COLOR_DARK AS 'Color_dark'
	FROM ReportPlayers ReportPlayers 
	INNER JOIN smp.ILOGSER_SERVERTIME ServerTime 
	ON ReportPlayers.LOG_SYS_NR=ServerTime.LOG_SYS_NR

	-- LEFT JOIN 
	-- (SELECT PROFESSION_NAME AS 'Profession', PROFESSION_NAME AS 'Spec', BIG_ICON_URL AS 'Icon_Big', ICON_URL AS 'Icon' FROM gw2.TAPIPRO_PROFESSIONS
	-- UNION
	-- SELECT PROFESSION_NAME AS 'Profession', SPECIALIZATION_NAME AS 'Spec', BIG_ICON_URL AS 'Icon_Big', ICON_URL AS 'Icon' FROM gw2.TAPISPEC_SPECIALIZATIONS) iconUrls
	-- ON ReportPlayers.LOG_PRO_NA=iconUrls.Spec

	LEFT JOIN gw2.TWEBPROF_COLORS Colors
	ON ReportPlayers.LOG_PRO_NA = Colors.ID

	WHERE ServerTime.LOG_START_NR>intStart
	  AND ServerTime.LOG_END_NR<intEnd 
	GROUP BY ReportPlayers.LOG_SYS_NR, ServerTime.LOG_START_NR, ReportPlayers.LOG_ACC_NA, ReportPlayers.LOG_PRO_NA, Colors.COLOR_MEDIUM, Colors.COLOR_DARK -- ,iconUrls.Icon, iconUrls.Icon_Big
	ORDER BY ServerTIme.LOG_START_NR;

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
	INNER JOIN smp.ilogply_players LoggedPlayers
		ON Players.LOG_ACC_TE=LoggedPlayers.LOG_ACC_TE 
	INNER JOIN smp.ilogser_servertime ServerTime
		ON LoggedPlayers.LOG_SYS_NR=ServerTime.LOG_SYS_NR
	GROUP BY Players.LOG_ACC_TE, FROM_UNIXTIME(ServerTime.LOG_START_NR, '%Y-%m-%d')
    ORDER BY Players.LOG_ACC_TE, FROM_UNIXTIME(ServerTime.LOG_START_NR, '%Y-%m-%d');

	DROP TABLE IF EXISTS tblPlayers;
END//
-- CALL web.vue_details(UNIX_TIMESTAMP('2020-07-01 18:00:00'), UNIX_TIMESTAMP('2020-07-03 21:45:00'));
-- CALL web.vue_details(1593651600, 1593837900);

CREATE PROCEDURE web.getAllStartDates()
BEGIN
	SELECT FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') AS 'Date' FROM smp.ilogser_servertime GROUP BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d') ORDER BY FROM_UNIXTIME(LOG_START_NR, '%Y-%m-%d');
END//
-- CALL web.getAllStartDates()