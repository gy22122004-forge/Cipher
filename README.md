# Cipher A1 — Full-Stack Task Management App
> Campus Drive Round 1 Submission | Deadline: 8th May '26

## Tech Stack
| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Go + Gin framework |
| Database | SQLite via GORM |
| Auth | JWT (72hr tokens) |
| State Management | Riverpod |

## Demo Accounts
| Role | Email | Password |
|---|---|---|
| Admin | admin@cipher.ai | admin123 |
| Manager | manager@cipher.ai | manager123 |
| Member | member@cipher.ai | member123 |

## Running the App

### Backend (Go)
```bash
cd backend
go run cmd/main.go
# API runs at http://localhost:8080
```

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

## API Endpoints
```
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/users/me         [auth]
GET  /api/v1/users            [admin]
PUT  /api/v1/users/:id/role   [admin]
GET  /api/v1/projects         [auth]
POST /api/v1/projects         [admin/manager]
GET  /api/v1/projects/:id     [auth]
PUT  /api/v1/projects/:id     [admin/manager]
DELETE /api/v1/projects/:id   [admin]
GET  /api/v1/projects/:id/tasks  [auth]
POST /api/v1/projects/:id/tasks  [admin/manager]
GET  /api/v1/tasks/:id        [auth]
PUT  /api/v1/tasks/:id        [auth]
DELETE /api/v1/tasks/:id      [admin/manager]
GET  /api/v1/dashboard/stats  [auth]
```

## Assessment Coverage
- ✅ Authentication & User Flow
- ✅ Project & Task Management UI
- ✅ Dashboard & Data Presentation (bar chart + stats)
- ✅ Validations, Error & Loading States (shimmer, error views)
- ✅ Code Quality & Responsiveness
- ✅ REST API Design & Coverage
- ✅ Authentication & Security (JWT)
- ✅ Role-Based Access Control (Admin/Manager/Member)
- ✅ Database Design & Relationships (GORM + SQLite)
- ✅ Validation, Error Handling & Business Logic
