-- ============================================================
-- school_db : Team 6 School System
-- Target: MySQL 8.0+ / MariaDB 10.5+ (GC-LAMP stack), InnoDB, utf8mb4
-- Usage : mysql -u root -p < school_db.sql
-- ============================================================

DROP DATABASE IF EXISTS school_db;
CREATE DATABASE school_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE school_db;

-- ------------------------------------------------------------
-- 1. Access control
-- ------------------------------------------------------------
CREATE TABLE roles (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code        VARCHAR(30)  NOT NULL,
  name        VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_code (code)
) ENGINE=InnoDB;

CREATE TABLE users (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_active     TINYINT(1)   NOT NULL DEFAULT 1,
  last_login_at DATETIME     NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_id    BIGINT UNSIGNED NOT NULL,
  role_id    BIGINT UNSIGNED NOT NULL,
  granted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. Academic structure
-- ------------------------------------------------------------
CREATE TABLE departments (
  id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code  VARCHAR(20)  NOT NULL,
  name  VARCHAR(150) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE programs (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  department_id BIGINT UNSIGNED NOT NULL,
  code          VARCHAR(20)  NOT NULL,
  name          VARCHAR(150) NOT NULL,
  degree_type   VARCHAR(50)  NOT NULL,
  total_units   SMALLINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_programs_code (code),
  CONSTRAINT fk_programs_department FOREIGN KEY (department_id) REFERENCES departments (id)
) ENGINE=InnoDB;

CREATE TABLE curricula (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  program_id            BIGINT UNSIGNED NOT NULL,
  code                  VARCHAR(30) NOT NULL,
  effective_school_year VARCHAR(9)  NOT NULL COMMENT 'e.g. 2025-2026',
  is_active             TINYINT(1)  NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_curricula_code (code),
  CONSTRAINT fk_curricula_program FOREIGN KEY (program_id) REFERENCES programs (id)
) ENGINE=InnoDB;

CREATE TABLE courses (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  department_id BIGINT UNSIGNED NOT NULL,
  code          VARCHAR(20)  NOT NULL,
  title         VARCHAR(200) NOT NULL,
  units         DECIMAL(3,1) NOT NULL,
  lecture_hours TINYINT UNSIGNED NOT NULL DEFAULT 0,
  lab_hours     TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_courses_code (code),
  CONSTRAINT fk_courses_department FOREIGN KEY (department_id) REFERENCES departments (id),
  CONSTRAINT chk_courses_units CHECK (units >= 0)
) ENGINE=InnoDB;

CREATE TABLE curriculum_courses (
  curriculum_id BIGINT UNSIGNED NOT NULL,
  course_id     BIGINT UNSIGNED NOT NULL,
  year_level    TINYINT UNSIGNED NOT NULL,
  term_no       TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (curriculum_id, course_id),
  CONSTRAINT fk_cc_curriculum FOREIGN KEY (curriculum_id) REFERENCES curricula (id) ON DELETE CASCADE,
  CONSTRAINT fk_cc_course     FOREIGN KEY (course_id)     REFERENCES courses (id)   ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE course_prerequisites (
  course_id              BIGINT UNSIGNED NOT NULL,
  prerequisite_course_id BIGINT UNSIGNED NOT NULL,
  min_grade              DECIMAL(3,2) NULL,
  PRIMARY KEY (course_id, prerequisite_course_id),
  CONSTRAINT fk_cp_course FOREIGN KEY (course_id)              REFERENCES courses (id) ON DELETE CASCADE,
  CONSTRAINT fk_cp_prereq FOREIGN KEY (prerequisite_course_id) REFERENCES courses (id) ON DELETE CASCADE,
  CONSTRAINT chk_cp_not_self CHECK (course_id <> prerequisite_course_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. People
-- ------------------------------------------------------------
CREATE TABLE faculty (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  employee_number VARCHAR(30) NOT NULL,
  department_id   BIGINT UNSIGNED NOT NULL,
  first_name      VARCHAR(100) NOT NULL,
  last_name       VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_faculty_user (user_id),
  UNIQUE KEY uq_faculty_employee_number (employee_number),
  CONSTRAINT fk_faculty_user       FOREIGN KEY (user_id)       REFERENCES users (id),
  CONSTRAINT fk_faculty_department FOREIGN KEY (department_id) REFERENCES departments (id)
) ENGINE=InnoDB;

CREATE TABLE students (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id        BIGINT UNSIGNED NOT NULL,
  student_number VARCHAR(30) NOT NULL,
  program_id     BIGINT UNSIGNED NOT NULL,
  curriculum_id  BIGINT UNSIGNED NOT NULL,
  year_level     TINYINT UNSIGNED NOT NULL DEFAULT 1,
  first_name     VARCHAR(100) NOT NULL,
  last_name      VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_students_user (user_id),
  UNIQUE KEY uq_students_number (student_number),
  CONSTRAINT fk_students_user       FOREIGN KEY (user_id)       REFERENCES users (id),
  CONSTRAINT fk_students_program    FOREIGN KEY (program_id)    REFERENCES programs (id),
  CONSTRAINT fk_students_curriculum FOREIGN KEY (curriculum_id) REFERENCES curricula (id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. Terms, rooms, sections, schedules
-- ------------------------------------------------------------
CREATE TABLE academic_terms (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  school_year         VARCHAR(9) NOT NULL COMMENT 'e.g. 2026-2027',
  semester            ENUM('1st','2nd','summer') NOT NULL,
  starts_on           DATE NOT NULL,
  ends_on             DATE NOT NULL,
  enrollment_opens_at DATETIME NULL,
  enrollment_closes_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_terms_year_sem (school_year, semester),
  CONSTRAINT chk_terms_dates CHECK (ends_on >= starts_on)
) ENGINE=InnoDB;

CREATE TABLE rooms (
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code     VARCHAR(20) NOT NULL,
  building VARCHAR(100) NULL,
  capacity SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rooms_code (code)
) ENGINE=InnoDB;

CREATE TABLE sections (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  course_id    BIGINT UNSIGNED NOT NULL,
  term_id      BIGINT UNSIGNED NOT NULL,
  faculty_id   BIGINT UNSIGNED NULL,
  section_code VARCHAR(20) NOT NULL,
  capacity     SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sections_term_code (course_id, term_id, section_code),
  UNIQUE KEY uq_sections_id_term (id, term_id),   -- target for enrollments composite FK
  CONSTRAINT fk_sections_course  FOREIGN KEY (course_id)  REFERENCES courses (id),
  CONSTRAINT fk_sections_term    FOREIGN KEY (term_id)    REFERENCES academic_terms (id),
  CONSTRAINT fk_sections_faculty FOREIGN KEY (faculty_id) REFERENCES faculty (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE section_schedules (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  section_id BIGINT UNSIGNED NOT NULL,
  room_id    BIGINT UNSIGNED NULL,
  day_of_week ENUM('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL,
  start_time TIME NOT NULL,
  end_time   TIME NOT NULL,
  PRIMARY KEY (id),
  KEY idx_ss_room_day (room_id, day_of_week, start_time),
  CONSTRAINT fk_ss_section FOREIGN KEY (section_id) REFERENCES sections (id) ON DELETE CASCADE,
  CONSTRAINT fk_ss_room    FOREIGN KEY (room_id)    REFERENCES rooms (id) ON DELETE SET NULL,
  CONSTRAINT chk_ss_times CHECK (end_time > start_time)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. Enrollment & grades
-- ------------------------------------------------------------
CREATE TABLE enrollments (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id  BIGINT UNSIGNED NOT NULL,
  section_id  BIGINT UNSIGNED NOT NULL,
  term_id     BIGINT UNSIGNED NOT NULL,
  status      ENUM('pending','enrolled','dropped','rejected','completed') NOT NULL DEFAULT 'pending',
  enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  approved_by BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_enrollments_student_section (student_id, section_id),
  KEY idx_enrollments_student_term (student_id, term_id),
  CONSTRAINT fk_enr_student FOREIGN KEY (student_id) REFERENCES students (id),
  -- composite FK guarantees term_id matches the section's own term
  CONSTRAINT fk_enr_section_term FOREIGN KEY (section_id, term_id) REFERENCES sections (id, term_id),
  CONSTRAINT fk_enr_approved_by  FOREIGN KEY (approved_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE grades (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  enrollment_id BIGINT UNSIGNED NOT NULL,
  final_grade   DECIMAL(3,2) NULL,
  remarks       VARCHAR(100) NULL,
  status        ENUM('draft','submitted','finalized') NOT NULL DEFAULT 'draft',
  submitted_by  BIGINT UNSIGNED NULL,
  submitted_at  DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_grades_enrollment (enrollment_id),
  CONSTRAINT fk_grades_enrollment   FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE,
  CONSTRAINT fk_grades_submitted_by FOREIGN KEY (submitted_by)  REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE grade_history (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  grade_id   BIGINT UNSIGNED NOT NULL,
  old_value  DECIMAL(3,2) NULL,
  new_value  DECIMAL(3,2) NULL,
  old_status VARCHAR(20) NULL,
  new_status VARCHAR(20) NULL,
  changed_by BIGINT UNSIGNED NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_gh_grade (grade_id),
  CONSTRAINT fk_gh_grade      FOREIGN KEY (grade_id)   REFERENCES grades (id) ON DELETE CASCADE,
  CONSTRAINT fk_gh_changed_by FOREIGN KEY (changed_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. Registrar services, audit, settings
-- ------------------------------------------------------------
CREATE TABLE document_requests (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id    BIGINT UNSIGNED NOT NULL,
  processed_by  BIGINT UNSIGNED NULL,
  document_type VARCHAR(80) NOT NULL,
  purpose       VARCHAR(255) NULL,
  status        ENUM('pending','processing','ready','released','rejected') NOT NULL DEFAULT 'pending',
  requested_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  released_at   DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_docreq_student (student_id),
  CONSTRAINT fk_docreq_student   FOREIGN KEY (student_id)   REFERENCES students (id),
  CONSTRAINT fk_docreq_processor FOREIGN KEY (processed_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_user_id BIGINT UNSIGNED NULL,
  action        VARCHAR(80)  NOT NULL,
  entity_type   VARCHAR(80)  NOT NULL,
  entity_id     BIGINT UNSIGNED NULL,
  metadata      JSON NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_entity (entity_type, entity_id),
  KEY idx_audit_actor (actor_user_id),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE system_settings (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  setting_key   VARCHAR(100) NOT NULL,
  setting_value TEXT NULL,
  updated_by    BIGINT UNSIGNED NULL,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_settings_key (setting_key),
  CONSTRAINT fk_settings_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. Starter data
-- ------------------------------------------------------------
INSERT INTO roles (code, name) VALUES
  ('admin',     'Administrator'),
  ('registrar', 'Registrar'),
  ('faculty',   'Faculty'),
  ('student',   'Student');

INSERT INTO system_settings (setting_key, setting_value) VALUES
  ('current_school_year', '2026-2027'),
  ('current_semester',    '1st'),
  ('passing_grade',       '3.00');
