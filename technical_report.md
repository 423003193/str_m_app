# STRM Technical Report

## SQLite Schema
```sql
CREATE TABLE tasks(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  synced INTEGER DEFAULT 0
);
```

## Firestore Structure
Collection: `users/{user_uid}/tasks`
Document fields: id, title, description, status, timestamp, synced.

## REST API Endpoints
- GET https://jsonplaceholder.typicode.com/todos?_limit=10

Parsed to Task models for display in Resources tab.

## Sync Flow
1. Add task to SQLite (offline).
2. On online or manual sync: unsynced -> Firestore -> mark synced.
3. List shows local tasks (synced flag).

## Error Handling
- Try-catch on all async/network.
- Connectivity stream for offline UI.
- Firebase exceptions handled in auth.

## Package Versions
See pubspec.yaml.

Convert to PDF: `pandoc technical_report.md -o report.pdf`

