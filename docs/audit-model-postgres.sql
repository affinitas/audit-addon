DROP SCHEMA IF EXISTS audit CASCADE;

CREATE SCHEMA audit;
REVOKE ALL ON SCHEMA audit FROM PUBLIC;
COMMENT ON SCHEMA audit IS '
  Out-of-table audit/history logging
  Audit application schema.
  Basic concept is taken from http://www.postgresql.org/docs/9.4/static/functions-info.html';

CREATE TYPE audit.op_types AS ENUM ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'SNAPSHOT' );
COMMENT ON TYPE audit.op_types IS '
The operation types for audited events. They must include all possible values
of "TG_OP" as listed in the PL/pgSQL trigger documentation
- INSERT   the new row is in rowdata
- UPDATE   both rows go in rowdata OLD first, NEW second
- DELETE   the old row is in rowdata
- TRUCATE  save all rows into rowdata
- SNAPSHOT must be taken when a table has already/still data on start/end of auditing
';


CREATE TABLE audit.events (
  nspname   TEXT           NOT NULL,
  relname   TEXT           NOT NULL,
  usename   TEXT           NOT NULL,
  trans_ts  TIMESTAMPTZ    NOT NULL,
  trans_id  BIGINT         NOT NULL,
  trans_sq  INTEGER        NOT NULL,
  operation audit.op_types NOT NULL,
  rowdata   JSONB,
  CONSTRAINT events_pkey PRIMARY KEY (trans_ts, trans_id, trans_sq)  -- TODO: find optimal order
);

REVOKE ALL ON audit.events FROM PUBLIC;

COMMENT ON TABLE audit.events IS 'History of auditable actions on audited tables, from audit.if_modified_func()';
COMMENT ON COLUMN audit.events.nspname IS 'database schema name of the audited table';
COMMENT ON COLUMN audit.events.relname IS 'name of the table changed by this event';
COMMENT ON COLUMN audit.events.usename IS 'Session user whose statement caused the audited event'; -- TODO: is this what we need?
COMMENT ON COLUMN audit.events.trans_ts IS 'Transaction timestamp for tx in which audited event occurred (PK)';
COMMENT ON COLUMN audit.events.trans_id IS 'Identifier of transaction that made the change. (PK)';
COMMENT ON COLUMN audit.events.trans_sq IS 'make multi-row-transactions unique. (PK)';
COMMENT ON COLUMN audit.events.operation IS 'event operation of type audit.op_types';
COMMENT ON COLUMN audit.events.rowdata IS 'Old and new rows affected by this event';
-- COMMENT ON COLUMN audit.events.stmnt_ts  IS 'Statement start timestamp for tx in which audited event occurred';
-- COMMENT ON COLUMN audit.events.clock_ts  IS 'Wall clock time at which audited event''s trigger call occurred';
-- COMMENT ON COLUMN audit.events.nodata  IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';
-- COMMENT ON COLUMN audit.events.query   IS 'Top-level query that caused this auditable event. May be more than one statement.';
-- COMMENT ON COLUMN audit.events.changed IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';
-- COMMENT ON COLUMN audit.events.appname IS 'postgres ''application_type'' set when this audit event occurred. Can be changed in-session by client.';
