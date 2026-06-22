-- ====================================================
-- seed.sql – Dummy data for GameLixt (no hardcoded UUIDs)
-- Run after schema: psql -d yourdb -f seed.sql
-- ====================================================

BEGIN;

-- 1. Users
INSERT INTO Users (username, email, password_hash, avatar_url) VALUES
  ('alice',   'alice@example.com',   '$2b$10$dummyhash1', NULL),
  ('bob',     'bob@example.com',     '$2b$10$dummyhash2', NULL),
  ('charlie', 'charlie@example.com', '$2b$10$dummyhash3', NULL),
  ('diana',   'diana@example.com',   '$2b$10$dummyhash4', NULL),
  ('eve',     'eve@example.com',     '$2b$10$dummyhash5', NULL);

-- 2. Games
INSERT INTO Games (title, developer, release_date, description, average_rating, cover_url) VALUES
  ('Cyber Quest',       'Neon Studios',    '2023-05-15', 'An open-world cyberpunk RPG.',                4.20, NULL),
  ('Stellar Frontier',  'Galaxy Games',    '2022-11-01', 'Explore the galaxy in this space sim.',        3.80, NULL),
  ('Dungeon Realms',    'Pixel Forge',     '2021-08-20', 'Classic dungeon crawler with modern twists.',  4.50, NULL),
  ('Arena Legends',     'Fight Club Inc',  '2024-01-10', 'Multiplayer online battle arena.',             3.90, NULL),
  ('Mystic Forest',     'Enchanted Dev',   '2020-03-05', 'A relaxing adventure in a magical forest.',    4.10, NULL),
  ('Speed Circuit',     'Turbo Team',      '2023-09-12', 'High-octane racing game.',                     4.00, NULL),
  ('Tactical Ops',      'StratCom',        '2022-04-18', 'Turn-based tactical shooter.',                 3.70, NULL),
  ('Ocean Depths',      'Deep Blue',       '2023-12-01', 'Underwater exploration and survival.',         4.30, NULL),
  ('Shadow Protocol',   'Stealth Ops',     '2021-11-11', 'Sneak your way through enemy lines.',          4.00, NULL),
  ('Farm Life',         'Green Thumb',     '2020-07-22', 'Build your dream farm.',                       4.60, NULL),
  ('Cosmic Clash',      'Star Fighters',   '2024-02-14', 'Fast-paced space combat.',                     3.50, NULL),
  ('Puzzle Worlds',     'Brain Games',     '2023-06-30', 'Challenging puzzle adventure.',                4.20, NULL),
  ('Vampire Hunt',      'Dark Arts',       '2022-10-31', 'Hunt creatures of the night.',                 3.90, NULL),
  ('Sky Racers',        'Cloud 9',         '2023-08-08', 'Airplane racing simulator.',                   3.80, NULL),
  ('Kingdom Wars',      'Crown Studios',   '2021-05-25', 'Medieval real-time strategy.',                 4.10, NULL);

-- 3. Genres
INSERT INTO Genres (genre_name, description) VALUES
  ('Action',      'Fast-paced combat and reflexes.'),
  ('RPG',         'Role-playing game with character progression.'),
  ('Adventure',   'Story-driven exploration.'),
  ('Simulation',  'Real-world simulation.'),
  ('Strategy',    'Tactical and strategic gameplay.'),
  ('Racing',      'Vehicle-based competition.'),
  ('Puzzle',      'Logic and problem solving.'),
  ('Horror',      'Survival horror and suspense.');

-- 4. Game_Genres (using subqueries by game title / genre name)
INSERT INTO Game_Genres (game_id, genre_id)
SELECT g.game_id, ge.genre_id
FROM (VALUES
  ('Cyber Quest',      'Action'),
  ('Cyber Quest',      'RPG'),
  ('Stellar Frontier', 'Adventure'),
  ('Stellar Frontier', 'Simulation'),
  ('Dungeon Realms',   'RPG'),
  ('Dungeon Realms',   'Adventure'),
  ('Arena Legends',    'Action'),
  ('Arena Legends',    'Strategy'),
  ('Mystic Forest',    'Adventure'),
  ('Mystic Forest',    'RPG'),
  ('Speed Circuit',    'Racing'),
  ('Tactical Ops',     'Strategy'),
  ('Ocean Depths',     'Adventure'),
  ('Ocean Depths',     'Simulation'),
  ('Shadow Protocol',  'Action'),
  ('Shadow Protocol',  'Horror'),
  ('Farm Life',        'Simulation'),
  ('Cosmic Clash',     'Action'),
  ('Puzzle Worlds',    'Puzzle'),
  ('Vampire Hunt',     'Horror'),
  ('Vampire Hunt',     'Action'),
  ('Sky Racers',       'Racing'),
  ('Kingdom Wars',     'Strategy')
) AS t(title, genre)
JOIN Games g ON g.title = t.title
JOIN Genres ge ON ge.genre_name = t.genre;

-- 5. Achievements (a few per game, using game title for lookup)
INSERT INTO Achievements (game_id, achievement_name, description)
SELECT g.game_id, a.name, a.achievement_desc
FROM (VALUES
  ('Cyber Quest',      'First Hack',         'Complete your first hack.'),
  ('Cyber Quest',      'Cyber Ninja',        'Finish a level without being detected.'),
  ('Stellar Frontier', 'Lift Off',           'Leave the first planet.'),
  ('Dungeon Realms',   'Skeleton Key',       'Open 10 locked chests.'),
  ('Dungeon Realms',   'Dragon Slayer',      'Defeat the dragon boss.'),
  ('Farm Life',        'Green Thumb',        'Plant 100 crops.'),
  ('Farm Life',        'Animal Whisperer',   'Pet all farm animals.'),
  ('Kingdom Wars',     'First Victory',      'Win a battle.'),
  ('Kingdom Wars',     'Castle Builder',     'Upgrade your castle to level 5.')
) AS a(title, name, achievement_desc)
JOIN Games g ON g.title = a.title;

-- 6. User_Library (each user adds a few games with various statuses)
INSERT INTO User_Library (user_id, game_id, play_status)
SELECT u.user_id, g.game_id, t.status
FROM (VALUES
  ('alice',   'Cyber Quest',      'Playing'),
  ('alice',   'Dungeon Realms',   'Completed'),
  ('alice',   'Mystic Forest',    'Plan to Play'),
  ('bob',     'Speed Circuit',    'Playing'),
  ('bob',     'Farm Life',        'Playing'),
  ('charlie', 'Ocean Depths',     'Completed'),
  ('charlie', 'Shadow Protocol',  'Dropped'),
  ('diana',   'Kingdom Wars',     'Playing'),
  ('diana',   'Puzzle Worlds',    'Completed'),
  ('diana',   'Cyber Quest',      'Plan to Play'),
  ('eve',     'Arena Legends',    'Playing'),
  ('eve',     'Vampire Hunt',     'Playing')
) AS t(username, game_title, status)
JOIN Users u ON u.username = t.username
JOIN Games g ON g.title = t.game_title;

-- 7. Reviews (only for games that are in the user's library, following the rule)
-- Using the procedure 'add_game_review' would be safer, but here we insert directly
INSERT INTO Reviews (user_id, game_id, rating, review_text)
SELECT u.user_id, g.game_id, r.rating, r.text
FROM (VALUES
  ('alice',   'Cyber Quest',      9.0, 'Loved the story and graphics!'),
  ('alice',   'Dungeon Realms',   8.5, 'Great dungeon design.'),
  ('bob',     'Farm Life',        9.5, 'So relaxing and cute.'),
  ('charlie', 'Ocean Depths',     8.0, 'Scary but beautiful.'),
  ('diana',   'Puzzle Worlds',    8.2, 'Hard but rewarding.'),
  ('eve',     'Arena Legends',    7.0, 'Good, but needs more heroes.')
) AS r(username, game_title, rating, text)
JOIN Users u ON u.username = r.username
JOIN Games g ON g.title = r.game_title;

-- 8. Lists (curated lists by users)
INSERT INTO List (user_id, title, description, list_cover_url)
SELECT u.user_id, l.title, l.list_desc, NULL
FROM (VALUES
  ('alice',   'Favorite RPGs',      'My top RPG picks'),
  ('bob',     'Relaxing Games',     'Games to wind down'),
  ('charlie', 'Horror Collection',  'Spooky titles I liked'),
  ('diana',   'Puzzle Mania',       'Brain teasers')
) AS l(username, title, list_desc)
JOIN Users u ON u.username = l.username;

-- 9. List_Items (populate lists using list title and game titles)
INSERT INTO List_Items (list_id, game_id)
SELECT li.list_id, g.game_id
FROM (VALUES
  ('Favorite RPGs',      'Cyber Quest'),
  ('Favorite RPGs',      'Dungeon Realms'),
  ('Favorite RPGs',      'Mystic Forest'),
  ('Relaxing Games',     'Farm Life'),
  ('Relaxing Games',     'Ocean Depths'),
  ('Horror Collection',  'Vampire Hunt'),
  ('Horror Collection',  'Shadow Protocol'),
  ('Puzzle Mania',       'Puzzle Worlds')
) AS i(list_title, game_title)
JOIN List li ON li.title = i.list_title
JOIN Games g ON g.title = i.game_title;

-- 10. Threads (main threads and replies)
-- Insert a couple of parent threads first, then replies using subqueries on thread's replying_to by ordering? 
-- We'll do it step by step with manual linking via subqueries on comment text (a bit fragile but okay for mock)
INSERT INTO Thread (user_id, replying_to, comment)
VALUES
  ((SELECT user_id FROM Users WHERE username='alice'), NULL, 'Cyber Quest is amazing, anyone else think so?'),
  ((SELECT user_id FROM Users WHERE username='bob'), NULL, 'What’s the best racing game out there?');

-- Now add replies to those threads (we can reference them by their comment text)
INSERT INTO Thread (user_id, replying_to, comment)
SELECT u.user_id, parent.thread_id, t.comment
FROM (VALUES
  ('charlie', 'Cyber Quest is amazing, anyone else think so?', 'Totally agree, the hacking mechanics are fun!'),
  ('diana',   'Cyber Quest is amazing, anyone else think so?', 'I wish it had more side quests.'),
  ('eve',     'What’s the best racing game out there?',       'Speed Circuit is my jam!')
) AS t(username, parent_comment, comment)
JOIN Users u ON u.username = t.username
JOIN Thread parent ON parent.comment = t.parent_comment AND parent.replying_to IS NULL;

-- 11. List_Votes (some votes on lists, using list title and username)
INSERT INTO List_Votes (list_id, user_id, vote_type)
SELECT li.list_id, u.user_id, v.vote
FROM (VALUES
  ('Favorite RPGs',    'bob',     true),
  ('Favorite RPGs',    'charlie', true),
  ('Relaxing Games',   'alice',   true),
  ('Relaxing Games',   'diana',   false),
  ('Horror Collection', 'eve',    true),
  ('Puzzle Mania',     'alice',   true)
) AS v(list_title, username, vote)
JOIN List li ON li.title = v.list_title
JOIN Users u ON u.username = v.username;

-- 12. Thread_Votes
INSERT INTO Thread_Votes (thread_id, user_id, vote_type)
SELECT t.thread_id, u.user_id, v.vote
FROM (VALUES
  ('Cyber Quest is amazing, anyone else think so?', 'bob',     true),
  ('Cyber Quest is amazing, anyone else think so?', 'charlie', true),
  ('What’s the best racing game out there?',        'alice',   true)
) AS v(parent_comment, username, vote)
JOIN Thread t ON t.comment = v.parent_comment
JOIN Users u ON u.username = v.username;

COMMIT;