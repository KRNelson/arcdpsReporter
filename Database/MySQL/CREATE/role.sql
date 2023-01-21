CREATE SCHEMA IF NOT EXISTS rol; 

/*----------------------------------------------------------------------------
-- rol contains information regarding specific roles that players have taken on during an encounter
------------------------------------------------------------------------------*/
CREATE TABLE IF NOT EXISTS rol.TPULROL_ROLES (
    LOG_SYS_NR CHAR(36),
	LOG_ACC_TE NVARCHAR(256),
	LOG_ROL_TE NVARCHAR(256)
);

