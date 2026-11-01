-- Append-only ledger enforcement and the application login role.
-- Runs after 001_ledger_schema.sql on first init of an empty data volume.
BEGIN;

-- One function for every mutation path. Raising an exception aborts the
-- statement; the return value is never used when an exception fires.
-- TG_OP / TG_TABLE_NAME identify what was blocked. ERRCODE 'LA001' is a
-- user-defined SQLSTATE (class LA) so asyncpg/Python can catch a ledger
-- refusal without treating every DatabaseError as a bug.
CREATE FUNCTION ledger.reject_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'ledger tables are append-only: blocked % on %',
        TG_OP, TG_TABLE_NAME
        USING ERRCODE = 'LA001';
END;
$$;

-- Row-level: fires once per affected row on UPDATE or DELETE.
CREATE TRIGGER sportsbooks_append_only
    BEFORE UPDATE OR DELETE ON ledger.sportsbooks
    FOR EACH ROW
    EXECUTE FUNCTION ledger.reject_mutation();

CREATE TRIGGER games_append_only
    BEFORE UPDATE OR DELETE ON ledger.games
    FOR EACH ROW
    EXECUTE FUNCTION ledger.reject_mutation();

-- TRUNCATE cannot use the row-level triggers above. Per CREATE TRIGGER:
-- (1) a TRUNCATE trigger must be FOR EACH STATEMENT — row-level is not
-- allowed; (2) TRUNCATE does not scan or delete rows one by one, so it
-- never fires ON DELETE triggers. Without these, TRUNCATE would empty
-- the table while bypassing append-only.
CREATE TRIGGER sportsbooks_append_only_truncate
    BEFORE TRUNCATE ON ledger.sportsbooks
    FOR EACH STATEMENT
    EXECUTE FUNCTION ledger.reject_mutation();

CREATE TRIGGER games_append_only_truncate
    BEFORE TRUNCATE ON ledger.games
    FOR EACH STATEMENT
    EXECUTE FUNCTION ledger.reject_mutation();

-- Application role: login allowed, ledger read and append only.
-- No password here — .sql files cannot read Compose env vars. The
-- password is set later by db/migrations/900_app_login.sh from
-- LEDGER_APP_PASSWORD.
CREATE ROLE ledger_app LOGIN;

GRANT USAGE ON SCHEMA ledger TO ledger_app;
GRANT SELECT, INSERT ON TABLE ledger.sportsbooks, ledger.games TO ledger_app;

-- Future tables in ledger (e.g. game_state_events in 003) inherit these
-- grants automatically — but only when created by the same role that
-- runs this statement. Init scripts run as POSTGRES_USER (odds), which
-- also owns 001's tables, so that catch is satisfied for migrations.
-- A table created by another role would still need an explicit GRANT.
ALTER DEFAULT PRIVILEGES IN SCHEMA ledger
    GRANT SELECT, INSERT ON TABLES TO ledger_app;

COMMIT;
