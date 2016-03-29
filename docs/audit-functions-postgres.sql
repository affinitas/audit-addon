
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $body$
DECLARE
  audit_row audit.events;
  query_text text;
  all_rows json[];
  anyrow RECORD;
BEGIN
  IF TG_WHEN <> 'AFTER' THEN
    RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
  END IF;

  audit_row = ROW (
              TG_TABLE_SCHEMA::TEXT,               -- nspname
              TG_TABLE_NAME::TEXT,                 -- relname
              session_user::TEXT,                  -- usename
              transaction_timestamp(),             -- trans_ts
              txid_current(),                      -- trans_id
              1,                                   -- trans_sq
              TG_OP,                               -- operation
              NULL                                 -- rowdata
  );

  IF    (TG_OP = 'UPDATE') THEN
    -- audit_row.rowdata := all_rows || row_to_json(OLD) || row_to_json(NEW);
    audit_row.rowdata = array_to_json(ARRAY[row_to_json(OLD), row_to_json(NEW)]);  -- save both rows
  ELSIF (TG_OP = 'DELETE') THEN
    audit_row.rowdata = row_to_json(OLD);                                            -- save old row
  ELSIF (TG_OP = 'INSERT') THEN
    audit_row.rowdata = row_to_json(NEW);                                            -- save new row
  ELSIF (TG_OP = 'TRUNCATE') THEN                                                    -- save all rows
    query_text = 'SELECT row_to_json(t) FROM (select *  from ' || quote_ident(TG_TABLE_SCHEMA) || '.' || quote_ident(TG_TABLE_NAME) ||') t';
    FOR anyrow IN EXECUTE query_text LOOP
        all_rows = all_rows || row_to_json(anyrow);
    END LOOP;
    audit_row.rowdata = array_to_json(all_rows);
  ELSE
    RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
    RETURN NULL;
  END IF;

  -- multiple events in the same transaction must be ordered
  LOOP
    BEGIN
      INSERT INTO audit.events VALUES (audit_row.*);
      EXIT; -- successful insert
    EXCEPTION WHEN unique_violation THEN
      -- add and loop to try the UPDATE again
      audit_row.trans_sq :=  audit_row.trans_sq + 1;
    END;
  END LOOP;
  RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER;

SET search_path = pg_catalog, public;


COMMENT ON FUNCTION audit.if_modified_func() IS $body$
Track changes to a table at the row level.
Note that the user name logged is the login role for the session. The audit trigger
cannot obtain the active role because it is reset by the SECURITY DEFINER invocation
of the audit trigger its self.
$body$;


CREATE OR REPLACE FUNCTION audit.audit_table(target_table regclass) RETURNS void AS $body$
DECLARE
  query_text text;
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || quote_ident(target_table::TEXT);
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || quote_ident(target_table::TEXT);

    query_text = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 quote_ident(target_table::TEXT) ||
                 ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();';
        RAISE NOTICE '%', query_text;
        EXECUTE query_text;

    query_text = 'CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON ' ||
                 quote_ident(target_table::TEXT) ||
                 ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func();';
        RAISE NOTICE '%', query_text;
        EXECUTE query_text;
END;
$body$
language 'plpgsql';

COMMENT ON FUNCTION audit.audit_table(regclass) IS $body$
Add auditing support to a table.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;
