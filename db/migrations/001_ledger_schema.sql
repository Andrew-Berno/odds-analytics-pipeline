BEGIN;

CREATE SCHEMA ledger;

CREATE TABLE ledger.sportsbooks (
    sportsbook_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_key text NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT sportsbooks_book_key_unique UNIQUE (book_key),
    CONSTRAINT sportsbooks_book_key_format CHECK (book_key ~ '^[a-z][a-z0-9_]{0,38}$')
);

CREATE TABLE ledger.games (
    game_id uuid PRIMARY KEY,
    home_team text NOT NULL,
    away_team text NOT NULL,
    starts_at timestamptz NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT games_teams_differ CHECK (home_team <> away_team)
);

COMMIT;
