-- Average Rating Recalculation
CREATE OR REPLACE FUNCTION refresh_game_average_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_game_id uuid;
    new_avg decimal(3,2);
BEGIN
    IF (TG_OP = 'DELETE') THEN
        target_game_id := OLD.game_id;
    ELSE
        target_game_id := NEW.game_id;
    END IF;

    SELECT COALESCE(AVG(rating), 0.00) INTO new_avg
    FROM Reviews WHERE game_id = target_game_id;

    UPDATE Games SET average_rating = new_avg WHERE game_id = target_game_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_recalculate_rating
AFTER INSERT OR UPDATE OR DELETE ON Reviews
FOR EACH ROW EXECUTE FUNCTION refresh_game_average_rating();


-- Anti-Spam: Library Insert Limiter
CREATE OR REPLACE FUNCTION enforce_library_spam_limit()
RETURNS TRIGGER AS $$
DECLARE
    game_count_last_hour int;
BEGIN
    SELECT COUNT(*) INTO game_count_last_hour
    FROM User_Library
    WHERE user_id = NEW.user_id AND added_at >= current_timestamp - INTERVAL '1 hour';

    IF game_count_last_hour >= 50 THEN
        RAISE EXCEPTION 'Spam protection: Maximum 50 library additions per hour allowed.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_limit_library_insert
BEFORE INSERT ON User_Library
FOR EACH ROW EXECUTE FUNCTION enforce_library_spam_limit();

-- Review Audit Trail
CREATE OR REPLACE FUNCTION log_review_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Audit_Log (log_id, table_name, record_id, action_type, old_data, action_timestamp)
    VALUES (
        gen_random_uuid(),
        'Reviews', 
        OLD.review_id, 
        TG_OP || '_REVIEW', 
        to_jsonb(OLD), 
        current_timestamp
    );
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_reviews
AFTER UPDATE OR DELETE ON Reviews
FOR EACH ROW EXECUTE FUNCTION log_review_audit_trail();

-- Self-List Vote Prevention
CREATE OR REPLACE FUNCTION prevent_self_list_vote()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM List l
        WHERE l.list_id = NEW.list_id
          AND l.user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'You cannot vote on your own list.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_self_list_vote
BEFORE INSERT ON List_Votes
FOR EACH ROW EXECUTE FUNCTION prevent_self_list_vote();

-- Self-Thread Vote Prevention
CREATE OR REPLACE FUNCTION prevent_self_thread_vote()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM List l
        WHERE l.list_id = NEW.list_id
          AND l.user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'You cannot vote on your own thread.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_self_thread_vote
BEFORE INSERT ON List_Votes
FOR EACH ROW EXECUTE FUNCTION prevent_self_thread_vote();