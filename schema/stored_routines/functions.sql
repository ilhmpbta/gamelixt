-- 1. UTILITY: Count List Votes (Upvotes - Downvotes)
CREATE OR REPLACE FUNCTION count_list_vote(target_list_id uuid)
RETURNS int AS $$
DECLARE
    total_score int;
BEGIN
    SELECT 
        COALESCE(SUM(CASE WHEN vote_type = true THEN 1 ELSE -1 END), 0)
    INTO total_score
    FROM List_Votes
    WHERE list_id = target_list_id;
    
    RETURN total_score;
END;
$$ LANGUAGE plpgsql;

-- 2. UTILITY: Count Thread Votes (Upvotes - Downvotes)
CREATE OR REPLACE FUNCTION count_thread_vote(target_thread_id uuid)
RETURNS int AS $$
DECLARE
    total_score int;
BEGIN
    SELECT 
        COALESCE(SUM(CASE WHEN vote_type = true THEN 1 ELSE -1 END), 0)
    INTO total_score
    FROM Thread_Votes
    WHERE thread_id = target_thread_id;
    
    RETURN total_score;
END;
$$ LANGUAGE plpgsql;

-- 3. ENDPOINT: Get Thread Tree View (/threads/[id])
-- Menarik thread parent beserta seluruh balasan beruntunnya dalam satu query
CREATE OR REPLACE FUNCTION get_thread_tree(root_thread_id uuid)
RETURNS TABLE (
    thread_id uuid,
    user_id uuid,
    username varchar(50),
    replying_to uuid,
    comment text,
    created_at timestamp,
    net_votes int
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE ThreadCTE AS (
        -- Base case: The requested parent thread
        SELECT t.thread_id, t.user_id, t.replying_to, t.comment, t.created_at
        FROM Thread t WHERE t.thread_id = root_thread_id
        UNION ALL
        -- Recursive step: All children
        SELECT t.thread_id, t.user_id, t.replying_to, t.comment, t.created_at
        FROM Thread t
        INNER JOIN ThreadCTE cte ON t.replying_to = cte.thread_id
    )
    SELECT 
        cte.thread_id, cte.user_id, u.username, cte.replying_to, cte.comment, cte.created_at,
        count_thread_vote(cte.thread_id) AS net_votes
    FROM ThreadCTE cte
    JOIN Users u ON cte.user_id = u.user_id
    ORDER BY cte.created_at ASC;
END;
$$ LANGUAGE plpgsql;