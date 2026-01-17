Changes fact records in type1 to scd in type2
----------------------------------------------
WITH fct AS (
  SELECT
    customer_id, TIMESTAMP(snapshot_date) AS change_ts,
    status, tier, TO_HEX(MD5(TO_JSON_STRING(STRUCT(cola,colb..)))) as attr_hash 
  FROM raw.customer_daily_snapshot
),
chg AS (
  select * from (
    SELECT *, LAG(attr_hash OVER (PARTITION BY customer_id ORDER BY change_ts) AS prev_hash FROM fct
  ) t where prev_hash IS NULL OR attr_hash != prev_hash
)
scd2 as (
  select key, change_ts, next_change_ts, case when row_num = 1 then TRUE else FALSE end as IS_ACTIVE, cola,colb..
  from (select *, 
      lag(change_ts) OVER (PARTITION by customer_id order by change_ts desc) as next_change_ts,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_ts desc) AS row_num
      from chg t order by customer_id, change_ts desc 
  )
)
select * from scd2
---------------------------------------------------------------------------------------------------------------------
-- Absorbs incremental incoming changes into sch history, handling the first and only one upsert per key per timeperiod
-- Starts with closing active record of the updated data in history file, and then, inserting the incoming values for 
-- both new & updated keys 
--------------------------------------------------------------------------------------------------------------------------
SELECT ABS(FARM_FINGERPRINT(CONCAT('selvam/doraisamy'))) AS surrogate_id
--------------------------------------------------------------------------------------------------------------------------
-- step1: create staging.dim_customer_scd2
create or replace table staging.dim_customer_scd2 as 
select key, effective_from, '9999-12-31', TRUE, colA, colB ...
TO_HEX(MD5(TO_JSON_STRING(STRUCT(cola,colb..)))) as attr_hash 
from hist.dim_customer_scd2 where is_active = TRUE
--------------------------------------------------------------------------------------------------------------------------
-- step2: close old recs staging.dim_customer_scd2
MERGE staging.dim_customer_scd2 t
USING (
  SELECT latest.* FROM (
    SELECT ARRAY_AGG(struct(key, change_ts, hash(cola,colb..) as attr_hash) 
    ORDER BY change_ts DESC LIMIT 1)[OFFSET(0)] AS latest FROM raw.customer_chg_log t GROUP BY key)
) s ON t.customer_id = s.customer_id AND t.is_active = TRUE
WHEN MATCHED AND t.attr_hash != s.attr_hash and s.change_ts > t.effective_from THEN
  UPDATE SET t.effective_to = s.change_ts, t.is_active = FALSE
--------------------------------------------------------------------------------------------------------------------------
-- step3: upsert new recs staging.dim_customer_scd2
INSERT INTO staging.dim_customer_scd2
select s.* from (
  SELECT latest.* FROM (
    SELECT ARRAY_AGG(struct(key, change_ts, '9999-12-31', TRUE, cola, colb,..,hash(cola,colb..) as attr_hash) 
    ORDER BY change_ts DESC LIMIT 1)[OFFSET(0)] AS latest FROM raw.customer_chg_log t GROUP BY key)
) s left join staging.dim_customer_scd2 t ON t.key = s.key AND t.is_current = TRUE
WHERE t.key IS NULL OR t.attr_hash != s.attr_hash;
----------------------------------------------------------------------------------------------------------------------------
-- step 4: re-create gold as view
create or replace view gold.dim_customer_scd2 
select * from staging.dim_customer_scd2 
union all 
(select * from hist.dim_customer_scd2 
where is_active = false)
----------------------------------------------------------------------------------------------------------------------------
-- step 5: eod processing. Transfer from staging to hist
delete from hist.dim_customer_scd2
where is_active = true 

INSERT INTO hist.dim_customer_scd2
select * from staging.dim_customer_scd2

truncate staging
----------------------------------------------------------------------------------------------------------------------------

-- Next go back to step 1 for next day

-- Full ETL Processing layer

-- Bronze (Collects and converts to full/partial snaphot) 
--   - 2 types: Chglog, Snapshot 
--   - Prepare (Normalize to LH formats - creates norm_tbl)  
--       - norm_config - (Row per addon fld)  

-- Silver (Full refresh of daily ingested data)
--   - Compress (Dedup by date or timestamp)
--   - Index (Lookup or create LH PK)
--   - Link (Assign LH FK)
--   - CTModel (Map to Canonical Target model)
--       - ctm_cfg 
--         - tgt_id[tgt_tbl,tgt_fld],priority -> norm_id[norm_tbl,norm_fld]
--       - ctm_curr (tgt_id,tgt_pks,asof -> norm_id_picked)
 
-- Gold (Full refresh of daily processed data)
--   - Transform  
--   - Integrate 

-- EOD - Converts following to hist 
--   - key_curr 
--   - ctm_curr
--   - ctm_cfg_curr
--   - dim_tbl_curr
--   - fct_tbl_curr 
--   - trn_tbl_curr 


