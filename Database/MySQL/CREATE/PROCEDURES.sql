DELIMITER //
CREATE PROCEDURE log.importJSON(jsonObject JSON, id CHAR(36))
BEGIN

	DECLARE exit handler for SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);

		INSERT INTO log.TLOGERROR(LOG_SYS_NR, LOG_ERR_TE)
		VALUES(id, @full_error);
	END;

	SET @newID = id;
	
	INSERT INTO log.TLOGCAT(LOG_SYS_NR)
	VALUES(@newID);

	-- INSERT INTO log.TLOGFIL(LOG_SYS_NR, LOG_FIL_TE)
	-- VALUES(@newID, jsonObject->>'$.file');
	
	INSERT INTO rpt.ILOGELT_INSIGHTS(
		LOG_SYS_NR
		, LOG_ELI_VER
		, LOG_TRG_ID
		, LOG_EI_ID
		, LOG_FGT_NA
		, LOG_FGT_IC
		, LOG_ARC_VER
		, LOG_GW_VER
		, LOG_LANG_TE
		, LOG_LANG_NR
		, LOG_REC_TE
		, LOG_STR_DT
		, LOG_END_DT
		, LOG_DUR_DT
		, LOG_DUR_MS
		, LOG_STR_OFF
		, LOG_SUC_IR
		, LOG_CM_IR
		)
	VALUES(@newID
			,jsonObject->>'$.eliteInsightsVersion'
			,jsonObject->>'$.triggerID'
			,jsonObject->>'$.eiEncounterID'
			,jsonObject->>'$.fightName'
			,jsonObject->>'$.fightIcon'
			,jsonObject->>'$.arcVersion'
			,jsonObject->>'$.gW2Build'
			,jsonObject->>'$.language'
			,jsonObject->>'$.languageID'
			,jsonObject->>'$.recordedBy'
			,STR_TO_DATE(LEFT(jsonObject->>'$.timeStartStd', LENGTH(jsonObject->>'$.timeStartStd') - LENGTH(' +00:00')), '%Y-%m-%d %H:%i:%s')
			,STR_TO_DATE(LEFT(jsonObject->>'$.timeEndStd', LENGTH(jsonObject->>'$.timeEndStd') - LENGTH(' +00:00')), '%Y-%m-%d %H:%i:%s')
			,jsonObject->>'$.duration'
			,jsonObject->>'$.durationMS'
			,jsonObject->>'$.logStartOffset'
			,CASE (jsonObject->>'$.success') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
			,CASE (jsonObject->>'$.isCM') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
	);

	INSERT INTO rpt.IRPTACT_ACTORS(
		LOG_SYS_NR
		, LOG_ACT_NA
		, LOG_HLT_NR

		, LOG_CND_NR
		, LOG_CON_NR
		, LOG_HEL_NR
		, LOG_TOU_NR

		, LOG_HGT_NR
		, LOG_WID_NR
		, LOG_INS_ID
		)
		SELECT @newID AS LOG_SYS_NR
				,Actors.LOG_ACT_NA
				,Actors.LOG_HLT_NR

				,Actors.LOG_CND_NR
				,Actors.LOG_CON_NR
				,Actors.LOG_HEL_NR
				,Actors.LOG_TOU_NR

				,Actors.LOG_HGT_NR
				,Actors.LOG_WID_NR
				,Actors.LOG_INS_ID

		FROM JSON_TABLE(jsonObject->> '$.targets'
						,'$[*]' COLUMNS (
						 LOG_ACT_NA NVARCHAR(256) PATH '$.name'
						,LOG_HLT_NR INT PATH '$.totalHealth'

						,LOG_CND_NR INT PATH '$.condition'
						,LOG_CON_NR INT PATH '$.concentration'
						,LOG_HEL_NR INT PATH '$.healing'
						,LOG_TOU_NR INT PATH '$.toughness'

						,LOG_HGT_NR INT PATH '$.hitboxHeight'
						,LOG_WID_NR INT PATH '$.hitboxWidth'

						,LOG_INS_ID INT PATH '$.instanceID'
						)) AS Actors
		;


	INSERT INTO rpt.IRPTNPC_NPC (
		LOG_SYS_NR
		, LOG_ACT_NA
		, LOG_NPC_ID
		, LOG_INS_ID

		, LOG_FNL_NR
		, LOG_BRN_NR
		, LOG_FST_NR
		, LOG_LST_NR
		)
		SELECT @newID AS LOG_SYS_NR
				,NPCs.LOG_ACT_NA
				,NPCs.LOG_NPC_ID
				,NPCs.LOG_INS_ID

				,NPCs.LOG_FNL_NR
				,NPCs.LOG_BRN_NR
				,NPCs.LOG_FST_NR
				,NPCs.LOG_LST_NR
		FROM JSON_TABLE(jsonObject->> '$.targets'
						,'$[*]' COLUMNS (
						 LOG_ACT_NA NVARCHAR(256) PATH '$.name'
						,LOG_NPC_ID INT PATH '$.id'
						,LOG_INS_ID INT PATH '$.instanceID'

						,LOG_FNL_NR INT PATH '$.finalHealth'
						,LOG_BRN_NR FLOAT PATH '$.healthPercentBurned'
						,LOG_FST_NR INT PATH '$.firstAware'
						,LOG_LST_NR INT PATH '$.lastAware'
						)) AS NPCs;

	INSERT INTO rpt.IRPTTGT_TARGETS (
		LOG_SYS_NR
		, LOG_IDX_NR
		, LOG_NPC_ID
		, LOG_INS_ID
		)
		SELECT @newID AS LOG_SYS_NR
				,Targets.LOG_IDX_NR - 1
				,Targets.LOG_NPC_ID
				,Targets.LOG_INS_ID
		FROM JSON_TABLE(jsonObject->> '$.targets'
						,'$[*]' COLUMNS (
						 LOG_IDX_NR FOR ORDINALITY
						,LOG_NPC_ID INT PATH '$.id'
						,LOG_INS_ID INT PATH '$.instanceID'
						)) AS Targets;

	INSERT INTO rpt.IRPTPHS_PHASE (
		LOG_SYS_NR
		, LOG_IDX_NR
		, LOG_STR_NR
		, LOG_END_NR
		, LOG_NAM_TE
		, LOG_BRK_IR
		)
		SELECT @newID AS LOG_SYS_NR
				, Phases.LOG_IDX_NR - 1
				, Phases.LOG_STR_NR
				, Phases.LOG_END_NR
				, Phases.LOG_NAM_TE
				,CASE Phases.LOG_BRK_IR WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
		FROM JSON_TABLE(jsonObject->> '$.phases'
						,'$[*]' COLUMNS (
						 LOG_IDX_NR FOR ORDINALITY
						,LOG_STR_NR INT PATH '$.start'
						,LOG_END_NR INT PATH '$.end'
						,LOG_NAM_TE NVARCHAR(256) PATH '$.name'
						,LOG_BRK_IR NVARCHAR(256) PATH '$.breakbarPhase'
						)) AS Phases;

	INSERT INTO rpt.IRPTPHS_TARGETS (
		LOG_SYS_NR
		, LOG_IDX_NR
		, LOG_TGT_NR
		)
		SELECT @newID AS LOG_SYS_NR
				,Targets.LOG_IDX_NR - 1
				,Targets.LOG_TGT_NR
		FROM JSON_TABLE(jsonObject->> '$.phases'
						,'$[*]' COLUMNS (
						 LOG_IDX_NR FOR ORDINALITY
						,NESTED PATH '$.targets[*]' COLUMNS (
							 LOG_TGT_NR INT PATH '$'
						)
						)) AS Targets;

	INSERT INTO rpt.IRPTPHS_SUBPHASE (
		LOG_SYS_NR
		, LOG_IDX_NR
		, LOG_PHS_NR
		)
		SELECT @newID AS LOG_SYS_NR
				,Phases.LOG_IDX_NR - 1
				,Phases.LOG_PHS_NR
		FROM JSON_TABLE(jsonObject->> '$.phases'
						,'$[*]' COLUMNS (
						 LOG_IDX_NR FOR ORDINALITY
						,NESTED PATH '$.subPhases[*]' COLUMNS (
							 LOG_PHS_NR INT PATH '$'
						)
						)) AS Phases
		WHERE Phases.LOG_PHS_NR IS NOT NULL
		;

		/** BEGIN: SkillMap **/
		INSERT INTO rpt.IRPTSKL_SKL (
			LOG_SYS_NR
			,LOG_SKL_ID 
			)
			SELECT @newID AS LOG_SYS_NR
					, SkillIDs.LOG_SKL_ID
			FROM JSON_TABLE(JSON_KEYS(jsonObject->> '$.skillMap')
							,'$[*]' COLUMNS (
								LOG_SKL_ID CHAR(6) PATH '$'
							)) SkillIDs
		;

		INSERT INTO rpt.IRPTSKL_MAP (
			LOG_SYS_NR
			,LOG_SKL_ID 

			,LOG_SKL_NA -- string Name
			,LOG_AUT_IR -- bool AutoAttack
			,LOG_CRT_IR -- bool CanCrit
			,LOG_ICN_TE -- string Icon
			,LOG_SWP_IR -- bool IsSwap
			,LOG_INS_IR -- bool IsInstantCast
			,LOG_NOT_IR -- bool IsNotAccurate
			,LOG_CHL_IR -- bool ConversionBasedHealing
			,LOG_HHL_IR -- bool HybridHealing
			)
			SELECT @newID AS LOG_SYS_NR
					,SkillMap.LOG_SKL_ID AS LOG_SKL_ID

					, JSON_EXTRACT(SkillMap.Skill, '$.name') AS LOG_SKL_NA
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.autoAttack') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_AUT_IR
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.canCrit') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_CRT_IR
					, JSON_EXTRACT(SkillMap.Skill, '$.icon') AS LOG_ICN_TE
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.isSwap') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_SWP_IR
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.isInstantCast') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_INS_IR
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.isNotAccurate') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_NOT_IR
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.conversionBasedHealing') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_CHL_IR
					, CASE JSON_EXTRACT(SkillMap.Skill, '$.hybridHealing') WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END AS LOG_HHL_IR
		FROM (
			SELECT LOG_SKL_ID, JSON_EXTRACT(JSON_EXTRACT(jsonObject, '$.skillMap'), CONCAT('$."', LOG_SKL_ID, '"')) Skill
			FROM rpt.IRPTSKL_SKL SKL
			WHERE LOG_SYS_NR=@newID
		) SkillMap
		;
		/** END: SkillMap **/

		/** BEGIN: Players **/
	INSERT INTO rpt.IRPTACT_ACTORS(
		LOG_SYS_NR
		, LOG_ACT_NA
		, LOG_HLT_NR

		, LOG_CND_NR
		, LOG_CON_NR
		, LOG_HEL_NR
		, LOG_TOU_NR

		, LOG_HGT_NR
		, LOG_WID_NR
		, LOG_INS_ID
		)
		SELECT @newID AS LOG_SYS_NR
				,Actors.LOG_ACT_NA
				,Actors.LOG_HLT_NR

				,Actors.LOG_CND_NR
				,Actors.LOG_CON_NR
				,Actors.LOG_HEL_NR
				,Actors.LOG_TOU_NR

				,Actors.LOG_HGT_NR
				,Actors.LOG_WID_NR
				,Actors.LOG_INS_ID
		FROM JSON_TABLE(jsonObject->> '$.players'
						,'$[*]' COLUMNS (
						 LOG_ACT_NA NVARCHAR(256) PATH '$.name'
						,LOG_HLT_NR INT PATH '$.totalHealth'

						,LOG_CND_NR INT PATH '$.condition'
						,LOG_CON_NR INT PATH '$.concentration'
						,LOG_HEL_NR INT PATH '$.healing'
						,LOG_TOU_NR INT PATH '$.toughness'

						,LOG_HGT_NR INT PATH '$.hitboxHeight'
						,LOG_WID_NR INT PATH '$.hitboxWidth'

						,LOG_INS_ID INT PATH '$.instanceID'
						)) AS Actors;

	INSERT INTO rpt.IRPTPLY_PLAYERS (
		LOG_SYS_NR
		, LOG_ACC_NA
		, LOG_INS_ID
		, LOG_CHR_NA
		, LOG_GRP_NR
		, LOG_CMD_IR
		, LOG_PRO_NA 
		, LOG_NPC_IR
		, LOG_NOT_IR
		, LOG_GLD_NA 
		)
		SELECT @newID AS LOG_SYS_NR
				,Players.LOG_ACC_NA
				,Players.LOG_INS_ID
				,Players.LOG_CHR_NA
				,Players.LOG_GRP_NR
				,CASE Players.LOG_CMD_IR WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
				,Players.LOG_PRO_NA 
				,CASE Players.LOG_NPC_IR WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
				,CASE Players.LOG_NOT_IR WHEN 'true' THEN 1 WHEN 'false' THEN 0 ELSE NULL END
				,Players.LOG_GLD_NA 
		FROM JSON_TABLE(jsonObject->> '$.players'
						,'$[*]' COLUMNS (
						 LOG_ACC_NA NVARCHAR(256) PATH '$.account'
						,LOG_INS_ID INT PATH '$.instanceID'
						,LOG_CHR_NA NVARCHAR(256) PATH '$.name'
						,LOG_GRP_NR INT PATH '$.group'
						,LOG_CMD_IR NVARCHAR(256) PATH '$.hasCommanderTag'
						,LOG_PRO_NA NVARCHAR(256) PATH '$.profession'
						,LOG_NPC_IR NVARCHAR(256) PATH '$.friendlyNPC'
						,LOG_NOT_IR NVARCHAR(256) PATH '$.notInSquad'
						,LOG_GLD_NA NVARCHAR(256) PATH '$.guildID'
						)) AS Players;

	INSERT INTO rpt.IRPTPLY_DPSTARGETS (
		LOG_SYS_NR
		, LOG_ACC_NA
		, LOG_TGT_NR
		, LOG_PHS_NR

		, LOG_DPS_NR
		, LOG_DMG_NR 
		, LOG_CND_DPS_NR 
		, LOG_CND_DMG_NR
		, LOG_PWR_DPS_NR
		, LOG_PWR_DMG_NR
		, LOG_BRK_DMG_NR
		, LOG_ACT_DPS_NR
		, LOG_ACT_DMG_NR
		, LOG_ACT_CND_DPS_NR
		, LOG_ACT_CND_DMG_NR
		, LOG_ACT_PWR_DPS_NR
		, LOG_ACT_PWR_DMG_NR
		, LOG_ACT_BRK_DMG_NR
		)
		SELECT @newID AS LOG_SYS_NR
				,Players.LOG_ACC_NA
				,DPSTargets.LOG_TGT_NR - 1
				,DPS.LOG_PHS_NR - 1

				,DPS.LOG_DPS_NR
				,DPS.LOG_DMG_NR 
				,DPS.LOG_CND_DPS_NR 
				,DPS.LOG_CND_DMG_NR
				,DPS.LOG_PWR_DPS_NR
				,DPS.LOG_PWR_DMG_NR
				,DPS.LOG_BRK_DMG_NR
				,DPS.LOG_ACT_DPS_NR
				,DPS.LOG_ACT_DMG_NR
				,DPS.LOG_ACT_CND_DPS_NR
				,DPS.LOG_ACT_CND_DMG_NR
				,DPS.LOG_ACT_PWR_DPS_NR
				,DPS.LOG_ACT_PWR_DMG_NR
				,DPS.LOG_ACT_BRK_DMG_NR
				
		FROM JSON_TABLE(jsonObject->>'$.players'
				,'$[*]' COLUMNS(
					LOG_ACC_NA NVARCHAR(256) PATH '$.account'
					,LOG_TGT_TBL JSON PATH '$.dpsTargets'
			)) Players
			,JSON_TABLE(Players.LOG_TGT_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_TGT_NR FOR ORDINALITY
					,LOG_PHS_TBL JSON PATH '$'
			)) DPSTargets
			,JSON_TABLE(DPSTargets.LOG_PHS_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_PHS_NR FOR ORDINALITY
					,LOG_DPS_NR INT PATH '$.dps'
					,LOG_DMG_NR INT PATH '$.damage'
					,LOG_CND_DPS_NR INT PATH '$.condiDps'
					,LOG_CND_DMG_NR INT PATH '$.condiDamage'
					,LOG_PWR_DPS_NR INT PATH '$.powerDps'
					,LOG_PWR_DMG_NR INT PATH '$.powerDamage'
					,LOG_BRK_DMG_NR FLOAT PATH '$.breakbarDamage'
					,LOG_ACT_DPS_NR INT PATH '$.actorDps'
					,LOG_ACT_DMG_NR INT PATH '$.actorDamage'
					,LOG_ACT_CND_DPS_NR INT PATH '$.actorCondiDps'
					,LOG_ACT_CND_DMG_NR INT PATH '$.actorCondiDamage'
					,LOG_ACT_PWR_DPS_NR INT PATH '$.actorPowerDps'
					,LOG_ACT_PWR_DMG_NR INT PATH '$.actorPowerDamage'
					,LOG_ACT_BRK_DMG_NR INT PATH '$.actorBreakbarDamage'
				)) DPS
		;
		/** END: Players **/

		/** BEGIN: Mechanics **/
		INSERT INTO rpt.IRPTMCH_MECHANICS(LOG_SYS_NR, LOG_MCH_NA, LOG_DSC_TE)
		SELECT @newID AS LOG_SYS_NR
				,Mechanics.LOG_MCH_NA
				,Mechanics.LOG_DSC_TE
		FROM JSON_TABLE(jsonObject->>'$.mechanics'
				,'$[*]' COLUMNS(
					LOG_MCH_NA NVARCHAR(256) PATH '$.name'
					,LOG_DSC_TE NVARCHAR(256) PATH '$.description'
		)) Mechanics;
		
		INSERT INTO rpt.IRPTMCH_DATA(LOG_SYS_NR, LOG_MCH_NA, LOG_TIM_NR, LOG_ACT_NA)
		SELECT @newID AS LOG_SYS_NR
		        ,Mechanics.LOG_MCH_NA
				,Actors.LOG_TIM_NR
				,Actors.LOG_ACT_NA
		FROM JSON_TABLE(jsonObject->>'$.mechanics'
				,'$[*]' COLUMNS(
					LOG_MCH_NA NVARCHAR(256) PATH '$.name'
					,LOG_MCH_TBL JSON PATH '$.mechanicsData'
			)) Mechanics
			,JSON_TABLE(Mechanics.LOG_MCH_TBL->>'$'
				,'$[*]' COLUMNS(
					LOG_TIM_NR INT PATH '$.time'
					,LOG_ACT_NA NVARCHAR(256) PATH '$.actor'
			)) Actors;
		/** END: Mechanics **/

		INSERT INTO rpt.IRPTROT_ROTATION(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID, LOG_SKL_ID, LOG_CST_NR, LOG_DUR_NR, LOG_TIM_NR, LOG_QIK_NR)
		SELECT @newID AS LOG_SYS_NR
			 , Players.LOG_ACT_NA
			 , Players.LOG_INS_ID

			 , CONCAT('s', SkillList.LOG_SKL_ID) AS LOG_SKL_ID

			 , Skills.LOG_CST_NR
			 , Skills.LOG_DUR_NR
			 , Skills.LOG_TIM_NR
			 , Skills.LOG_QIK_NR
		FROM JSON_TABLE(jsonObject->>'$.players'
				,'$[*]' COLUMNS(
					LOG_ACT_NA NVARCHAR(256) PATH '$.name'
					,LOG_INS_ID INT PATH '$.instanceID'
					,LOG_ROT_TBL JSON PATH '$.rotation'
			)) Players
			,JSON_TABLE(Players.LOG_ROT_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_SKL_ID CHAR(6) PATH '$.id'
					,LOG_SKL_TBL JSON PATH '$.skills'
			)) SkillList
			,JSON_TABLE(SkillList.LOG_SKL_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_CST_NR INT PATH '$.castTime'
					,LOG_DUR_NR INT PATH '$.duration'
					,LOG_TIM_NR INT PATH '$.timeGained'
					,LOG_QIK_NR FLOAT PATH '$.quickness'
				)) Skills
		;

		INSERT INTO rpt.IRPTROT_ROTATION(LOG_SYS_NR, LOG_ACT_NA, LOG_INS_ID, LOG_SKL_ID, LOG_CST_NR, LOG_DUR_NR, LOG_TIM_NR, LOG_QIK_NR)
		SELECT @newID AS LOG_SYS_NR
			 , Targets.LOG_ACT_NA
			 , Targets.LOG_INS_ID

			 , CONCAT('s', SkillList.LOG_SKL_ID) AS LOG_SKL_ID

			 , Skills.LOG_CST_NR
			 , Skills.LOG_DUR_NR
			 , Skills.LOG_TIM_NR
			 , Skills.LOG_QIK_NR
		FROM JSON_TABLE(jsonObject->>'$.targets'
				,'$[*]' COLUMNS(
					LOG_ACT_NA NVARCHAR(256) PATH '$.name'
					,LOG_INS_ID INT PATH '$.instanceID'
					,LOG_ROT_TBL JSON PATH '$.rotation'
			)) Targets
			,JSON_TABLE(Targets.LOG_ROT_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_SKL_ID CHAR(6) PATH '$.id'
					,LOG_SKL_TBL JSON PATH '$.skills'
			)) SkillList
			,JSON_TABLE(SkillList.LOG_SKL_TBL->>'$'
				,'$[*]' COLUMNS(
					 LOG_CST_NR INT PATH '$.castTime'
					,LOG_DUR_NR INT PATH '$.duration'
					,LOG_TIM_NR INT PATH '$.timeGained'
					,LOG_QIK_NR FLOAT PATH '$.quickness'
				)) Skills
		;
END//

USE rpt
//

CREATE TRIGGER Import_JSON
	AFTER INSERT ON IRPTJSON
	FOR EACH ROW
BEGIN
	CALL log.importJSON(NEW.LOG_JSON_TE, NEW.LOG_SYS_ID);
END //

CREATE PROCEDURE web.importJson(jsonObject JSON)
BEGIN
	CALL log.importJSON(jsonObject);
END//

CREATE PROCEDURE web.getLogs()
BEGIN
	WITH Logs_CTE AS (
		SELECT LOG_SYS_NR
			 , LOG_ELI_VER
			 , LOG_TRG_ID
			 , LOG_EI_ID
			 , LOG_FGT_NA
			 , LOG_FGT_IC
			 , LOG_ARC_VER
			 , LOG_GW_VER
			 , LOG_LANG_TE
			 , LOG_LANG_NR
			 , LOG_REC_TE
			 , LOG_STR_DT
			 , LOG_END_DT
			 , LOG_DUR_DT
			 , LOG_DUR_MS
			 , LOG_STR_OFF
			 , LOG_SUC_IR
		     , LOG_CM_IR

		FROM rpt.ILOGELT_INSIGHTS
	)
	SELECT LOG_SYS_NR
		 , LOG_ELI_VER
		 , LOG_TRG_ID
		 , LOG_EI_ID
		 , LOG_FGT_NA
		 , LOG_FGT_IC
		 , LOG_ARC_VER
		 , LOG_GW_VER
		 , LOG_LANG_TE
		 , LOG_LANG_NR
		 , LOG_REC_TE
		 , LOG_STR_DT
		 , LOG_END_DT
		 , LOG_DUR_DT
		 , LOG_DUR_MS
		 , LOG_STR_OFF
		 , LOG_SUC_IR
	     , LOG_CM_IR

	FROM Logs_CTE
	;
END//

CREATE PROCEDURE web.postLogs(jsonObject JSON)
BEGIN
	WITH Logs_CTE AS (
		SELECT LOG_SYS_NR
			 , LOG_ELI_VER
			 , LOG_TRG_ID
			 , LOG_EI_ID
			 , LOG_FGT_NA
			 , LOG_FGT_IC
			 , LOG_ARC_VER
			 , LOG_GW_VER
			 , LOG_LANG_TE
			 , LOG_LANG_NR
			 , LOG_REC_TE
			 , LOG_STR_DT
			 , LOG_END_DT
			 , LOG_DUR_DT
			 , LOG_DUR_MS
			 , LOG_STR_OFF
			 , LOG_SUC_IR
		     , LOG_CM_IR
		FROM rpt.ILOGELT_INSIGHTS
	)
	SELECT LOG_SYS_NR
		 , LOG_ELI_VER
		 , LOG_TRG_ID
		 , LOG_EI_ID
		 , LOG_FGT_NA
		 , LOG_FGT_IC
		 , LOG_ARC_VER
		 , LOG_GW_VER
		 , LOG_LANG_TE
		 , LOG_LANG_NR
		 , LOG_REC_TE
		 , LOG_STR_DT
		 , LOG_END_DT
		 , LOG_DUR_DT
		 , LOG_DUR_MS
		 , LOG_STR_OFF
		 , LOG_SUC_IR
	     , LOG_CM_IR
	FROM Logs_CTE A01
	INNER JOIN JSON_TABLE(jsonObject->>'$.logs'
		, '$[*]' COLUMNS(
			LOG_SYS_NR CHAR(36) PATH '$.id'
		)) LOGS
		ON A01.LOG_SYS_NR = LOGS.LOG_SYS_NR
	;
END//

CREATE PROCEDURE web.getPlayers()
BEGIN
	SELECT LOG_ACC_NA
	FROM rpt.IRPTPLY_PLAYERS PLY
	GROUP BY LOG_ACC_NA;
END//

CREATE PROCEDURE web.postPlayers(jsonObject JSON)
BEGIN
	SELECT LOG_ACC_NA
	FROM rpt.IRPTPLY_PLAYERS PLY
	INNER JOIN JSON_TABLE(jsonObject->>'$.logs'
		, '$[*]' COLUMNS(
			LOG_SYS_NR CHAR(36) PATH '$.id'
		)) LOGS
		ON PLY.LOG_SYS_NR = LOGS.LOG_SYS_NR
	GROUP BY LOG_ACC_NA;
END//

CREATE PROCEDURE web.getMechanics()
BEGIN
	WITH Mechanics_CTE AS (
		SELECT ELT.LOG_SYS_NR, ELT.LOG_FGT_NA, ELT.LOG_FGT_IC, ELT.LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, PMCH.LOG_MCH_NA, LOG_DSC_TE, COUNT(*) AS TOT_NR
		FROM rpt.IRPTPLY_PLAYERS PLY 
		INNER JOIN rpt.IRPTMCH_DATA PMCH
			ON PLY.LOG_SYS_NR = PMCH.LOG_SYS_NR
			AND PLY.LOG_CHR_NA = PMCH.LOG_ACT_NA
		INNER JOIN rpt.IRPTMCH_MECHANICS MMCH
			ON PMCH.LOG_SYS_NR = MMCH.LOG_SYS_NR
			AND PMCH.LOG_MCH_NA = MMCH.LOG_MCH_NA
		INNER JOIN rpt.ILOGELT_INSIGHTS ELT
			ON PMCH.LOG_SYS_NR = ELT.LOG_SYS_NR
		GROUP BY ELT.LOG_SYS_NR, ELT.LOG_FGT_NA, ELT.LOG_FGT_IC, ELT.LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, PMCH.LOG_MCH_NA, LOG_DSC_TE
	)/*, MechanicsTotal_CTE AS (
		SELECT LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, GROUP_CONCAT(LOG_MCH_NA) AS LOG_MCH_TE, SUM(Total) AS TOT_NR, GROUP_CONCAT(LOG_MCH_NA, ':', Total) AS TOT_DSC_TE
		FROM Mechanics_CTE
		GROUP BY LOG_SYS_NR, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA
	)*/
	SELECT LOG_SYS_NR, LOG_FGT_NA, LOG_FGT_IC, LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, LOG_MCH_NA, LOG_DSC_TE, TOT_NR
	-- SELECT LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, LOG_MCH_TE, TOT_NR, TOT_DSC_TE
	FROM Mechanics_CTE
	ORDER BY LOG_STR_DT
	-- FROM MechanicsTotal_CTE
	;
END//

CREATE PROCEDURE web.postMechanics(jsonObject JSON)
BEGIN
	WITH Mechanics_CTE AS (
		SELECT ELT.LOG_SYS_NR, ELT.LOG_FGT_NA, ELT.LOG_FGT_IC, ELT.LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, PMCH.LOG_MCH_NA, LOG_DSC_TE, COUNT(*) AS TOT_NR
		FROM rpt.IRPTPLY_PLAYERS PLY 
		INNER JOIN rpt.IRPTMCH_DATA PMCH
			ON PLY.LOG_SYS_NR = PMCH.LOG_SYS_NR
			AND PLY.LOG_CHR_NA = PMCH.LOG_ACT_NA
		INNER JOIN rpt.IRPTMCH_MECHANICS MMCH
			ON PMCH.LOG_SYS_NR = MMCH.LOG_SYS_NR
			AND PMCH.LOG_MCH_NA = MMCH.LOG_MCH_NA
		INNER JOIN rpt.ILOGELT_INSIGHTS ELT
			ON PMCH.LOG_SYS_NR = ELT.LOG_SYS_NR
		GROUP BY ELT.LOG_SYS_NR, ELT.LOG_FGT_NA, ELT.LOG_FGT_IC, ELT.LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, PMCH.LOG_MCH_NA, LOG_DSC_TE
	)/*, MechanicsTotal_CTE AS (
		SELECT LOG_SYS_NR, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, GROUP_CONCAT(LOG_MCH_NA) AS LOG_MCH_TE, SUM(Total) AS TOT_NR, GROUP_CONCAT(LOG_MCH_NA, ':', Total) AS TOT_DSC_TE
		FROM Mechanics_CTE
		GROUP BY LOG_SYS_NR, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA
	)*/
	SELECT A01.LOG_SYS_NR, LOG_FGT_NA, LOG_FGT_IC, LOG_STR_DT, LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, LOG_MCH_NA, LOG_DSC_TE, TOT_NR
	-- SELECT LOG_ACC_NA, LOG_CHR_NA, LOG_PRO_NA, LOG_MCH_TE, TOT_NR, TOT_DSC_TE
	FROM Mechanics_CTE A01
	-- FROM MechanicsTotal_CTE A01
	INNER JOIN JSON_TABLE(jsonObject->>'$.logs'
		, '$[*]' COLUMNS(
			LOG_SYS_NR CHAR(36) PATH '$.id'
		)) LOGS
		ON A01.LOG_SYS_NR = LOGS.LOG_SYS_NR
	ORDER BY LOG_STR_DT
	;
END//
