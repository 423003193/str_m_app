# STRM Technical Implementation Report

This report details the technical architecture and data structures behind the SecureCloud Task & Resource Manager (STRM) application.

## 💾 SQLite Local Persistence

### Schema
The local database uses **SQFlite** to manage task data offline. 

```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  synced INTEGER DEFAULT 0
);
```

### How it's Used
1.  **Offline-First Strategy**: All Create-Update-Delete (CUD) operations are performed locally first. This ensures zero latency and full functionality regardless of internet status.
2.  **Optimistic UI**: The `TaskNotifier` updates the application state based on SQLite results immediately before attempting remote synchronization.
3.  **Sync Tracking**: The `synced` flag (0/1) tells the engine which tasks need to be pushed to Firestore once a connection is re-established.

---

## 🔥 Cloud Firestore Structure

### Structure
Data is organized in a user-centric sub-collection hierarchy to ensure data isolation and security.

**Path**: `users/{uid}/tasks/{task_id}`

| Field | Type | Description |
| :--- | :--- | :--- |
| `title` | `String` | Task headline |
| `description` | `String` | Supporting details |
| `status` | `String` | `pending` or `done` |
| `timestamp` | `number` | Creation time (ms) |

### How it's Used
1.  **Remote Sync**: When the user clicks the "Sync" button (or auto-reconnects), the app iterates through SQLite entries where `synced = 0` and pushes them to this collection.
2.  **Backup & Restore**: This allows users to access their tasks from any device once logged in via Firebase Authentication.

---

## 🌐 REST API Integration

The application consumes two primary public REST APIs to provide real-time environment and resource insights.

### 1. Weather Forecast API
*   **Endpoint**: `api.open-meteo.com/v1/forecast`
*   **Parameters**: Latitude/Longitude (New York by default), temperature_2m, wind_speed_10m.
*   **Usage**: Displayed in the **Live Data > Weather** tab. The `ApiService` fetches the JSON response and maps it to a `Weather` model to display current conditions in the UI.

### 2. Currency Exchange API
*   **Endpoint**: `open.er-api.com/v6/latest/USD`
*   **Usage**: Displayed in the **Live Data > Currency** tab. Provides real-time relative values for global currencies against the USD. 

### Implementation Detail
Both APIs are consumed via the `http` package with a **15-second timeout** and robust error handling. Data is intentionally **non-persisted** to ensure that users always see the most up-to-date live information every time they open the tab.

---

## 🛠 Tech Stack Overview
| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter |
| **State Management** | Riverpod (StateNotifier) |
| **Authentication** | Firebase Auth |
| **Cloud Storage** | Google Cloud Firestore |
| **Local DB** | SQLite (SQFlite) |
| **HTTP Client** | http |

---
*Report generated on 2026-04-10*
