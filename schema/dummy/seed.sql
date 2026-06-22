-- ============================================================
-- seed.sql  –  Realistic test data for the game review schema
-- ============================================================

BEGIN;

DO $$
DECLARE
    -- arrays to hold generated UUIDs
    user_ids       uuid[] := '{}';
    game_ids       uuid[] := '{}';
    genre_ids      uuid[] := '{}';
    list_ids       uuid[] := '{}';
    thread_ids     uuid[] := '{}';
    ach_ids        uuid[] := '{}';   -- achievement IDs
    i              int;
    j              int;
    r_user         uuid;
    r_game         uuid;
    r_list         uuid;
    r_thread       uuid;
    r_status       varchar(20);
    r_text         text;
    r_rating       decimal(3,2);
    r_comment      text;
    r_count        int;
BEGIN
    RAISE NOTICE 'Starting seed generation...';

    -- 1. Users
    RAISE NOTICE 'Inserting 200 users...';
    FOR i IN 1..200 LOOP
        INSERT INTO Users (username, email, password_hash, join_date)
        VALUES (
            'user' || i,
            'user' || i || '@example.com',
            '$2a$10$abcdefghijklmnopqrstuvwxyz1234567890',
            NOW() - (random() * interval '365 days')
        )
        RETURNING user_id INTO r_user;
        user_ids := array_append(user_ids, r_user);
    END LOOP;

    -- 2. Games
    RAISE NOTICE 'Inserting 200 games...';
    FOR i IN 1..200 LOOP
        INSERT INTO Games (title, developer, release_date, description, average_rating, cover_url)
        VALUES (
            'Game Title ' || i,
            (ARRAY['Studio Alpha','Beta Corp','Gamma Games','Delta Soft','Epsilon Studios'])[ceil(random()*5)],
            ('2010-01-01'::date + (random() * 3650)::int * interval '1 day')::date,
            'Description for game ' || i || '. Lorem ipsum dolor sit amet.',
            0.00,
            'https://example.com/covers/game' || i || '.jpg'
        )
        RETURNING game_id INTO r_game;
        game_ids := array_append(game_ids, r_game);
    END LOOP;

    -- 3. Genres
    RAISE NOTICE 'Inserting 30 genres...';
    FOR i IN 1..30 LOOP
        INSERT INTO Genres (genre_name, description)
        VALUES (
            'Genre ' || i,
            'Description of genre ' || i
        )
        RETURNING genre_id INTO r_user;   -- reuse variable
        genre_ids := array_append(genre_ids, r_user);
    END LOOP;

    -- 4. Game_Genres (each game gets 1-3 random genres)
    RAISE NOTICE 'Linking games to genres...';
    FOREACH r_game IN ARRAY game_ids LOOP
        FOR j IN 1..(1 + floor(random()*3)::int) LOOP
            INSERT INTO Game_Genres (game_id, genre_id)
            SELECT r_game, genre_ids[ceil(random()*array_length(genre_ids,1))]
            ON CONFLICT DO NOTHING;  -- avoid duplicate pair
        END LOOP;
    END LOOP;

    -- 5. Achievements (2-5 per game)
    RAISE NOTICE 'Inserting achievements...';
    FOREACH r_game IN ARRAY game_ids LOOP
        r_count := 2 + floor(random()*4)::int;
        FOR j IN 1..r_count LOOP
            INSERT INTO Achievements (game_id, achievement_name, description)
            VALUES (
                r_game,
                'Achievement ' || j,
                'Unlock condition for achievement ' || j
            )
            RETURNING achievement_id INTO r_user;
            ach_ids := array_append(ach_ids, r_user);
        END LOOP;
    END LOOP;

    -- 6. User_Achievements (randomly assign some achievements to users)
    RAISE NOTICE 'Granting achievements to users...';
    FOREACH r_user IN ARRAY user_ids LOOP
        -- pick 0-5 random achievements for this user
        FOR r_user IN
            SELECT ach_ids[ceil(random()*array_length(ach_ids,1))]
            FROM generate_series(1, floor(random()*6)::int)
        LOOP
            INSERT INTO User_Achievements (user_id, achievement_id)
            VALUES (r_user, r_user)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;

    -- 7. User Library (3-15 games per user)
    RAISE NOTICE 'Populating user library...';
    FOREACH r_user IN ARRAY user_ids LOOP
        r_count := 3 + floor(random()*13)::int;  -- 3..15
        FOR r_game IN
            SELECT game_ids[ceil(random()*array_length(game_ids,1))]
            FROM generate_series(1, r_count)
        LOOP
            INSERT INTO User_Library (user_id, game_id, play_status)
            VALUES (
                r_user,
                r_game,
                (ARRAY['Playing','Completed','Dropped','Plan to Play'])[ceil(random()*4)]
            )
            ON CONFLICT (user_id, game_id) DO NOTHING;
        END LOOP;
    END LOOP;

    -- 8. Reviews (0-5 reviews per user, only for games in their library)
    RAISE NOTICE 'Writing reviews...';
    FOREACH r_user IN ARRAY user_ids LOOP
        r_count := floor(random()*6)::int;  -- 0..5
        FOR r_game IN
            SELECT game_id FROM User_Library WHERE user_id = r_user
            ORDER BY random()
            LIMIT r_count
        LOOP
            r_rating := round((random()*4 + 1)::numeric, 2);  -- 1.00..5.00
            r_text   := 'Sample review text for game. Rating: ' || r_rating;
            INSERT INTO Reviews (user_id, game_id, rating, review_text)
            VALUES (r_user, r_game, r_rating, r_text)
            ON CONFLICT (user_id, game_id) DO NOTHING;
        END LOOP;
    END LOOP;

    -- 9. Lists (100 lists)
    RAISE NOTICE 'Creating curated lists...';
    FOR i IN 1..100 LOOP
        r_user := user_ids[ceil(random()*array_length(user_ids,1))];
        INSERT INTO List (user_id, title, description, list_cover_url)
        VALUES (
            r_user,
            'Awesome List ' || i,
            'A curated list of favourite games.',
            'https://example.com/listcovers/list' || i || '.jpg'
        )
        RETURNING list_id INTO r_list;
        list_ids := array_append(list_ids, r_list);
    END LOOP;

    -- 10. List_Items (3-10 games per list, no duplicates)
    RAISE NOTICE 'Adding games to lists...';
    FOREACH r_list IN ARRAY list_ids LOOP
        r_count := 3 + floor(random()*8)::int;  -- 3..10
        FOR r_game IN
            SELECT game_ids[ceil(random()*array_length(game_ids,1))]
            FROM generate_series(1, r_count)
        LOOP
            INSERT INTO List_Items (list_id, game_id)
            VALUES (r_list, r_game)
            ON CONFLICT (list_id, game_id) DO NOTHING;
        END LOOP;
    END LOOP;

    -- 11. List Votes (each list gets 0-8 votes from random users, excluding owner)
    RAISE NOTICE 'Voting on lists...';
    FOREACH r_list IN ARRAY list_ids LOOP
        r_count := floor(random()*9)::int;  -- 0..8
        INSERT INTO List_Votes (list_id, user_id, vote_type)
        SELECT l.list_id, u.user_id, (random() < 0.5)
        FROM (SELECT r_list AS list_id) l
        CROSS JOIN LATERAL (
            SELECT user_id FROM Users
            WHERE user_id <> (SELECT user_id FROM List WHERE list_id = r_list)
            ORDER BY random()
            LIMIT r_count
        ) u
        ON CONFLICT (user_id, list_id) DO NOTHING;
    END LOOP;

    -- 12. Threads (parent threads + replies)
    RAISE NOTICE 'Posting threads...';
    -- 300 parent threads
    FOR i IN 1..300 LOOP
        r_user := user_ids[ceil(random()*array_length(user_ids,1))];
        r_comment := 'Parent thread post #' || i || ': Let''s discuss this game!';
        INSERT INTO Thread (user_id, replying_to, comment)
        VALUES (r_user, NULL, r_comment)
        RETURNING thread_id INTO r_thread;
        thread_ids := array_append(thread_ids, r_thread);
    END LOOP;

    -- 200 replies to random parents
    FOR i IN 1..200 LOOP
        r_user   := user_ids[ceil(random()*array_length(user_ids,1))];
        r_thread := thread_ids[ceil(random()*array_length(thread_ids,1))];
        r_comment := 'Reply #' || i || ' to thread ' || r_thread || '. Interesting points.';
        INSERT INTO Thread (user_id, replying_to, comment)
        VALUES (r_user, r_thread, r_comment)
        RETURNING thread_id INTO r_thread;
        -- Optionally add some deeper replies (nested)
        IF random() < 0.3 THEN
            r_user   := user_ids[ceil(random()*array_length(user_ids,1))];
            r_comment := 'Nested reply to ' || r_thread || '. I agree!';
            INSERT INTO Thread (user_id, replying_to, comment)
            VALUES (r_user, r_thread, r_comment);
        END IF;
    END LOOP;

    -- 13. Thread Votes (0-5 votes per thread, avoiding self-vote)
    RAISE NOTICE 'Voting on threads...';
    FOREACH r_thread IN ARRAY thread_ids LOOP
        r_count := floor(random()*6)::int;  -- 0..5
        INSERT INTO Thread_Votes (thread_id, user_id, vote_type)
        SELECT t.thread_id, u.user_id, (random() < 0.5)
        FROM (SELECT r_thread AS thread_id) t
        CROSS JOIN LATERAL (
            SELECT user_id FROM Users
            WHERE user_id <> (SELECT user_id FROM Thread WHERE thread_id = r_thread)
            ORDER BY random()
            LIMIT r_count
        ) u
        ON CONFLICT (user_id, thread_id) DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Seeding complete!';
END;
$$;

COMMIT;