
CREATE DATABASE IF NOT EXISTS intern_management
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE intern_management;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS saved_filters, intern_profiles, mentors, internship_programs,
  school_aliases, schools, majors, departments, user_roles, users, roles;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE roles (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  role_code   VARCHAR(30)  NOT NULL COMMENT 'ADMIN, HR_MANAGER, MENTOR, INTERN',
  role_name   VARCHAR(100) NOT NULL,
  description VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_roles_code (role_code)
) ENGINE=InnoDB COMMENT='Danh mục vai trò';

CREATE TABLE users (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  username      VARCHAR(50)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL COMMENT 'Bcrypt/Argon2',
  email         VARCHAR(100) NOT NULL,
  full_name     VARCHAR(100) NOT NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  last_login_at DATETIME     NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_username (username),
  UNIQUE KEY uk_users_email (email),
  KEY idx_users_full_name (full_name),               -- tìm kiếm theo tên
  CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE','INACTIVE','LOCKED'))
) ENGINE=InnoDB COMMENT='Tài khoản (Admin, HR, Mentor, TTS)';

CREATE TABLE user_roles (
  user_id     BIGINT   NOT NULL,
  role_id     BIGINT   NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='N-M giữa users và roles (HR cần role HR_MANAGER để vào màn hình DS TTS)';

CREATE TABLE schools (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  school_code VARCHAR(30)  NOT NULL COMMENT 'Mã trường chuẩn, vd: HUST, NEU',
  school_name VARCHAR(150) NOT NULL COMMENT 'Tên chính thức',
  short_name  VARCHAR(50)  NULL     COMMENT 'Tên viết tắt hiển thị',
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_schools_code (school_code),
  UNIQUE KEY uk_schools_name (school_name)
) ENGINE=InnoDB COMMENT='Danh mục Trường (dropdown lọc)';

CREATE TABLE school_aliases (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  school_id  BIGINT       NOT NULL,
  alias_name VARCHAR(150) NOT NULL COMMENT 'Tên gọi khác: BKHN, ĐH Bách Khoa HN...',
  PRIMARY KEY (id),
  UNIQUE KEY uk_alias (alias_name),
  CONSTRAINT fk_alias_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Tên gọi khác của trường - hỗ trợ tìm gần đúng (ngoại lệ A2)';

CREATE TABLE majors (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  major_code VARCHAR(30)  NOT NULL COMMENT 'vd: IT, SE, BA',
  major_name VARCHAR(100) NOT NULL,
  is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_majors_code (major_code),
  UNIQUE KEY uk_majors_name (major_name)
) ENGINE=InnoDB COMMENT='Danh mục Ngành/Chuyên ngành (dropdown lọc)';

CREATE TABLE departments (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  dept_code  VARCHAR(30)  NOT NULL,
  dept_name  VARCHAR(150) NOT NULL,
  head_name  VARCHAR(100) NULL,
  is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_dept_code (dept_code)
) ENGINE=InnoDB COMMENT='Phòng ban tiếp nhận TTS';

CREATE TABLE internship_programs (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  program_code  VARCHAR(50)  NOT NULL COMMENT 'vd: TTCS_K10_2026',
  program_name  VARCHAR(200) NOT NULL,
  department_id BIGINT       NOT NULL,
  quota_count   INT          NULL,
  start_date    DATE         NULL,
  end_date      DATE         NULL,
  description   TEXT         NULL,
  status        VARCHAR(30)  NOT NULL DEFAULT 'PLANNING',
  PRIMARY KEY (id),
  UNIQUE KEY uk_program_code (program_code),
  CONSTRAINT fk_prog_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  CONSTRAINT chk_prog_status CHECK (status IN ('PLANNING','ACTIVE','COMPLETED','CANCELLED')),
  CONSTRAINT chk_prog_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB COMMENT='Đợt/chương trình thực tập';

CREATE TABLE mentors (
  id            BIGINT      NOT NULL AUTO_INCREMENT,
  user_id       BIGINT      NOT NULL,
  mentor_code   VARCHAR(30) NOT NULL,
  department_id BIGINT      NOT NULL,
  job_title     VARCHAR(100) NULL,
  max_capacity  INT         NOT NULL DEFAULT 5,
  status        VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (id),
  UNIQUE KEY uk_mentor_user (user_id),
  UNIQUE KEY uk_mentor_code (mentor_code),
  CONSTRAINT fk_mentor_user FOREIGN KEY (user_id)       REFERENCES users(id)       ON DELETE RESTRICT,
  CONSTRAINT fk_mentor_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
  CONSTRAINT chk_mentor_status CHECK (status IN ('ACTIVE','INACTIVE'))
) ENGINE=InnoDB COMMENT='Người hướng dẫn (dùng cho bộ lọc mở rộng: theo Mentor)';

CREATE TABLE intern_profiles (
  id                BIGINT       NOT NULL AUTO_INCREMENT,
  user_id           BIGINT       NOT NULL COMMENT '1-1 tới users (tên, email nằm ở users)',
  intern_code       VARCHAR(30)  NOT NULL COMMENT 'vd: TTS001',
  student_code      VARCHAR(30)  NULL     COMMENT 'Mã sinh viên (tìm kiếm theo mã SV)',
  identity_number   VARCHAR(20)  NULL     COMMENT 'CCCD/CMND',
  date_of_birth     DATE         NULL,
  gender            VARCHAR(10)  NULL,
  phone             VARCHAR(20)  NULL,
  address           VARCHAR(255) NULL,
  school_id         BIGINT       NOT NULL COMMENT 'FK -> schools (thay university_name)',
  major_id          BIGINT       NOT NULL COMMENT 'FK -> majors  (thay major_name)',
  program_id        BIGINT       NULL,
  mentor_id         BIGINT       NULL,
  start_date        DATE         NULL,
  end_date          DATE         NULL,
  bank_account_no   VARCHAR(30)  NULL,
  bank_name         VARCHAR(100) NULL,
  internship_status VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE' COMMENT 'Trạng thái hồ sơ/thực tập',
  created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_intern_user (user_id),
  UNIQUE KEY uk_intern_code (intern_code),
  UNIQUE KEY uk_intern_student_code (student_code),
  UNIQUE KEY uk_intern_identity (identity_number),

  -- Index phục vụ bộ lọc (yêu cầu phi chức năng: < 1-2s khi dữ liệu lớn)
  KEY idx_intern_school       (school_id),
  KEY idx_intern_major        (major_id),
  KEY idx_intern_school_major (school_id, major_id, internship_status),  -- lọc kết hợp (AND)
  KEY idx_intern_status       (internship_status),
  KEY idx_intern_start_date   (start_date),
  KEY idx_intern_program      (program_id),
  KEY idx_intern_mentor       (mentor_id),

  CONSTRAINT fk_intern_user    FOREIGN KEY (user_id)    REFERENCES users(id)               ON DELETE RESTRICT,
  CONSTRAINT fk_intern_school  FOREIGN KEY (school_id)  REFERENCES schools(id)             ON DELETE RESTRICT,
  CONSTRAINT fk_intern_major   FOREIGN KEY (major_id)   REFERENCES majors(id)              ON DELETE RESTRICT,
  CONSTRAINT fk_intern_program FOREIGN KEY (program_id) REFERENCES internship_programs(id) ON DELETE RESTRICT,
  CONSTRAINT fk_intern_mentor  FOREIGN KEY (mentor_id)  REFERENCES mentors(id)             ON DELETE RESTRICT,
  CONSTRAINT chk_intern_gender CHECK (gender IS NULL OR gender IN ('MALE','FEMALE','OTHER')),
  CONSTRAINT chk_intern_status CHECK (internship_status IN ('ACTIVE','COMPLETED','PAUSED','DROPPED')),
  CONSTRAINT chk_intern_dates  CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
) ENGINE=InnoDB COMMENT='Hồ sơ thực tập sinh - bảng trung tâm của chức năng tìm kiếm/lọc';

CREATE TABLE saved_filters (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  user_id     BIGINT       NOT NULL COMMENT 'HR sở hữu bộ lọc',
  filter_name VARCHAR(100) NOT NULL,
  filter_json JSON         NOT NULL COMMENT 'vd: {"school_ids":[1,2],"major_ids":[3],"status":["ACTIVE"]}',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_filter_user_name (user_id, filter_name),
  CONSTRAINT fk_sf_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Bộ lọc đã lưu (tùy chọn nâng cao)';

INSERT INTO roles (role_code, role_name, description) VALUES
 ('ADMIN','Quản trị viên','Toàn quyền hệ thống'),
 ('HR_MANAGER','Cán bộ HR','Quản lý hồ sơ TTS'),
 ('MENTOR','Mentor','Người hướng dẫn'),
 ('INTERN','Thực tập sinh','Tài khoản TTS');

INSERT INTO users (username, password_hash, email, full_name) VALUES
 ('hr01','$2b$10$hashmau','hr01@company.vn','Nguyễn Thị HR'),
 ('mentor01','$2b$10$hashmau','mentor01@company.vn','Trần Văn Mentor'),
 ('tts001','$2b$10$hashmau','an.nv@sv.hust.edu.vn','Nguyễn Văn An'),
 ('tts002','$2b$10$hashmau','binh.tt@sv.hust.edu.vn','Trần Thị Bình'),
 ('tts003','$2b$10$hashmau','cuong.lm@sv.neu.edu.vn','Lê Minh Cường'),
 ('tts004','$2b$10$hashmau','dung.pt@sv.tnut.edu.vn','Phạm Thùy Dung');

INSERT INTO user_roles (user_id, role_id) VALUES (1,2),(2,3),(3,4),(4,4),(5,4),(6,4);

INSERT INTO schools (school_code, school_name, short_name) VALUES
 ('HUST','Đại học Bách Khoa Hà Nội','ĐHBK HN'),
 ('NEU','Đại học Kinh tế Quốc dân','KTQD'),
 ('TNUT','Đại học Kỹ thuật Công nghiệp Thái Nguyên','ĐHKTCN TN');

INSERT INTO school_aliases (school_id, alias_name) VALUES
 (1,'BKHN'),(1,'Bách Khoa HN'),(1,'ĐH Bách Khoa'),(2,'NEU'),(3,'KTCN Thái Nguyên');

INSERT INTO majors (major_code, major_name) VALUES
 ('IT','Công nghệ thông tin'),
 ('SE','Kỹ thuật phần mềm'),
 ('BA','Quản trị kinh doanh'),
 ('EE','Điện - Điện tử');

INSERT INTO departments (dept_code, dept_name, head_name) VALUES
 ('DEV_CENTER','Trung tâm Phát triển Phần mềm','Lê Trưởng Phòng');

INSERT INTO internship_programs (program_code, program_name, department_id, quota_count, start_date, end_date, status) VALUES
 ('TTCS_K10_2026','Chương trình TTCS K10 Sáu tháng',1,50,'2026-09-01','2027-02-28','ACTIVE');

INSERT INTO mentors (user_id, mentor_code, department_id, job_title) VALUES
 (2,'MNT001',1,'Senior Fullstack Developer');

INSERT INTO intern_profiles
 (user_id, intern_code, student_code, school_id, major_id, program_id, mentor_id, start_date, end_date, internship_status) VALUES
 (3,'TTS001','20210001',1,1,1,1,'2026-09-01','2027-02-28','ACTIVE'),
 (4,'TTS002','20210002',1,2,1,1,'2026-09-01','2027-02-28','ACTIVE'),
 (5,'TTS003','11210003',2,3,1,1,'2026-09-15','2027-02-28','PAUSED'),
 (6,'TTS004','K205480001',3,1,1,1,'2026-09-01','2027-02-28','ACTIVE');

-- AC1: Lọc theo Trường = Đại học Bách Khoa Hà Nội
SELECT ip.intern_code, ip.student_code, u.full_name, u.email, s.school_name, m.major_name, ip.internship_status
FROM intern_profiles ip
JOIN users   u ON u.id = ip.user_id
JOIN schools s ON s.id = ip.school_id
JOIN majors  m ON m.id = ip.major_id
WHERE ip.school_id = (SELECT id FROM schools WHERE school_code = 'HUST');

-- AC2: Trường + Ngành (AND) + multi-select + trạng thái + khoảng ngày bắt đầu + từ khóa
--      Các điều kiện không chọn thì bỏ khỏi WHERE (build động ở backend).
SELECT SQL_CALC_FOUND_ROWS
       ip.id, ip.intern_code, ip.student_code, u.full_name, u.email,
       s.school_name, m.major_name, ip.internship_status, ip.start_date
FROM intern_profiles ip
JOIN users   u ON u.id = ip.user_id
JOIN schools s ON s.id = ip.school_id
JOIN majors  m ON m.id = ip.major_id
WHERE ip.school_id IN (1, 2)                       -- multi-select Trường
  AND ip.major_id  IN (1, 2)                       -- multi-select Ngành
  AND ip.internship_status IN ('ACTIVE','PAUSED')  -- Trạng thái
  AND ip.start_date BETWEEN '2026-09-01' AND '2026-12-31'
  AND (u.full_name LIKE '%An%' OR ip.student_code LIKE '%An%' OR u.email LIKE '%An%')
ORDER BY u.full_name ASC
LIMIT 20 OFFSET 0;                                 -- A4: phân trang

-- A2: Tìm trường gần đúng qua alias (người dùng gõ "BKHN")
SELECT DISTINCT s.id, s.school_name
FROM schools s
LEFT JOIN school_aliases a ON a.school_id = s.id
WHERE s.school_name LIKE '%BKHN%' OR s.short_name LIKE '%BKHN%' OR a.alias_name LIKE '%BKHN%';

-- AC3: Không có kết quả -> backend trả mảng rỗng, UI hiển thị
--      "Không tìm thấy kết quả phù hợp"
SELECT ip.id FROM intern_profiles ip
WHERE ip.school_id = 3 AND ip.major_id = 4;

-- AC4: "Xóa bộ lọc" = bỏ toàn bộ WHERE (chỉ giữ phân trang/sắp xếp mặc định)
SELECT ip.intern_code, u.full_name, s.school_name, m.major_name
FROM intern_profiles ip
JOIN users u ON u.id = ip.user_id
JOIN schools s ON s.id = ip.school_id
JOIN majors  m ON m.id = ip.major_id
ORDER BY ip.created_at DESC LIMIT 20 OFFSET 0;

-- Thống kê số TTS theo Trường/Ngành (phục vụ báo cáo của Trưởng phòng)
SELECT s.school_name, m.major_name, COUNT(*) AS so_tts
FROM intern_profiles ip
JOIN schools s ON s.id = ip.school_id
JOIN majors  m ON m.id = ip.major_id
GROUP BY s.school_name, m.major_name
ORDER BY so_tts DESC;
