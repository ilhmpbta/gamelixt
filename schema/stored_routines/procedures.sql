-- 1. Add Game Review with condition User has to own the game before leaving a review.
CREATE OR REPLACE PROCEDURE add_game_review(
    p_user_id uuid,
    p_game_id uuid,
    p_rating decimal(3,2),
    p_text text
)
LANGUAGE plpgsql AS $$
DECLARE
    in_library boolean;
    already_reviewed boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM User_Library WHERE user_id = p_user_id AND game_id = p_game_id) INTO in_library;
    IF NOT in_library THEN
        RAISE EXCEPTION 'Action Denied: You must add this game to your library before leaving a review.';
    END IF;

    SELECT EXISTS(SELECT 1 FROM Reviews WHERE user_id = p_user_id AND game_id = p_game_id) INTO already_reviewed;
    IF already_reviewed THEN
        RAISE EXCEPTION 'Action Denied: You have already reviewed this game. Please edit your existing review instead.';
    END IF;

    INSERT INTO Reviews (user_id, game_id, rating, review_text, created_at, updated_at)
    VALUES (p_user_id, p_game_id, p_rating, p_text, current_timestamp, current_timestamp);
END;
$$;

-- 2. Edit Review
CREATE OR REPLACE PROCEDURE edit_review(
    p_user_id uuid,
    p_review_id uuid,
    p_text text,
    p_rating decimal(3,2) DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Reviews WHERE review_id = p_review_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'Action Denied: You do not have permission to edit this review.';
    END IF;
    
    UPDATE Reviews
    SET review_text = p_text,
       rating = COALESCE(p_rating, rating),
       updated_at = current_timestamp
    WHERE review_id = p_review_id AND user_id = p_user_id;
END;
$$;

-- 3. Delete Review
CREATE OR REPLACE PROCEDURE delete_review(
    p_user_id uuid,
    p_review_id uuid
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Reviews WHERE review_id = p_review_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'Action Denied: You do not have permission to delete this review.';
    END IF;    
    
    DELETE FROM Reviews WHERE review_id = p_review_id AND user_id = p_user_id;
END;
$$;

-- 4. Toggle List Vote (Upvote/Downvote/Remove)
CREATE OR REPLACE PROCEDURE toggle_list_vote(
    p_user_id uuid,
    p_list_id uuid,
    p_is_upvote boolean
)
LANGUAGE plpgsql AS $$
DECLARE
    existing_vote boolean;
BEGIN
    SELECT vote_type INTO existing_vote 
    FROM List_Votes WHERE user_id = p_user_id AND list_id = p_list_id;

    IF FOUND THEN
        IF existing_vote = p_is_upvote THEN
            -- Hapus vote jika user mengklik tombol yang sama dua kali (Unlike/Remove)
            DELETE FROM List_Votes WHERE user_id = p_user_id AND list_id = p_list_id;
        ELSE
            -- Flip dari upvote ke downvote (atau sebaliknya)
            UPDATE List_Votes SET vote_type = p_is_upvote 
            WHERE user_id = p_user_id AND list_id = p_list_id;
        END IF;
    ELSE
        -- Belum pernah vote, buat baru
        INSERT INTO List_Votes (list_id, user_id, vote_type) 
        VALUES (p_list_id, p_user_id, p_is_upvote);
    END IF;
END;
$$;


-- 5. Toggle Thread Vote
CREATE OR REPLACE PROCEDURE toggle_thread_vote(
    p_user_id uuid,
    p_thread_id uuid,
    p_is_upvote boolean
)
LANGUAGE plpgsql AS $$
DECLARE
    existing_vote boolean;
BEGIN
    SELECT vote_type INTO existing_vote 
    FROM Thread_Votes WHERE user_id = p_user_id AND thread_id = p_thread_id;

    IF FOUND THEN
        IF existing_vote = p_is_upvote THEN
            DELETE FROM Thread_Votes WHERE user_id = p_user_id AND thread_id = p_thread_id;
        ELSE
            UPDATE Thread_Votes SET vote_type = p_is_upvote 
            WHERE user_id = p_user_id AND thread_id = p_thread_id;
        END IF;
    ELSE
        INSERT INTO Thread_Votes (thread_id, user_id, vote_type) 
        VALUES (p_thread_id, p_user_id, p_is_upvote);
    END IF;
END;
$$;

-- 6. Upsert User Library (Add or Edit in one procedure)
CREATE OR REPLACE PROCEDURE upsert_user_library(
    p_user_id uuid,
    p_game_id uuid,
    p_play_status varchar(20)
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Validate constraint
    IF p_play_status NOT IN ('Playing', 'Completed', 'Dropped', 'Plan to Play') THEN
        RAISE EXCEPTION 'Invalid play_status. Must be Playing, Completed, Dropped, or Plan to Play.';
    END IF;

    -- Upsert logic: Insert new, or update if the unique constraint (user_id, game_id) clashes
    INSERT INTO User_Library (user_id, game_id, play_status, added_at)
    VALUES (p_user_id, p_game_id, p_play_status, current_timestamp)
    ON CONFLICT (user_id, game_id) 
    DO UPDATE SET 
        play_status = EXCLUDED.play_status
END;
$$;

-- 7. Create a Curated List
CREATE OR REPLACE PROCEDURE create_new_list(
    p_user_id uuid,
    p_title varchar(100),
    p_description text,
    p_cover_url varchar(255)
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO List (user_id, title, description, list_cover_url, created_at)
    VALUES (p_user_id, p_title, p_description, p_cover_url, current_timestamp);
END;
$$;

-- 8. Edit an Existing List
CREATE OR REPLACE PROCEDURE edit_list_details(
    p_user_id uuid,
    p_list_id uuid,
    p_title varchar(100),
    p_description text,
    p_cover_url varchar(255)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM List WHERE list_id = p_list_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'Action Denied: You do not have permission to edit this list.';
    END IF;

    UPDATE List
    SET title = p_title,
        description = p_description,
        list_cover_url = p_cover_url
    WHERE list_id = p_list_id AND user_id = p_user_id;
END;
$$;

-- 9. Add Game to List
CREATE OR REPLACE PROCEDURE add_game_to_list(
    p_user_id uuid,
    p_list_id uuid,
    p_game_id uuid
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM List
        WHERE list_id = p_list_id
          AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Action Denied: You do not own this list.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM List_Items
        WHERE list_id = p_list_id
          AND game_id = p_game_id
    ) THEN
        RAISE EXCEPTION 'Game already exists in this list.';
    END IF;

    INSERT INTO List_Items (list_id, game_id)
    VALUES (p_list_id, p_game_id);
END;
$$;

-- 10. Remove Game from List
CREATE OR REPLACE PROCEDURE remove_game_from_list(
    p_user_id uuid,
    p_list_id uuid,
    p_game_id uuid
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM List
        WHERE list_id = p_list_id
          AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'Action Denied: You do not own this list.';
    END IF;

    DELETE FROM List_Items
    WHERE list_id = p_list_id
      AND game_id = p_game_id;
END;
$$;

-- 11. Start a Thread or Reply
CREATE OR REPLACE PROCEDURE create_thread_post(
    p_user_id uuid,
    p_replying_to uuid, -- Pass NULL if creating a brand new main thread
    p_comment text
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Integrity Check: If this is a reply, verify the parent thread hasn't been deleted
    IF p_replying_to IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM Thread WHERE thread_id = p_replying_to) THEN
            RAISE EXCEPTION 'Action Denied: The thread you are replying to no longer exists.';
        END IF;
    END IF;

    INSERT INTO Thread (user_id, replying_to, comment, created_at)
    VALUES (p_user_id, p_replying_to, p_comment, current_timestamp);
END;
$$;
