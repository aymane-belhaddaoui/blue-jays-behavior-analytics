-- Execute after 01_load_sql_server.sql in the same database.
SELECT 'games' AS table_name, COUNT(*) AS row_count FROM dbo.games
UNION ALL SELECT 'batters', COUNT(*) FROM dbo.batters
UNION ALL SELECT 'plate_appearances', COUNT(*) FROM dbo.plate_appearances
UNION ALL SELECT 'pitches', COUNT(*) FROM dbo.pitches;
-- Expect no rows: missing parents.
SELECT p.pitch_id FROM dbo.pitches p LEFT JOIN dbo.plate_appearances a ON a.pa_id=p.pa_id WHERE a.pa_id IS NULL;
-- Expect no rows: game-level pitch-count disagreement.
SELECT g.game_id, g.pitch_count, COUNT(p.pitch_id) AS counted
FROM dbo.games g JOIN dbo.plate_appearances a ON a.game_id=g.game_id
JOIN dbo.pitches p ON p.pa_id=a.pa_id
GROUP BY g.game_id,g.pitch_count HAVING COUNT(p.pitch_id)<>g.pitch_count;
-- Expect 3 missing, 1 calculated, 5630 observed routines.
SELECT routine_source,COUNT(*) AS n FROM dbo.pitches GROUP BY routine_source;
-- Expect 1 unresolved PA and 1 inferred outcome (separate PAs).
SELECT SUM(1-pa_sequence_valid) AS unresolved, SUM(outcome_inferred) AS inferred FROM dbo.plate_appearances;
