# GameLixt
Aplikasi katalog dan manajemen koleksi game — seperti MyAnimeList tapi untuk game.

Database Schema Final Project Mata Kuliah Manajemen Basis Data
Institut Teknologi Sepuluh Nopember — 2026

> The Implementation can be accessed at [@hisyamssyr/game-lixt](https://github.com/hisyamssyr/game-lixt/)

## Anggota Kelompok
| Nama | NRP |
|------|-----|
| Hasan Abdurrahman | 5025241114 |
| Hisyam Syafa Raditya | 5025241130 |
| Bintang Ilham Pabeta | 5025241152 |

## About

* Uses PostgreSQL 18
* Implements Active Database/Stored Routines (Functions, Stored Procedures, Triggers)
* Performance Analyzed using PostgreSQL's EXPLAIN ANALYZE

## Project Structure

```
gamelixt/
  ├── ddl.sql             # DDL (Data Definition Language)
  ├── index.sql           # Indexes
  ├── analysis/
  │   └── analyze.sql     # Query analisis
  ├── dummy/
  │   ├── dml.sql         # DML (Data Manipulation Language)
  │   └── seed.sql        # Seed data for dummy tables
  └── stored_routines/
      ├── functions.sql   # Functions
      ├── procedures.sql  # Stored procedures
      └── triggers.sql    # Triggers
```
