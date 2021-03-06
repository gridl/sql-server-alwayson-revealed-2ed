--Set the secondary Availability Group to synchronous commit mode

ALTER AVAILABILITY GROUP App2Distributed 
MODIFY 
AVAILABILITY GROUP ON
'ag1' WITH  
   ( 
    LISTENER_URL = 'tcp://App2_App2Listen:5022',  
    AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, 
    FAILOVER_MODE = MANUAL, 
    SEEDING_MODE = MANUAL 
    ), 
'ag2' WITH  
  ( 
  LISTENER_URL = 'tcp://App2_App2Listen:5022', 
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, 
  FAILOVER_MODE = MANUAL, 
  SEEDING_MODE = MANUAL 
  );  

--Wait until the Availability Groups are synchronized

WHILE (SELECT COUNT(DISTINCT synchronization_state_desc) 
FROM (
	SELECT 
		ag.name
	  , drs.database_id
      , drs.group_id
      , drs.replica_id
      , drs.synchronization_state_desc
      , drs.end_of_log_lsn 
	FROM sys.dm_hadr_database_replica_states drs
	INNER JOIN sys.availability_groups ag
		ON drs.group_id = ag.group_id 
	WHERE ag.name = 'App2' 
		AND synchronization_state_desc = 'synchronized' 
	  ) a 
) > 1
BEGIN
	WAITFOR DELAY'00:00:05' ;
END

--Assign the primary Availability Group, the secondary role

ALTER AVAILABILITY GROUP App2Distributed SET (ROLE = SECONDARY) ;

--Force the failover

ALTER AVAILABILITY GROUP App2Distributed FORCE_FAILOVER_ALLOW_DATA_LOSS ;
