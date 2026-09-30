-- =========================================================================
-- HỆ THỐNG QUẢN LÝ SINH VIÊN (STUDENT MANAGEMENT SYSTEM)
-- Database Script cho MySQL 8.0+
-- =========================================================================

CREATE DATABASE IF NOT EXISTS csdl CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE csdl;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. users (Tài khoản người dùng hệ thống)
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, INACTIVE, LOCKED',
    last_login_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. roles (Danh mục vai trò)
DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_code VARCHAR(30) NOT NULL UNIQUE,
    role_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. permissions (Quyền hạn chi tiết)
DROP TABLE IF EXISTS permissions;
CREATE TABLE permissions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    permission_code VARCHAR(50) NOT NULL UNIQUE,
    permission_name VARCHAR(100) NOT NULL,
    module_group VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. user_roles (Bảng liên kết Phân quyền N-M)
DROP TABLE IF EXISTS user_roles;
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. faculties (Khoa / Viện đào tạo)
DROP TABLE IF EXISTS faculties;
CREATE TABLE faculties (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    faculty_code VARCHAR(30) NOT NULL UNIQUE,
    faculty_name VARCHAR(150) NOT NULL,
    established_year INT NULL,
    office_location VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. majors (Ngành học)
DROP TABLE IF EXISTS majors;
CREATE TABLE majors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    major_code VARCHAR(30) NOT NULL UNIQUE,
    major_name VARCHAR(150) NOT NULL,
    faculty_id BIGINT NOT NULL,
    total_credits INT DEFAULT 120,
    CONSTRAINT fk_majors_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. classes (Lớp hành chính)
DROP TABLE IF EXISTS classes;
CREATE TABLE classes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    class_code VARCHAR(30) NOT NULL UNIQUE,
    class_name VARCHAR(100) NOT NULL,
    major_id BIGINT NOT NULL,
    academic_year VARCHAR(20) NOT NULL COMMENT 'Ví dụ: 2024-2028',
    advisor_name VARCHAR(100) NULL,
    CONSTRAINT fk_classes_major FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. students (Hồ sơ sinh viên)
DROP TABLE IF EXISTS students;
CREATE TABLE students (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    student_code VARCHAR(30) NOT NULL UNIQUE,
    identity_number VARCHAR(20) NULL UNIQUE,
    date_of_birth DATE NULL,
    gender VARCHAR(10) NULL COMMENT 'MALE, FEMALE, OTHER',
    address VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    class_id BIGINT NOT NULL,
    admission_date DATE NULL,
    status VARCHAR(30) DEFAULT 'STUDYING' COMMENT 'STUDYING, SUSPENDED, GRADUATED, DROPPED',
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE RESTRICT,
    INDEX idx_student_code (student_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. teachers (Hồ sơ giảng viên)
DROP TABLE IF EXISTS teachers;
CREATE TABLE teachers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    teacher_code VARCHAR(30) NOT NULL UNIQUE,
    faculty_id BIGINT NOT NULL,
    academic_degree VARCHAR(50) NULL COMMENT 'BACHELOR, MASTER, PHD, PROFESSOR',
    phone VARCHAR(20) NULL,
    CONSTRAINT fk_teachers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_teachers_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. subjects (Môn học)
DROP TABLE IF EXISTS subjects;
CREATE TABLE subjects (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    subject_code VARCHAR(30) NOT NULL UNIQUE,
    subject_name VARCHAR(150) NOT NULL,
    credits INT NOT NULL DEFAULT 3,
    faculty_id BIGINT NULL,
    CONSTRAINT fk_subjects_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. semesters (Học kỳ năm học)
DROP TABLE IF EXISTS semesters;
CREATE TABLE semesters (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    semester_code VARCHAR(30) NOT NULL UNIQUE,
    semester_name VARCHAR(100) NOT NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    is_current BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. course_classes (Lớp học phần)
DROP TABLE IF EXISTS course_classes;
CREATE TABLE course_classes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_class_code VARCHAR(50) NOT NULL UNIQUE,
    subject_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    max_students INT DEFAULT 50,
    room_name VARCHAR(50) NULL,
    schedule_description VARCHAR(255) NULL,
    CONSTRAINT fk_course_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    CONSTRAINT fk_course_semester FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE,
    CONSTRAINT fk_course_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. enrollments (Đăng ký học phần của sinh viên)
DROP TABLE IF EXISTS enrollments;
CREATE TABLE enrollments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    course_class_id BIGINT NOT NULL,
    enrolled_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'ENROLLED' COMMENT 'ENROLLED, DROPPED, COMPLETED',
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_enroll_course FOREIGN KEY (course_class_id) REFERENCES course_classes(id) ON DELETE CASCADE,
    UNIQUE KEY uk_student_course (student_id, course_class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. exam_schedules (Lịch thi)
DROP TABLE IF EXISTS exam_schedules;
CREATE TABLE exam_schedules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_class_id BIGINT NOT NULL,
    exam_date DATETIME NOT NULL,
    room_name VARCHAR(50) NOT NULL,
    duration_minutes INT DEFAULT 60,
    exam_form VARCHAR(50) DEFAULT 'WRITTEN' COMMENT 'WRITTEN, PRACTICAL, ONLINE',
    CONSTRAINT fk_exam_course FOREIGN KEY (course_class_id) REFERENCES course_classes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. exam_scores (Bảng điểm thi chi tiết)
DROP TABLE IF EXISTS exam_scores;
CREATE TABLE exam_scores (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    enrollment_id BIGINT NOT NULL UNIQUE,
    attendance_score DECIMAL(4,2) NULL COMMENT 'Điểm chuyên cần (10%)',
    midterm_score DECIMAL(4,2) NULL COMMENT 'Điểm giữa kỳ (30%)',
    final_score DECIMAL(4,2) NULL COMMENT 'Điểm cuối kỳ (60%)',
    total_score DECIMAL(4,2) NULL COMMENT 'Điểm tổng kết hệ 10',
    letter_grade VARCHAR(5) NULL COMMENT 'A, B, C, D, F',
    gpa_4 DECIMAL(3,2) NULL COMMENT 'Điểm quy đổi hệ 4',
    CONSTRAINT fk_scores_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. tuition_fees (Quản lý học phí)
DROP TABLE IF EXISTS tuition_fees;
CREATE TABLE tuition_fees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0.00,
    payment_status VARCHAR(30) DEFAULT 'UNPAID' COMMENT 'UNPAID, PARTIAL, PAID',
    due_date DATE NULL,
    CONSTRAINT fk_tuition_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_tuition_semester FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. scholarships (Danh mục học bổng)
DROP TABLE IF EXISTS scholarships;
CREATE TABLE scholarships (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scholarship_code VARCHAR(30) NOT NULL UNIQUE,
    scholarship_name VARCHAR(150) NOT NULL,
    fund_amount DECIMAL(12,2) NOT NULL,
    criteria_description TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. student_scholarships (Sinh viên nhận học bổng)
DROP TABLE IF EXISTS student_scholarships;
CREATE TABLE student_scholarships (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    scholarship_id BIGINT NOT NULL,
    awarded_date DATE NULL,
    amount_received DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_stusch_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_stusch_scholarship FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. dormitory_rooms (Quản lý Ký túc xá)
DROP TABLE IF EXISTS dormitory_rooms;
CREATE TABLE dormitory_rooms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    building_name VARCHAR(50) NOT NULL,
    capacity INT DEFAULT 4,
    current_occupants INT DEFAULT 0,
    price_per_month DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. dormitory_contracts (Hợp đồng KTX)
DROP TABLE IF EXISTS dormitory_contracts;
CREATE TABLE dormitory_contracts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT NOT NULL,
    room_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, TERMINATED',
    CONSTRAINT fk_dom_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_dom_room FOREIGN KEY (room_id) REFERENCES dormitory_rooms(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. support_tickets (Yêu cầu hỗ trợ sinh viên)
DROP TABLE IF EXISTS support_tickets;
CREATE TABLE support_tickets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticket_code VARCHAR(30) NOT NULL UNIQUE,
    student_id BIGINT NOT NULL,
    category VARCHAR(50) NOT NULL COMMENT 'TUITION, CERTIFICATE, FACILITY, ACADEMIC',
    subject VARCHAR(200) NOT NULL,
    description TEXT NULL,
    admin_response TEXT NULL,
    status VARCHAR(30) DEFAULT 'OPEN' COMMENT 'OPEN, IN_PROGRESS, RESOLVED, CLOSED',
    CONSTRAINT fk_tickets_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 22. notifications (Thông báo hệ thống)
DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    target_url VARCHAR(255) NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 23. notification_templates (Mẫu thông báo tự động)
DROP TABLE IF EXISTS notification_templates;
CREATE TABLE notification_templates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    template_key VARCHAR(50) NOT NULL UNIQUE,
    subject_pattern VARCHAR(255) NOT NULL,
    body_html_pattern TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 24. system_devices (Thiết bị điểm danh / phòng học thông minh)
DROP TABLE IF EXISTS system_devices;
CREATE TABLE system_devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_name VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45) NULL,
    status VARCHAR(20) DEFAULT 'ONLINE' COMMENT 'ONLINE, OFFLINE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 25. audit_logs (Nhật ký hoạt động hệ thống)
DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    action_code VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NULL,
    old_values_json TEXT NULL,
    new_values_json TEXT NULL,
    ip_address VARCHAR(45) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;