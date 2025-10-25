-- Creating a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Creating ENUM types for various status and role fields
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'admin');
COMMENT ON TYPE user_role IS 'Defines possible user roles in the system';

CREATE TYPE enrollment_status AS ENUM ('active', 'pending', 'cancelled', 'completed');
COMMENT ON TYPE enrollment_status IS 'Defines possible statuses for program enrollments';

CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
COMMENT ON TYPE payment_status IS 'Defines possible statuses for payments';

CREATE TYPE program_completion_status AS ENUM ('active', 'completed', 'pending', 'cancelled');
COMMENT ON TYPE program_completion_status IS 'Defines possible statuses for program completions';

CREATE TYPE blog_status AS ENUM ('created', 'in_moderation', 'published', 'archived');
COMMENT ON TYPE blog_status IS 'Defines possible statuses for blog posts';

CREATE TYPE program_type AS ENUM ('certificate', 'degree', 'short_course');
COMMENT ON TYPE program_type IS 'Defines possible types of educational programs';

-- Creating courses table
CREATE TABLE courses
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP WITH TIME ZONE
);
COMMENT ON TABLE courses IS 'Stores information about individual courses';
COMMENT ON COLUMN courses.name IS 'The name of the course';
COMMENT ON COLUMN courses.description IS 'Detailed description of the course content';
COMMENT ON COLUMN courses.deleted_at IS 'Soft delete timestamp to mark courses as deleted without removing them';

-- Creating trigger for courses updated_at
CREATE TRIGGER update_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating modules table
CREATE TABLE modules
(
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP WITH TIME ZONE
);
COMMENT ON TABLE modules IS 'Stores information about modules that group related courses';
COMMENT ON COLUMN modules.name IS 'The name of the module';
COMMENT ON COLUMN modules.description IS 'Detailed description of the module content';
COMMENT ON COLUMN modules.deleted_at IS 'Soft delete timestamp to mark modules as deleted without removing them';

-- Creating trigger for modules updated_at
CREATE TRIGGER update_modules_updated_at
    BEFORE UPDATE ON modules
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating programs table
CREATE TABLE programs
(
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(255)   NOT NULL,
    price        DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    program_type VARCHAR(255),
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE programs IS 'Stores information about educational programs that students can enroll in';
COMMENT ON COLUMN programs.name IS 'The name of the program';
COMMENT ON COLUMN programs.price IS 'The price of the program in decimal format';
COMMENT ON COLUMN programs.program_type IS 'The type of program (certificate, degree, short_course)';

-- Creating trigger for programs updated_at
CREATE TRIGGER update_programs_updated_at
    BEFORE UPDATE ON programs
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating course_modules junction table for many-to-many relationship
CREATE TABLE course_modules
(
    course_id INTEGER NOT NULL,
    module_id INTEGER NOT NULL,
    PRIMARY KEY (course_id, module_id),
    FOREIGN KEY (course_id) REFERENCES courses (id),
    FOREIGN KEY (module_id) REFERENCES modules (id)
);
COMMENT ON TABLE course_modules IS 'Junction table for the many-to-many relationship between courses and modules';
COMMENT ON COLUMN course_modules.course_id IS 'Foreign key reference to the courses table';
COMMENT ON COLUMN course_modules.module_id IS 'Foreign key reference to the modules table';

-- Creating indexes for course_modules
CREATE INDEX idx_course_modules_course_id ON course_modules(course_id);
CREATE INDEX idx_course_modules_module_id ON course_modules(module_id);

-- Creating program_modules junction table for many-to-many relationship
CREATE TABLE program_modules
(
    module_id  INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    PRIMARY KEY (module_id, program_id),
    FOREIGN KEY (module_id) REFERENCES modules (id),
    FOREIGN KEY (program_id) REFERENCES programs (id)
);
COMMENT ON TABLE program_modules IS 'Junction table for the many-to-many relationship between modules and programs';
COMMENT ON COLUMN program_modules.module_id IS 'Foreign key reference to the modules table';
COMMENT ON COLUMN program_modules.program_id IS 'Foreign key reference to the programs table';

-- Creating indexes for program_modules
CREATE INDEX idx_program_modules_module_id ON program_modules(module_id);
CREATE INDEX idx_program_modules_program_id ON program_modules(program_id);

-- Creating lessons table
CREATE TABLE lessons
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    content    TEXT,
    video_url  VARCHAR(255),
    position   INTEGER CHECK (position > 0),
    course_id  INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (course_id) REFERENCES courses (id)
);
COMMENT ON TABLE lessons IS 'Stores individual learning units that make up courses';
COMMENT ON COLUMN lessons.name IS 'The name of the lesson';
COMMENT ON COLUMN lessons.content IS 'The textual content of the lesson';
COMMENT ON COLUMN lessons.video_url IS 'URL to the video content for the lesson';
COMMENT ON COLUMN lessons.position IS 'The order of the lesson within its course';
COMMENT ON COLUMN lessons.course_id IS 'Foreign key reference to the courses table';
COMMENT ON COLUMN lessons.deleted_at IS 'Soft delete timestamp to mark lessons as deleted without removing them';

-- Creating trigger for lessons updated_at
CREATE TRIGGER update_lessons_updated_at
    BEFORE UPDATE ON lessons
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for lessons
CREATE INDEX idx_lessons_course_id ON lessons(course_id);

-- Creating teaching_groups table
CREATE TABLE teaching_groups
(
    id         SERIAL PRIMARY KEY,
    slug       VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE teaching_groups IS 'Stores information about teaching groups that teachers can be assigned to';
COMMENT ON COLUMN teaching_groups.slug IS 'A unique identifier for the teaching group used in URLs';

-- Creating trigger for teaching_groups updated_at
CREATE TRIGGER update_teaching_groups_updated_at
    BEFORE UPDATE ON teaching_groups
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating users table
CREATE TABLE users
(
    id                SERIAL PRIMARY KEY,
    name              VARCHAR(255) NOT NULL,
    email             VARCHAR(255) NOT NULL UNIQUE,
    password_hash     VARCHAR(255),
    role              VARCHAR(50)  NOT NULL,
    teaching_group_id INTEGER,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at        TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (teaching_group_id) REFERENCES teaching_groups (id)
);
COMMENT ON TABLE users IS 'Stores all user accounts including students, teachers, and administrators';
COMMENT ON COLUMN users.name IS 'The name for the user account';
COMMENT ON COLUMN users.email IS 'The email address for the user account, must be unique';
COMMENT ON COLUMN users.password_hash IS 'The hashed password for the user account';
COMMENT ON COLUMN users.role IS 'User role determining permissions: student, teacher, or admin';
COMMENT ON COLUMN users.teaching_group_id IS 'Foreign key reference to the teaching_groups table for teachers';
COMMENT ON COLUMN users.deleted_at IS 'Soft delete timestamp to mark users as deleted without removing them';

-- Creating trigger for users updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for users
CREATE INDEX idx_users_teaching_group_id ON users(teaching_group_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Creating enrollments table
CREATE TABLE enrollments
(
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER           NOT NULL,
    program_id INTEGER           NOT NULL,
    status     enrollment_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (program_id) REFERENCES programs (id),
    UNIQUE (user_id, program_id)
);
COMMENT ON TABLE enrollments IS 'Tracks user enrollment in educational programs';
COMMENT ON COLUMN enrollments.user_id IS 'Foreign key reference to the users table';
COMMENT ON COLUMN enrollments.program_id IS 'Foreign key reference to the programs table';
COMMENT ON COLUMN enrollments.status IS 'Current status of the enrollment: active, pending, cancelled, or completed';

-- Creating trigger for enrollments updated_at
CREATE TRIGGER update_enrollments_updated_at
    BEFORE UPDATE ON enrollments
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating indexes for enrollments
CREATE INDEX idx_enrollments_user_id ON enrollments(user_id);
CREATE INDEX idx_enrollments_program_id ON enrollments(program_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

-- Creating payments table
CREATE TABLE payments
(
    id            SERIAL PRIMARY KEY,
    enrollment_id INTEGER        NOT NULL,
    amount        DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    status        payment_status NOT NULL,
    paid_at       TIMESTAMP WITH TIME ZONE,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (enrollment_id) REFERENCES enrollments (id)
);
COMMENT ON TABLE payments IS 'Tracks payment information for program enrollments';
COMMENT ON COLUMN payments.enrollment_id IS 'Foreign key reference to the enrollments table';
COMMENT ON COLUMN payments.amount IS 'The payment amount in decimal format';
COMMENT ON COLUMN payments.status IS 'Current status of the payment: pending, paid, failed, or refunded';
COMMENT ON COLUMN payments.paid_at IS 'The date and time when the payment was processed';

-- Creating trigger for payments updated_at
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for payments
CREATE INDEX idx_payments_enrollment_id ON payments(enrollment_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);

-- Creating program_completions table
CREATE TABLE program_completions
(
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER                   NOT NULL,
    program_id   INTEGER                   NOT NULL,
    status       program_completion_status NOT NULL,
    started_at   TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (program_id) REFERENCES programs (id),
    UNIQUE (user_id, program_id)
);
COMMENT ON TABLE program_completions IS 'Tracks user progress and completion of educational programs';
COMMENT ON COLUMN program_completions.user_id IS 'Foreign key reference to the users table';
COMMENT ON COLUMN program_completions.program_id IS 'Foreign key reference to the programs table';
COMMENT ON COLUMN program_completions.status IS 'Current status of the program completion: active, completed, pending, or cancelled';
COMMENT ON COLUMN program_completions.started_at IS 'The date and time when the user started the program';
COMMENT ON COLUMN program_completions.completed_at IS 'The date and time when the user completed the program';

-- Creating trigger for program_completions updated_at
CREATE TRIGGER update_program_completions_updated_at
    BEFORE UPDATE ON program_completions
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating indexes for program_completions
CREATE INDEX idx_program_completions_user_id ON program_completions(user_id);
CREATE INDEX idx_program_completions_program_id ON program_completions(program_id);
CREATE INDEX idx_program_completions_status ON program_completions(status);

-- Creating certificates table
CREATE TABLE certificates
(
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER                  NOT NULL,
    program_id INTEGER                  NOT NULL,
    url        VARCHAR(255)             NOT NULL,
    issued_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (program_id) REFERENCES programs (id),
    UNIQUE (user_id, program_id)
);
COMMENT ON TABLE certificates IS 'Stores certificates issued to users upon program completion';
COMMENT ON COLUMN certificates.user_id IS 'Foreign key reference to the users table';
COMMENT ON COLUMN certificates.program_id IS 'Foreign key reference to the programs table';
COMMENT ON COLUMN certificates.url IS 'URL to access the certificate';
COMMENT ON COLUMN certificates.issued_at IS 'The date and time when the certificate was issued';

-- Creating trigger for certificates updated_at
CREATE TRIGGER update_certificates_updated_at
    BEFORE UPDATE ON certificates
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating indexes for certificates
CREATE INDEX idx_certificates_user_id ON certificates(user_id);
CREATE INDEX idx_certificates_program_id ON certificates(program_id);
CREATE INDEX idx_certificates_issued_at ON certificates(issued_at);

-- Creating quizzes table
CREATE TABLE quizzes
(
    id         SERIAL PRIMARY KEY,
    lesson_id  INTEGER      NOT NULL,
    name       VARCHAR(255) NOT NULL,
    content    JSONB        NOT NULL, -- Using JSONB for storing tree-like question structure
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lesson_id) REFERENCES lessons (id)
);
COMMENT ON TABLE quizzes IS 'Stores quizzes associated with lessons';
COMMENT ON COLUMN quizzes.lesson_id IS 'Foreign key reference to the lessons table';
COMMENT ON COLUMN quizzes.name IS 'The name of the quiz';
COMMENT ON COLUMN quizzes.content IS 'JSONB structure containing quiz questions and answers';

-- Creating trigger for quizzes updated_at
CREATE TRIGGER update_quizzes_updated_at
    BEFORE UPDATE ON quizzes
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for quizzes
CREATE INDEX idx_quizzes_lesson_id ON quizzes(lesson_id);

-- Creating exercises table
CREATE TABLE exercises
(
    id         SERIAL PRIMARY KEY,
    lesson_id  INTEGER      NOT NULL,
    name       VARCHAR(255) NOT NULL,
    url        VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lesson_id) REFERENCES lessons (id)
);
COMMENT ON TABLE exercises IS 'Stores exercises associated with lessons';
COMMENT ON COLUMN exercises.lesson_id IS 'Foreign key reference to the lessons table';
COMMENT ON COLUMN exercises.name IS 'The name of the exercise';
COMMENT ON COLUMN exercises.url IS 'URL to access the exercise content';

-- Creating trigger for exercises updated_at
CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for exercises
CREATE INDEX idx_exercises_lesson_id ON exercises(lesson_id);

-- Creating discussions table
CREATE TABLE discussions
(
    id         SERIAL PRIMARY KEY,
    lesson_id  INTEGER NOT NULL,
    text       JSONB   NOT NULL,
    user_id    INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lesson_id) REFERENCES lessons (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);
COMMENT ON TABLE discussions IS 'Stores discussions associated with lessons';
COMMENT ON COLUMN discussions.lesson_id IS 'Foreign key reference to the lessons table';
COMMENT ON COLUMN discussions.text IS 'JSONB structure containing discussion content';
COMMENT ON COLUMN discussions.user_id IS 'Foreign key reference to the users table';

-- Creating trigger for discussions updated_at
CREATE TRIGGER update_discussions_updated_at
    BEFORE UPDATE ON discussions
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating index for discussions
CREATE INDEX idx_discussions_lesson_id ON discussions(lesson_id);
CREATE INDEX idx_discussions_user_id ON discussions(user_id);

-- Creating blogs table
CREATE TABLE blogs
(
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER      NOT NULL,
    name       VARCHAR(255) NOT NULL,
    content    TEXT         NOT NULL,
    status     blog_status  NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);
COMMENT ON TABLE blogs IS 'Stores blogs created by users';
COMMENT ON COLUMN blogs.user_id IS 'Foreign key reference to the users table';
COMMENT ON COLUMN blogs.name IS 'The name of the blog';
COMMENT ON COLUMN blogs.content IS 'The content of the blog';
COMMENT ON COLUMN blogs.status IS 'Current status of the blog: created, in_moderation, published, or archived';

-- Creating trigger for blogs updated_at
CREATE TRIGGER update_blogs_updated_at
    BEFORE UPDATE ON blogs
    FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Creating indexes for blogs
CREATE INDEX idx_blogs_user_id ON blogs(user_id);
CREATE INDEX idx_blogs_status ON blogs(status);
