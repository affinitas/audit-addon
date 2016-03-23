
DROP SCHEMA IF EXISTS audit CASCADE ;

CREATE SCHEMA audit;
-- REVOKE ALL ON SCHEMA audit FROM public;
COMMENT ON SCHEMA audit IS '
  Out-of-table audit/history logging
  ===================================

  Audit data schema. Lots of information is available, its just a matter of how much you really want to record.
  See: http://www.postgresql.org/docs/9.4/static/functions-info.html'
;

-- type for audited events:
--   must include all possible valuse of "TG_OP" as listerd in PL/pgSQL trigger documentation
--   SNAPSHOT must be taken when a table has data on start/end of auditing
--   INSERT/UPDATE   the old row goes in rowdata
--   DELETE          the old row goes in rowdata
--   TRUCATE         write all rows (where?)
CREATE TYPE audit.etypes AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT' );

CREATE TABLE audit.events (
  nspname    TEXT NOT NULL,
  relname    TEXT NOT NULL,
  usename    TEXT NOT NULL,
  trans_ts   TIMESTAMPTZ NOT NULL ,
  stmnt_ts   TIMESTAMPTZ NOT NULL ,
  clock_ts   TIMESTAMPTZ NOT NULL ,
  trans_id   BIGINT NOT NULL ,
  operation  audit.etypes NOT NULL ,
  rowdata    JSONB,
  CONSTRAINT events_pkey PRIMARY KEY (trans_ts, trans_id)
);


-- REVOKE ALL ON audit.events FROM public;

COMMENT ON TABLE  audit.events           IS 'History of auditable actions on audited tables, from audit.if_modified_func()';
COMMENT ON COLUMN audit.events.nspname   IS 'database schema of the audited table';
COMMENT ON COLUMN audit.events.relname   IS 'name of the tabkle changed by this event';
COMMENT ON COLUMN audit.events.usename   IS 'Login / session user whose statement caused the audited event';
COMMENT ON COLUMN audit.events.trans_ts  IS 'Transaction start timestamp for tx in which audited event occurred (PK)';
COMMENT ON COLUMN audit.events.stmnt_ts  IS 'Statement start timestamp for tx in which audited event occurred';
COMMENT ON COLUMN audit.events.clock_ts  IS 'Wall clock time at which audited event''s trigger call occurred';
COMMENT ON COLUMN audit.events.trans_id  IS 'Identifier of transaction that made the change. May wrap, but unique paired with ts_tx. (PK)';
COMMENT ON COLUMN audit.events.operation IS 'event operation insert, delete, update or truncate';
COMMENT ON COLUMN audit.events.rowdata   IS 'Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';
-- COMMENT ON COLUMN audit.events.nodata  IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';
-- COMMENT ON COLUMN audit.events.query   IS 'Top-level query that caused this auditable event. May be more than one statement.';
-- COMMENT ON COLUMN audit.events.changed IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';
-- COMMENT ON COLUMN audit.events.appname IS 'postgres ''application_type'' set when this audit event occurred. Can be changed in-session by client.';
