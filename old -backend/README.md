# Gokul Shree School Backend API

A scalable REST API backend for the Gokul Shree School mobile application.

## 🛠 Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: Helmet, CORS, bcryptjs

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js    # PostgreSQL connection pool
│   │   ├── migrate.js     # Database migrations
│   │   └── seed.js        # Sample data seeder
│   ├── middleware/
│   │   └── auth.middleware.js  # JWT authentication
│   ├── routes/
│   │   ├── auth.routes.js      # Login, Register, Verify
│   │   ├── course.routes.js    # Course CRUD
│   │   ├── student.routes.js   # Student profile, results
│   │   ├── notice.routes.js    # Announcements
│   │   └── download.routes.js  # File downloads
│   └── server.js          # Express app entry point
├── .env                   # Environment variables
├── .env.example           # Environment template
└── package.json           # Dependencies
```

## 🚀 Getting Started

### Prerequisites

1. **Node.js 18+**: [Download](https://nodejs.org/)
2. **PostgreSQL 14+**: [Download](https://www.postgresql.org/download/)

### Installation

1. **Install dependencies**:
   ```bash
   cd backend
   npm install
   ```

2. **Configure environment**:
   - Copy `.env.example` to `.env`
   - Update database credentials:
     ```
     DB_HOST=localhost
     DB_PORT=5432
     DB_NAME=gokul_shree_db
     DB_USER=postgres
     DB_PASSWORD=your_password
     ```

3. **Create database**:
   ```sql
   CREATE DATABASE gokul_shree_db;
   ```

4. **Run migrations**:
   ```bash
   npm run db:migrate
   ```

5. **Seed sample data**:
   ```bash
   npm run db:seed
   ```

6. **Start server**:
   ```bash
   # Development (with hot reload)
   npm run dev

   # Production
   npm start
   ```

## 📡 API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Student login |
| POST | `/api/v1/auth/register` | Register new student |
| GET | `/api/v1/auth/verify` | Verify JWT token |

### Courses
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/courses` | Get all courses |
| GET | `/api/v1/courses/:id` | Get course by ID |
| GET | `/api/v1/courses/meta/categories` | Get categories |

### Students (Protected)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/students/profile` | Get student profile |
| GET | `/api/v1/students/results` | Get exam results |
| GET | `/api/v1/students/admit-cards` | Get admit cards |
| POST | `/api/v1/students/verify` | Verify student (public) |

### Notices
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notices` | Get all notices |
| GET | `/api/v1/notices/:id` | Get notice by ID |

### Downloads
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/downloads` | Get all downloads |
| POST | `/api/v1/downloads/:id/download` | Record download |

## 🔐 Authentication

Protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## 🧪 Demo Credentials

After running the seed script:
- **Registration Number**: `12345`
- **Password**: `password`

## 🐳 Docker (Optional)

```dockerfile
# Coming soon
```

## 📈 Scalability Features

- **Connection Pooling**: PostgreSQL connection pool (max 20 clients)
- **Stateless JWT**: Horizontal scaling ready
- **CORS Enabled**: Multi-client support
- **Health Check**: `/health` endpoint for load balancers

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_NAME` | Database name | gokul_shree_db |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | - |
| `JWT_SECRET` | JWT signing secret | - |
| `JWT_EXPIRES_IN` | Token expiry | 7d |
