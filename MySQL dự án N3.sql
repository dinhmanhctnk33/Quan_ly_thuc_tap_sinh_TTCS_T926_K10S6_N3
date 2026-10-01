DROP DATABASE IF EXISTS internship_management_db;
CREATE DATABASE internship_management_db 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE internship_management_db;

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(30) NOT NULL DEFAULT 'ROLE_INTERN',
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_ACTIVATION', 
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE internship_programs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    program_name VARCHAR(150) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(30) DEFAULT 'OPEN', 
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE mentors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNIQUE,
    department VARCHAR(100),
    job_title VARCHAR(100),
    max_interns INT DEFAULT 5,
    CONSTRAINT fk_mentor_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE intern_profiles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    intern_code VARCHAR(30) NOT NULL UNIQUE,
    identity_number VARCHAR(20) UNIQUE,
    date_of_birth DATE,
    gender VARCHAR(10),                              -- MALE, FEMALE, OTHER
    address VARCHAR(255),
    university_name VARCHAR(150) NOT NULL,
    major_name VARCHAR(100) NOT NULL,
    program_id BIGINT,
    mentor_id BIGINT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    bank_account_no VARCHAR(30),
    bank_name VARCHAR(100),
    internship_status VARCHAR(30) DEFAULT 'ACTIVE',  -- ACTIVE, COMPLETED, PAUSED, DROPPED
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_profile_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_profile_program FOREIGN KEY (program_id) REFERENCES internship_programs(id) ON DELETE SET NULL,
    CONSTRAINT fk_profile_mentor FOREIGN KEY (mentor_id) REFERENCES mentors(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE intern_documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    intern_profile_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,           
    file_name VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    approval_status VARCHAR(30) DEFAULT 'PENDING',   
    rejection_note TEXT,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_document_profile FOREIGN KEY (intern_profile_id) REFERENCES intern_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_intern_profiles_code ON intern_profiles(intern_code);
CREATE INDEX idx_intern_profiles_status ON intern_profiles(internship_status);
CREATE INDEX idx_intern_documents_status ON intern_documents(approval_status);