# Educational Platform Database

[![Actions Status](https://github.com/mikitasazan/sql-for-developers-project-136/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/mikitasazan/sql-for-developers-project-136/actions)

A production-ready PostgreSQL database schema for modern educational platforms, featuring comprehensive course management, user enrollment, payment processing, and interactive learning components.

## Overview

This schema supports a complete online learning ecosystem with:

**Content Management**: Hierarchical structure (Programs → Modules → Courses → Lessons) with flexible many-to-many relationships, enabling complex curriculum design.

**User System**: Role-based access control (student/teacher/admin), teaching group assignments, and secure authentication with soft-delete support.

**Enrollment & Finance**: Full enrollment lifecycle tracking with multi-status payments (pending/paid/failed/refunded), certificate issuance, and program completion tracking.

**Learning Tools**: Interactive quizzes and exercises, threaded discussions with JSONB storage for flexible content structure, and progress monitoring.

**Technical Features**: Automatic timestamp management via triggers, comprehensive indexing on foreign keys and query-critical columns, JSONB for dynamic content, and extensive data validation through CHECK and UNIQUE constraints.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/mikitasazan/sql-for-developers-project-136.git
cd sql-for-developers-project-136

# Execute schema (PostgreSQL 12+)
psql -U username -d database -f database.sql
```

## Schema Architecture

### Core Entities

- **programs** - Educational offerings with pricing and type (certificate/degree/short_course)
- **program_modules** - Junction table linking programs to modules (many-to-many)
- **modules** - Logical groupings of related courses
- **course_modules** - Junction table linking courses to modules (many-to-many)
- **courses** - Collections of lessons forming a learning unit
- **lessons** - Individual learning units with content, videos, and sequential positioning

### User Management

- **users** - Accounts with role-based permissions and optional teaching group assignment
- **teaching_groups** - Organizational units for teacher management
- **enrollments** - User-program registrations with status tracking (active/pending/cancelled/completed)
- **payments** - Financial transactions linked to enrollments
- **program_completions** - Progress tracking with start/completion dates
- **certificates** - Credential issuance upon successful completion

### Learning Components

- **quizzes** - Assessments with JSONB-stored question trees
- **exercises** - Practical assignments linked to lessons
- **discussions** - Threaded conversations with JSONB-stored structure
- **blog_posts** - Educational content with moderation workflow

## Key Features

**Soft Deletes**: All tables use `deleted_at` timestamps instead of hard deletes, preserving data integrity and enabling recovery.

**Auto-Timestamps**: Every table includes `created_at` and `updated_at` columns, with automatic updates via the `update_updated_at_column()` trigger.

**Data Integrity**: Enforced through CHECK constraints (positive prices/positions), UNIQUE constraints (no duplicate enrollments/certificates), and comprehensive foreign key relationships.

**Performance**: Strategic indexing on all foreign keys, status columns, and frequently queried fields.

**Flexibility**: JSONB columns in quizzes and discussions allow schema-less nested structures without additional tables.

## License

MIT
