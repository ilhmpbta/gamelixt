-- Drop indexes
DROP INDEX IF EXISTS idx_games_explore;
DROP INDEX IF EXISTS idx_list_explore;
DROP INDEX IF EXISTS idx_thread_hierarchy;
DROP INDEX IF EXISTS idx_thread_created;

-- create indexes
CREATE INDEX idx_games_explore ON Games (average_rating DESC, release_date DESC);
CREATE INDEX idx_list_explore ON List (created_at DESC);
CREATE INDEX idx_thread_hierarchy ON Thread (replying_to);
CREATE INDEX idx_thread_created ON Thread (created_at DESC);


-- Game exploration – sorting by rating & release date
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT game_id, title, average_rating, release_date, cover_url
FROM Games
ORDER BY average_rating DESC, release_date DESC
LIMIT 100;


-- List exploration – sorting by newest first
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT l.list_id, l.title, l.user_id, l.created_at,
       count_thread_vote(l.list_id) AS net_votes
FROM List l
ORDER BY l.created_at DESC
LIMIT 20;


-- Thread hierarchy – using the recursive function
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT * FROM get_thread_tree(
    (SELECT thread_id FROM Thread WHERE replying_to IS NULL ORDER BY random() LIMIT 1)
);


-- Latest parent threads (no reply) – sorted by newest
EXPLAIN (ANALYZE, BUFFERS, TIMING)
SELECT thread_id, user_id, comment, created_at
FROM Thread
WHERE replying_to IS NULL
ORDER BY created_at DESC
LIMIT 20;
