-- INDEXING: Mempercepat /game (sorting berdasarkan rating dan tanggal rilis)
CREATE INDEX idx_games_explore ON Games (average_rating DESC, release_date DESC);

-- INDEXING: Mempercepat /list (sorting berdasarkan waktu pembuatan)
CREATE INDEX idx_list_explore ON List (created_at DESC);

-- INDEXING: Mempercepat pencarian parent thread vs child thread di /threads dan /threads/[id]
CREATE INDEX idx_thread_hierarchy ON Thread (replying_to);
CREATE INDEX idx_thread_created ON Thread (created_at DESC);
