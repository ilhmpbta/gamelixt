DROP TABLE IF EXISTS Thread_Votes CASCADE;
DROP TABLE IF EXISTS List_Votes CASCADE;
DROP TABLE IF EXISTS User_Library CASCADE;
DROP TABLE IF EXISTS User_Achievements CASCADE;
DROP TABLE IF EXISTS List_Items CASCADE;
DROP TABLE IF EXISTS List CASCADE;
DROP TABLE IF EXISTS Reviews CASCADE;
DROP TABLE IF EXISTS Thread CASCADE;
DROP TABLE IF EXISTS Game_Genres CASCADE;
DROP TABLE IF EXISTS Achievements CASCADE;
DROP TABLE IF EXISTS Genres CASCADE;
DROP TABLE IF EXISTS Games CASCADE;
DROP TABLE IF EXISTS Audit_Log CASCADE;
DROP TABLE IF EXISTS Users CASCADE;

-- Table: Users
CREATE TABLE Users (
    user_id uuid NOT NULL DEFAULT gen_random_uuid(),
    username varchar(50) NOT NULL,
    email varchar(100) NOT NULL,
    password_hash varchar(255) NOT NULL,
    join_date timestamp NOT NULL DEFAULT current_timestamp,
    avatar_url varchar(255) NULL,
    CONSTRAINT Users_pk PRIMARY KEY (user_id),
    CONSTRAINT Users_username_unique UNIQUE (username),
    CONSTRAINT Users_email_unique UNIQUE (email)
);

-- Table: Games
CREATE TABLE Games (
    game_id uuid NOT NULL DEFAULT gen_random_uuid(),
    title varchar(150) NOT NULL,
    developer varchar(100) NULL,
    release_date date NULL,
    description text NULL,
    average_rating decimal(3,2) NULL DEFAULT 0.00,
    cover_url varchar(255) NULL,
    CONSTRAINT Games_pk PRIMARY KEY (game_id)
);

-- Table: Genres
CREATE TABLE Genres (
    genre_id uuid NOT NULL DEFAULT gen_random_uuid(),
    genre_name varchar(50) NOT NULL,
    description text NULL,
    CONSTRAINT Genres_pk PRIMARY KEY (genre_id)
);

-- Table: Audit_Log
CREATE TABLE Audit_Log (
    log_id uuid NOT NULL DEFAULT gen_random_uuid(),
    table_name varchar(50) NOT NULL,
    record_id uuid NOT NULL,
    action_type varchar(20) NOT NULL,
    old_data jsonb NULL,
    action_timestamp timestamp NOT NULL DEFAULT current_timestamp,
    CONSTRAINT Audit_Log_pk PRIMARY KEY (log_id)
);

-- Table: Game_Genres (Many-to-Many Bridge)
CREATE TABLE Game_Genres (
    game_id uuid NOT NULL,
    genre_id uuid NOT NULL,
    CONSTRAINT Game_Genres_pk PRIMARY KEY (game_id, genre_id)
);

-- Table: Achievements
CREATE TABLE Achievements (
    achievement_id uuid NOT NULL DEFAULT gen_random_uuid(),
    game_id uuid NOT NULL,
    achievement_name varchar(100) NOT NULL,
    description text NULL,
    CONSTRAINT Achievements_pk PRIMARY KEY (achievement_id)
);

-- Table: User_Achievements (Many-to-Many Bridge)
CREATE TABLE User_Achievements (
    user_id uuid NOT NULL,
    achievement_id uuid NOT NULL,
    CONSTRAINT User_Achievements_pk PRIMARY KEY (user_id, achievement_id)
);

-- Table: List
CREATE TABLE List (
    list_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    title varchar(100) NOT NULL,
    description text NULL,
    created_at timestamp NOT NULL DEFAULT current_timestamp,
    list_cover_url varchar(255) NULL,
    CONSTRAINT List_pk PRIMARY KEY (list_id)
);

-- Table: List_Items
CREATE TABLE List_Items (
    item_id uuid NOT NULL DEFAULT gen_random_uuid(),
    list_id uuid NOT NULL,
    game_id uuid NOT NULL,
    added_at timestamp NOT NULL DEFAULT current_timestamp,
    CONSTRAINT List_Items_pk PRIMARY KEY (item_id),
    CONSTRAINT List_Items_unique_game UNIQUE (list_id, game_id)
);

-- Table: List_Votes
CREATE TABLE List_Votes (
    list_id uuid NOT NULL,
    user_id uuid NOT NULL,
    vote_type boolean NOT NULL,
    CONSTRAINT List_Votes_pk PRIMARY KEY (user_id, list_id)
);

-- Table: Reviews
CREATE TABLE Reviews (
    review_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    game_id uuid NOT NULL,
    rating decimal(3,2) NOT NULL,
    review_text text NOT NULL,
    created_at timestamp NOT NULL DEFAULT current_timestamp,
    updated_at timestamp NOT NULL DEFAULT current_timestamp,
    CONSTRAINT check_review_rating CHECK (rating >= 0 AND rating <= 5),
    CONSTRAINT Reviews_pk PRIMARY KEY (review_id),
    CONSTRAINT Reviews_unique_user_game UNIQUE (user_id, game_id)
);

-- Table: Thread
CREATE TABLE Thread (
    thread_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    replying_to uuid NULL,
    comment text NOT NULL,
    created_at timestamp NOT NULL DEFAULT current_timestamp,
    CONSTRAINT Thread_pk PRIMARY KEY (thread_id)
);

-- Table: Thread_Votes
CREATE TABLE Thread_Votes (
    thread_id uuid NOT NULL,
    user_id uuid NOT NULL,
    vote_type boolean NOT NULL,
    CONSTRAINT Thread_Votes_pk PRIMARY KEY (user_id, thread_id)
);

-- Table: User_Library
CREATE TABLE User_Library (
    library_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    game_id uuid NOT NULL,
    play_status varchar(20) NOT NULL,
    added_at timestamp NOT NULL DEFAULT current_timestamp,
    CONSTRAINT check_play_status CHECK (play_status IN ('Playing', 'Completed', 'Dropped', 'Plan to Play')),
    CONSTRAINT User_Library_pk PRIMARY KEY (library_id),
    CONSTRAINT User_library_unique_games UNIQUE (user_id, game_id)
);

-- Reference: Game_Genres to Games & Genres
ALTER TABLE Game_Genres ADD CONSTRAINT Game_Genres_Games
    FOREIGN KEY (game_id) REFERENCES Games (game_id) ON DELETE CASCADE;

ALTER TABLE Game_Genres ADD CONSTRAINT Game_Genres_Genres
    FOREIGN KEY (genre_id) REFERENCES Genres (genre_id) ON DELETE CASCADE;

-- Reference: Achievements to Games
ALTER TABLE Achievements ADD CONSTRAINT Achievements_Games
    FOREIGN KEY (game_id) REFERENCES Games (game_id) ON DELETE CASCADE;

-- Reference: User_Achievements to Users & Achievements
ALTER TABLE User_Achievements ADD CONSTRAINT User_Achievements_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

ALTER TABLE User_Achievements ADD CONSTRAINT User_Achievements_Achievements
    FOREIGN KEY (achievement_id) REFERENCES Achievements (achievement_id) ON DELETE CASCADE;

-- Reference: List to Users
ALTER TABLE List ADD CONSTRAINT List_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

-- Reference: List_Items to List & Games
ALTER TABLE List_Items ADD CONSTRAINT List_Items_List
    FOREIGN KEY (list_id) REFERENCES List (list_id) ON DELETE CASCADE;

ALTER TABLE List_Items ADD CONSTRAINT List_Items_Games
    FOREIGN KEY (game_id) REFERENCES Games (game_id) ON DELETE CASCADE;

-- Reference: List_Votes to List & Users
ALTER TABLE List_Votes ADD CONSTRAINT List_Votes_List
    FOREIGN KEY (list_id) REFERENCES List (list_id) ON DELETE CASCADE;

ALTER TABLE List_Votes ADD CONSTRAINT List_Votes_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

-- Reference: Reviews to Users & Games
ALTER TABLE Reviews ADD CONSTRAINT Reviews_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

ALTER TABLE Reviews ADD CONSTRAINT Reviews_Games
    FOREIGN KEY (game_id) REFERENCES Games (game_id) ON DELETE CASCADE;

-- Reference: Thread to Users & Self-Reference
ALTER TABLE Thread ADD CONSTRAINT Thread_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

ALTER TABLE Thread ADD CONSTRAINT Thread_Thread_Reply
    FOREIGN KEY (replying_to) REFERENCES Thread (thread_id) ON DELETE CASCADE;

-- Reference: Thread_Votes to Thread & Users
ALTER TABLE Thread_Votes ADD CONSTRAINT Thread_Votes_Thread
    FOREIGN KEY (thread_id) REFERENCES Thread (thread_id) ON DELETE CASCADE;

ALTER TABLE Thread_Votes ADD CONSTRAINT Thread_Votes_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

-- Reference: User_Library to Users & Games
ALTER TABLE User_Library ADD CONSTRAINT User_Library_Users
    FOREIGN KEY (user_id) REFERENCES Users (user_id) ON DELETE CASCADE;

ALTER TABLE User_Library ADD CONSTRAINT User_Library_Games
    FOREIGN KEY (game_id) REFERENCES Games (game_id) ON DELETE CASCADE;
