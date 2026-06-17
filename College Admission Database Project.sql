CREATE DATABASE CollegeAdmissionDB;
USE CollegeAdmissionDB;

-- =========================================================================
-- PHASE 1: CORE INFRASTRUCTURE & ACADEMICS
-- =========================================================================

-- 1. Departments Table
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    building_location VARCHAR(100)
);

-- 2. Programs Table (Degrees offered)
CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY,
    program_name VARCHAR(100) NOT NULL,
    degree_type ENUM('Undergraduate', 'Postgraduate', 'PhD') NOT NULL,
    department_id INT,
    total_credits_required INT DEFAULT 120,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 3. Courses Table (Individual subjects)
CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    credits INT DEFAULT 3,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 4. Academic Terms Table
CREATE TABLE academic_terms (
    term_id INT AUTO_INCREMENT PRIMARY KEY,
    term_name VARCHAR(50) NOT NULL, -- e.g., 'Fall 2026'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE
);

-- 5. Faculty Table
CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- =========================================================================
-- PHASE 2: APPLICANTS & ADMISSION PIPELINE
-- =========================================================================

-- 6. Applicants Table (Before becoming formal students)
CREATE TABLE applicants (
    applicant_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    high_school_gpa DECIMAL(3,2),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Admission Applications Table
CREATE TABLE applications (
    application_id INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT,
    program_id INT,
    term_id INT,
    application_status ENUM('Submitted', 'Under Review', 'Accepted', 'Rejected', 'Waitlisted') DEFAULT 'Submitted',
    submission_date DATE DEFAULT (CURRENT_DATE),
    reviewer_comments TEXT,
    FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES programs(program_id),
    FOREIGN KEY (term_id) REFERENCES academic_terms(term_id)
);

-- 8. Document Verification Table
CREATE TABLE document_checks (
    document_id INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT,
    document_type ENUM('Transcripts', 'National ID', 'Recommendation Letter', 'SAT_ACT_Scores') NOT NULL,
    verification_status ENUM('Pending', 'Verified', 'Rejected') DEFAULT 'Pending',
    verified_by_faculty_id INT,
    FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_faculty_id) REFERENCES faculty(faculty_id)
);

-- =========================================================================
-- PHASE 3: ACTIVE ENROLLED STUDENTS
-- =========================================================================

-- 9. Active Students Table (Promoted from accepted applicants)
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id INT UNIQUE, -- Links back to their original application profile
    student_roll_number VARCHAR(15) UNIQUE NOT NULL, -- Matched against university layout
    program_id INT,
    current_semester INT DEFAULT 1,
    enrollment_status ENUM('Active', 'On Leave', 'Graduated', 'Dropped Out') DEFAULT 'Active',
    academic_advisor_id INT,
    FOREIGN KEY (applicant_id) REFERENCES applicants(applicant_id),
    FOREIGN KEY (program_id) REFERENCES programs(program_id),
    FOREIGN KEY (academic_advisor_id) REFERENCES faculty(faculty_id)
);

-- 10. Class Sections Table (Specific classes running in a term)
CREATE TABLE class_sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT,
    faculty_id INT,
    term_id INT,
    room_number VARCHAR(20),
    max_capacity INT DEFAULT 30,
    current_enrollment_count INT DEFAULT 0,
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id),
    FOREIGN KEY (term_id) REFERENCES academic_terms(term_id)
);

-- 11. Student Course Enrollments Table (Many-to-Many Bridge)
CREATE TABLE course_enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    section_id INT,
    final_grade CHAR(2) DEFAULT NULL, -- e.g., 'A', 'B+', 'F'
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES class_sections(section_id)
);

-- =========================================================================
-- PHASE 4: BILLING, HOUSING & SECURITY AUDITS
-- =========================================================================

-- 12. Tuition Fees Table
CREATE TABLE tuition_billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    term_id INT,
    total_owed DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) DEFAULT 0.00,
    payment_status ENUM('Unpaid', 'Partially Paid', 'Fully Paid') AS 
        (CASE 
            WHEN amount_paid = 0 THEN 'Unpaid'
            WHEN amount_paid < total_owed THEN 'Partially Paid'
            ELSE 'Fully Paid'
        END),
    due_date DATE NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (term_id) REFERENCES academic_terms(term_id)
);

-- 13. Scholarships Table
CREATE TABLE scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    scholarship_name VARCHAR(100) NOT NULL,
    discount_percentage DECIMAL(5,2) CHECK (discount_percentage BETWEEN 0 AND 100),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
);

-- 14. Hostel Dormitory Allocations Table
CREATE TABLE dorm_allocations (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNIQUE,
    building_name VARCHAR(50) NOT NULL,
    room_number INT NOT NULL,
    monthly_rent DECIMAL(8,2),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- 15. Audit Log Table (Tracks background alterations automatically)
CREATE TABLE status_change_audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_value VARCHAR(100),
    new_value VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

USE CollegeAdmissionDB;
USE CollegeAdmissionDB;

-- =========================================================================
-- PHASE 1: CORE INFRASTRUCTURE & ACADEMICS
-- =========================================================================

-- 1. Insert Departments
INSERT INTO departments (department_name, building_location) VALUES
('Computer Science & Engineering', 'Alan Turing Block, Floor 3'),
('Electrical & Electronics Engineering', 'Tesla Lab, Floor 1'),
('Business Administration', 'Adam Smith Hall, Floor 2'),
('Natural Sciences', 'Marie Curie Pavilion, Floor 4');

-- 2. Insert Programs
INSERT INTO programs (program_name, degree_type, department_id, total_credits_required) VALUES
('B.Tech Computer Science', 'Undergraduate', 1, 120),
('M.Tech Data Science', 'Postgraduate', 1, 60),
('B.Tech Electrical Engineering', 'Undergraduate', 2, 124),
('MBA Finance', 'Postgraduate', 3, 64),
('PhD Physics', 'PhD', 4, 36);

-- 3. Insert Courses
INSERT INTO courses (course_code, course_name, credits, department_id) VALUES
('CS101', 'Introduction to Programming', 3, 1),
('CS202', 'Database Management Systems', 4, 1),
('EE110', 'Basic Circuit Analysis', 3, 2),
('BA501', 'Corporate Financial Strategy', 4, 3),
('PH901', 'Advanced Quantum Mechanics', 4, 4);

-- 4. Insert Academic Terms
INSERT INTO academic_terms (term_name, start_date, end_date, is_active) VALUES
('Fall 2025', '2025-09-01', '2025-12-20', FALSE),
('Spring 2026', '2026-01-10', '2026-05-15', TRUE),
('Fall 2026', '2026-09-02', '2026-12-22', FALSE);

-- 5. Insert Faculty
INSERT INTO faculty (first_name, last_name, email, department_id) VALUES
('Charles', 'Babbage', 'c.babbage@university.edu', 1),
('Grace', 'Hopper', 'g.hopper@university.edu', 1),
('Nikola', 'Tesla', 'n.tesla@university.edu', 2),
('Warren', 'Buffett', 'w.buffett@university.edu', 3),
('Albert', 'Einstein', 'a.einstein@university.edu', 4);


-- =========================================================================
-- PHASE 2: APPLICANTS & ADMISSION PIPELINE
-- =========================================================================

-- 6. Insert Applicants
INSERT INTO applicants (first_name, last_name, email, phone, date_of_birth, high_school_gpa) VALUES
('John', 'Doe', 'john.doe@email.com', '+1234567890', '2005-04-12', 3.85),
('Jane', 'Smith', 'jane.smith@email.com', '+1234567891', '2004-11-23', 3.92),
('Robert', 'Lee', 'robert.lee@email.com', '+1234567892', '2005-01-05', 2.70),
('Emily', 'Davis', 'emily.davis@email.com', '+1234567893', '2003-07-19', 3.65),
('Michael', 'Brown', 'michael.b@email.com', '+1234567894', '1998-05-30', 3.98);

-- 7. Insert Admission Applications
INSERT INTO applications (applicant_id, program_id, term_id, application_status, reviewer_comments) VALUES
(1, 1, 2, 'Accepted', 'Excellent GPA, strong personal statement.'),
(2, 1, 2, 'Accepted', 'Top tier portfolio and high school recommendations.'),
(3, 3, 2, 'Rejected', 'GPA falls below department cut-off limits.'),
(4, 4, 2, 'Accepted', 'Strong professional background matching MBA tracks.'),
(5, 5, 2, 'Under Review', 'Waiting for panel interview notes.');

-- 8. Insert Document Verification Checkpoints
INSERT INTO document_checks (applicant_id, document_type, verification_status, verified_by_faculty_id) VALUES
(1, 'Transcripts', 'Verified', 1),
(1, 'National ID', 'Verified', 1),
(2, 'Transcripts', 'Verified', 2),
(3, 'Transcripts', 'Rejected', 3),
(4, 'Recommendation Letter', 'Verified', 4);


-- =========================================================================
-- PHASE 3: ACTIVE ENROLLED STUDENTS
-- =========================================================================

-- 9. Insert Active Enrolled Students (Promoted from accepted applicants 1, 2, and 4)
INSERT INTO students (applicant_id, student_roll_number, program_id, current_semester, enrollment_status, academic_advisor_id) VALUES
(1, 'STU20260001', 1, 1, 'Active', 1),
(2, 'STU20260002', 1, 1, 'Active', 2),
(4, 'STU20260003', 4, 1, 'Active', 4);

-- 10. Insert Class Sections Running in the Active Term (Term 2)
INSERT INTO class_sections (course_id, faculty_id, term_id, room_number, max_capacity, current_enrollment_count) VALUES
(1, 1, 2, 'Turing Hall A', 30, 2),
(2, 2, 2, 'Lab Alpha', 25, 1),
(4, 4, 2, 'Business Suite 1', 40, 1);

-- 11. Insert Student Course Enrollments (Bridge Table mappings)
INSERT INTO course_enrollments (student_id, section_id, final_grade) VALUES
(1, 1, NULL), -- John enrolled in CS101
(1, 2, NULL), -- John enrolled in CS202
(2, 1, NULL), -- Jane enrolled in CS101
(3, 3, NULL); -- Emily enrolled in BA501


-- =========================================================================
-- PHASE 4: BILLING, HOUSING & SECURITY AUDITS
-- =========================================================================

-- 12. Insert Tuition Fees
INSERT INTO tuition_billing (student_id, term_id, total_owed, amount_paid, due_date) VALUES
(1, 2, 5000.00, 5000.00, '2026-02-01'), -- Fully Paid (Computed column handles status)
(2, 2, 5000.00, 2500.00, '2026-02-01'), -- Partially Paid
(3, 2, 7500.00, 0.00, '2026-02-01');    -- Unpaid

-- 13. Insert Scholarships
INSERT INTO scholarships (student_id, scholarship_name, discount_percentage) VALUES
(2, 'Presidential Merit Scholarship', 50.00),
(3, 'Corporate Partnership Grant', 15.00);

-- 14. Insert Hostel Dormitory Allocations
INSERT INTO dorm_allocations (student_id, building_name, room_number, monthly_rent) VALUES
(1, 'Edison Boys Hostel', 104, 450.00),
(2, 'Ada Lovelace Girls Hall', 302, 500.00);

-- 15. Insert Initial Audit Log Entries (Simulating past manual admin records)
INSERT INTO status_change_audit_logs (table_name, record_id, old_value, new_value) VALUES
('applications', 1, 'Submitted', 'Under Review'),
('applications', 1, 'Under Review', 'Accepted'),
('applications', 3, 'Under Review', 'Rejected');

INSERT INTO applicants (first_name, last_name, email, phone, date_of_birth, high_school_gpa) VALUES
('John', 'Brown', 'john.brown1@university.edu', '+14642376103', '2002-06-04', 3.88),
('Robert', 'Miller', 'robert.miller2@university.edu', '+16809461488', '1999-08-06', 2.96),
('William', 'Anderson', 'william.anderson3@university.edu', '+16082209021', '1998-10-13', 3.26),
('John', 'Hernandez', 'john.hernandez4@university.edu', '+16172338980', '2004-06-06', 2.23),
('Matthew', 'Thomas', 'matthew.thomas5@university.edu', '+18254038308', '1998-02-20', 3.74),
('Robert', 'Miller', 'robert.miller6@university.edu', '+18803074915', '2006-01-13', 3.93),
('Joseph', 'Moore', 'joseph.moore7@university.edu', '+13209891311', '2002-03-08', 2.34),
('Emily', 'Brown', 'emily.brown8@university.edu', '+14578622287', '2004-01-17', 2.06),
('John', 'Garcia', 'john.garcia9@university.edu', '+16101748963', '2001-07-19', 3.57),
('Mary', 'Moore', 'mary.moore10@university.edu', '+15116656213', '2001-04-06', 2.95),
('Mary', 'Anderson', 'mary.anderson11@university.edu', '+19009284179', '2003-01-13', 2.42),
('Michael', 'Gonzalez', 'michael.gonzalez12@university.edu', '+15446013243', '1998-03-23', 3.30),
('James', 'Jones', 'james.jones13@university.edu', '+13222611034', '2001-09-20', 3.71),
('Barbara', 'Thomas', 'barbara.thomas14@university.edu', '+18022162230', '2007-01-08', 3.39),
('Charles', 'Martin', 'charles.martin15@university.edu', '+14884309475', '1998-08-24', 3.37),
('Thomas', 'Moore', 'thomas.moore16@university.edu', '+14553858913', '2004-04-20', 2.89),
('William', 'Davis', 'william.davis17@university.edu', '+12337616536', '2002-03-07', 2.05),
('Linda', 'Smith', 'linda.smith18@university.edu', '+14286937465', '2002-03-17', 3.92),
('Barbara', 'Taylor', 'barbara.taylor19@university.edu', '+19836429969', '2005-11-04', 2.23),
('Christopher', 'Taylor', 'christopher.taylor20@university.edu', '+13899507956', '2004-12-06', 2.93),
('Mary', 'Davis', 'mary.davis21@university.edu', '+12357299650', '2007-06-20', 3.67),
('William', 'Gonzalez', 'william.gonzalez22@university.edu', '+13828332652', '2002-05-05', 3.74),
('Joseph', 'Miller', 'joseph.miller23@university.edu', '+19896587661', '1999-08-05', 3.25),
('Richard', 'Hernandez', 'richard.hernandez24@university.edu', '+13303641817', '1999-05-06', 3.11),
('James', 'Brown', 'james.brown25@university.edu', '+19169896914', '2000-07-04', 2.23),
('John', 'Taylor', 'john.taylor26@university.edu', '+14127425320', '2003-05-23', 3.11),
('Michael', 'Wilson', 'michael.wilson27@university.edu', '+15035743288', '1998-05-18', 3.77),
('Christopher', 'Thomas', 'christopher.thomas28@university.edu', '+14144224103', '2007-01-18', 2.74),
('Matthew', 'Thomas', 'matthew.thomas29@university.edu', '+12709466788', '2000-04-11', 2.22),
('Thomas', 'Rodriguez', 'thomas.rodriguez30@university.edu', '+13737931374', '2001-04-23', 3.05),
('Thomas', 'Wilson', 'thomas.wilson31@university.edu', '+16195046958', '2007-04-24', 3.88),
('Thomas', 'Johnson', 'thomas.johnson32@university.edu', '+17644647815', '2006-01-14', 2.13),
('Barbara', 'Wilson', 'barbara.wilson33@university.edu', '+18766514658', '1998-12-01', 2.43),
('Linda', 'Wilson', 'linda.wilson34@university.edu', '+13246225874', '2003-11-26', 2.24),
('William', 'Anderson', 'william.anderson35@university.edu', '+13028765180', '2006-06-04', 3.73),
('Barbara', 'Rodriguez', 'barbara.rodriguez36@university.edu', '+18208899365', '2003-01-05', 3.49),
('Linda', 'Williams', 'linda.williams37@university.edu', '+15771061505', '1999-12-09', 3.24),
('William', 'Brown', 'william.brown38@university.edu', '+13504777650', '2004-05-11', 3.36),
('Charles', 'Thomas', 'charles.thomas39@university.edu', '+12395414979', '2005-12-05', 3.98),
('Christopher', 'Martin', 'christopher.martin40@university.edu', '+14357554959', '2007-08-27', 3.16),
('William', 'Gonzalez', 'william.gonzalez41@university.edu', '+18516706665', '2005-06-01', 3.25),
('John', 'Anderson', 'john.anderson42@university.edu', '+13742303182', '2001-11-27', 3.85),
('Sarah', 'Wilson', 'sarah.wilson43@university.edu', '+18335636383', '2002-03-16', 3.84),
('James', 'Martin', 'james.martin44@university.edu', '+16388636931', '2003-12-16', 4.00),
('Richard', 'Davis', 'richard.davis45@university.edu', '+12982269114', '2005-12-14', 2.67),
('Robert', 'Jones', 'robert.jones46@university.edu', '+14025501021', '2001-07-26', 3.05),
('John', 'Miller', 'john.miller47@university.edu', '+17628156687', '2005-03-28', 3.03),
('William', 'Miller', 'william.miller48@university.edu', '+14632749078', '2004-01-25', 2.73),
('Charles', 'Brown', 'charles.brown49@university.edu', '+14115363341', '1998-04-26', 3.75),
('Barbara', 'Smith', 'barbara.smith50@university.edu', '+15651381490', '2002-12-16', 3.23);

INSERT INTO applicants (first_name, last_name, email, phone, date_of_birth, high_school_gpa) VALUES
('Emily', 'Jackson', 'emily.jackson51@university.edu', '+17056318555', '2000-01-02', 2.50),
('David', 'Garcia', 'david.garcia52@university.edu', '+14246916938', '2003-03-17', 2.40),
('Charles', 'Williams', 'charles.williams53@university.edu', '+18818253283', '2003-12-16', 2.24),
('Charles', 'Garcia', 'charles.garcia54@university.edu', '+15433805332', '1998-01-19', 3.36),
('Matthew', 'Hernandez', 'matthew.hernandez55@university.edu', '+17416066456', '2007-10-04', 2.73),
('Joseph', 'Garcia', 'joseph.garcia56@university.edu', '+13724378956', '2000-12-21', 2.98),
('Robert', 'Rodriguez', 'robert.rodriguez57@university.edu', '+14955455945', '2002-04-21', 3.14),
('Richard', 'Smith', 'richard.smith58@university.edu', '+16799697920', '1998-10-10', 3.85),
('Matthew', 'Wilson', 'matthew.wilson59@university.edu', '+16579665807', '2001-05-12', 2.38),
('Barbara', 'Johnson', 'barbara.johnson60@university.edu', '+17198842311', '2006-04-18', 2.82),
('Charles', 'Garcia', 'charles.garcia61@university.edu', '+15103509267', '2005-11-25', 3.57),
('Jane', 'Martinez', 'jane.martinez62@university.edu', '+17517807219', '2002-12-21', 2.11),
('Charles', 'Jackson', 'charles.jackson63@university.edu', '+19206736255', '2002-12-04', 3.26),
('Richard', 'Rodriguez', 'richard.rodriguez64@university.edu', '+15357569447', '2001-12-21', 2.90),
('Robert', 'Jackson', 'robert.jackson65@university.edu', '+19388848876', '2006-01-23', 3.16),
('William', 'Lopez', 'william.lopez66@university.edu', '+13018451324', '1998-04-04', 3.15),
('Michael', 'Garcia', 'michael.garcia67@university.edu', '+13771012413', '2001-10-02', 2.24),
('Matthew', 'Miller', 'matthew.miller68@university.edu', '+15458932125', '1999-08-22', 3.85),
('David', 'Jackson', 'david.jackson69@university.edu', '+17738629319', '2006-05-18', 3.34),
('Sarah', 'Miller', 'sarah.miller70@university.edu', '+13763757874', '2004-06-17', 2.80),
('Jane', 'Williams', 'jane.williams71@university.edu', '+19595033004', '2007-12-24', 3.16),
('William', 'Davis', 'william.davis72@university.edu', '+12159047361', '2006-08-11', 3.84),
('Christopher', 'Rodriguez', 'christopher.rodriguez73@university.edu', '+12121167071', '2001-06-25', 2.87),
('John', 'Martinez', 'john.martinez74@university.edu', '+18592061597', '2005-07-16', 3.26),
('Matthew', 'Hernandez', 'matthew.hernandez75@university.edu', '+17579177247', '2004-06-09', 3.27),
('Thomas', 'Smith', 'thomas.smith76@university.edu', '+13739592703', '2005-05-03', 3.54),
('Sarah', 'Brown', 'sarah.brown77@university.edu', '+13117187434', '2005-12-13', 2.12),
('Barbara', 'Jones', 'barbara.jones78@university.edu', '+16123065831', '2005-05-07', 2.18),
('Patricia', 'Anderson', 'patricia.anderson79@university.edu', '+19456102673', '2003-03-23', 2.20),
('Daniel', 'Williams', 'daniel.williams80@university.edu', '+12625055909', '2002-06-19', 3.88),
('Joseph', 'Rodriguez', 'joseph.rodriguez81@university.edu', '+16205134869', '2001-12-18', 2.36),
('Richard', 'Jones', 'richard.jones82@university.edu', '+16068849642', '2006-07-03', 2.10),
('William', 'Gonzalez', 'william.gonzalez83@university.edu', '+13649052321', '2000-11-02', 3.29),
('Emily', 'Gonzalez', 'emily.gonzalez84@university.edu', '+16371814776', '2003-08-21', 3.08),
('Patricia', 'Williams', 'patricia.williams85@university.edu', '+13352633256', '2002-08-22', 2.05),
('Linda', 'Jackson', 'linda.jackson86@university.edu', '+19161866103', '2004-08-11', 2.84),
('Richard', 'Williams', 'richard.williams87@university.edu', '+12098227757', '2000-03-24', 2.40),
('William', 'Moore', 'william.moore88@university.edu', '+15012413888', '2007-07-06', 2.85),
('Michael', 'Taylor', 'michael.taylor89@university.edu', '+17693436356', '2002-05-12', 3.39),
('Matthew', 'Williams', 'matthew.williams90@university.edu', '+14111146285', '2003-01-07', 3.02),
('Mary', 'Jackson', 'mary.jackson91@university.edu', '+19911922129', '2004-01-28', 2.15),
('John', 'Johnson', 'john.johnson92@university.edu', '+15706738565', '2003-06-03', 3.41),
('Richard', 'Wilson', 'richard.wilson93@university.edu', '+14802767628', '2005-04-19', 2.08),
('Barbara', 'Rodriguez', 'barbara.rodriguez94@university.edu', '+18078356442', '1999-02-11', 2.39),
('Sarah', 'Davis', 'sarah.davis95@university.edu', '+18869847546', '2004-01-06', 3.68),
('David', 'Miller', 'david.miller96@university.edu', '+15996585161', '1998-06-26', 2.69),
('Jane', 'Moore', 'jane.moore97@university.edu', '+14602552398', '2001-07-28', 3.90),
('Richard', 'Anderson', 'richard.anderson98@university.edu', '+12666927514', '2002-05-06', 2.88),
('Richard', 'Anderson', 'richard.anderson99@university.edu', '+14361407103', '2000-03-05', 2.56),
('Sarah', 'Brown', 'sarah.brown100@university.edu', '+18167738541', '1999-11-07', 2.72);

SELECT 
    s.student_roll_number AS 'Roll No',
    CONCAT(a.first_name, ' ', a.last_name) AS 'Student Name',
    p.program_name AS 'Enrolled Program',
    t.total_owed AS 'Fees Invoiced',
    t.payment_status AS 'Payment Status',
    COALESCE(d.building_name, 'Commuter / No Dorm') AS 'Housing'
FROM students s
JOIN applicants a ON s.applicant_id = a.applicant_id
JOIN programs p ON s.program_id = p.program_id
JOIN tuition_billing t ON s.student_id = t.student_id
LEFT JOIN dorm_allocations d ON s.student_id = d.student_id;

-- =========================================================================
-- SYSTEM: CollegeAdmissionDB - 32 PRODUCTION-GRADE ANALYTICS & OPERATIONAL SCENARIOS
-- DESCRIPTION: Combined execution script for administrative and business intelligence metrics.
-- =========================================================================

USE CollegeAdmissionDB;

-- -------------------------------------------------------------------------
-- CATEGORY A: ADMISSION PIPELINE & APPLICATION FILTERS (SCENARIOS 1–8)
-- -------------------------------------------------------------------------

-- [Scenario 1: High Achievers Screening]
-- Intent: Extract high-potential leads for elite programs.
SELECT first_name, last_name, email, high_school_gpa 
FROM applicants 
WHERE high_school_gpa >= 3.80;

-- [Scenario 2: Stalled Application Alert]
-- Intent: Identify applicants who submitted profiles but haven't been reviewed or assigned a verdict.
SELECT application_id, applicant_id, submission_date 
FROM applications 
WHERE application_status = 'Submitted';

-- [Scenario 3: Flag Missing/Rejected Documentation]
-- Intent: Alert administrative staff to contact applicants with issues in their file verification records.
SELECT applicant_id, document_type, verification_status 
FROM document_checks 
WHERE verification_status = 'Rejected';

-- [Scenario 4: Program Popularity Analytics]
-- Intent: Rank programs by application volume to optimize future faculty hiring and resource allocations.
SELECT p.program_name, COUNT(a.application_id) AS total_applications
FROM programs p
LEFT JOIN applications a ON p.program_id = a.program_id
GROUP BY p.program_id
ORDER BY total_applications DESC;

-- [Scenario 5: Conversion Rate Tracking (Applicants to Enrolled)]
-- Intent: Calculate what percentage of applicants successfully matriculated into active student records.
SELECT 
    (SELECT COUNT(*) FROM students) / (SELECT COUNT(*) FROM applicants) * 100 AS conversion_percentage;

-- [Scenario 6: Age Distribution Metric]
-- Intent: Determine the demographic age groups of prospective students.
SELECT TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age, COUNT(*) AS count
FROM applicants
GROUP BY age;

-- [Scenario 7: Verification Load Balancing]
-- Intent: Monitor the workload distribution among your faculty document verifiers.
SELECT f.first_name, f.last_name, COUNT(d.document_id) AS checked_documents
FROM faculty f
JOIN document_checks d ON f.faculty_id = d.verified_by_faculty_id
GROUP BY f.faculty_id;

-- [Scenario 8: Purging Old Unsubmitted or Rejected Leads]
-- Intent: Safely preview records slated for background archival cleanup schedules.
SELECT a.applicant_id, app.application_status 
FROM applicants a
JOIN applications app ON a.applicant_id = app.applicant_id
WHERE app.application_status = 'Rejected';


-- -------------------------------------------------------------------------
-- CATEGORY B: ACADEMIC OPERATIONS & CAPACITY CONTROLS (SCENARIOS 9–16)
-- -------------------------------------------------------------------------

-- [Scenario 9: Roster Overfill Warning]
-- Intent: Flag class sections running exactly at or over maximum planned physical seating capacities.
SELECT section_id, room_number, max_capacity, current_enrollment_count 
FROM class_sections 
WHERE current_enrollment_count >= max_capacity;

-- [Scenario 10: Low Enrollment Section Alert]
-- Intent: Identify sections with critically low student numbers that face cancellation choices.
SELECT section_id, room_number, current_enrollment_count 
FROM class_sections 
WHERE current_enrollment_count < 5;

-- [Scenario 11: Complete Active Roster Generation]
-- Intent: Generate a clean master student lookup displaying their programmatic degree specifications.
SELECT s.student_roll_number, a.first_name, a.last_name, p.program_name 
FROM students s
JOIN applicants a ON s.applicant_id = a.applicant_id
JOIN programs p ON s.program_id = p.program_id;

-- [Scenario 12: Faculty Advisory Loads]
-- Intent: Ensure academic advisors are not overburdened with student counts.
SELECT f.first_name, f.last_name, COUNT(s.student_id) AS student_count
FROM faculty f
LEFT JOIN students s ON f.faculty_id = s.academic_advisor_id
GROUP BY f.faculty_id;

-- [Scenario 13: Dynamic Room Assignment Tracking]
-- Intent: View physical location distributions across active class instances.
SELECT room_number, COUNT(*) as sections_assigned
FROM class_sections
GROUP BY room_number;

-- [Scenario 14: Course Registration Density Reports]
-- Intent: Track which individual courses are creating structural traffic blocks.
SELECT c.course_name, COUNT(ce.enrollment_id) as enrolled_students
FROM courses c
JOIN class_sections cs ON c.course_id = cs.course_id
JOIN course_enrollments ce ON cs.section_id = ce.section_id
GROUP BY c.course_id;

-- [Scenario 15: Department Infrastructure Audit]
-- Intent: Map academic departments against the building spaces they govern.
SELECT department_name, building_location FROM departments;

-- [Scenario 16: Degree Track Breakdown]
-- Intent: Quantify how many students are enrolled across academic tiers (Undergrad vs Postgrad vs PhD).
SELECT p.degree_type, COUNT(s.student_id) AS total_enrolled
FROM programs p
JOIN students s ON p.program_id = s.program_id
GROUP BY p.degree_type;


-- -------------------------------------------------------------------------
-- CATEGORY C: FINANCIALS, HOUSING & LOGISTICS (SCENARIOS 17–24)
-- -------------------------------------------------------------------------

-- [Scenario 17: Defaulting Account Collection List]
-- Intent: Isolate students holding unpaid balances past structural deadlines.
SELECT student_id, total_owed, amount_paid 
FROM tuition_billing 
WHERE payment_status = 'Unpaid';

-- [Scenario 18: Projected vs Liquid Income Yields]
-- Intent: Analyze financial variance metrics between projected receivables and cash on hand.
SELECT SUM(total_owed) AS projected_revenue, SUM(amount_paid) AS actual_collected 
FROM tuition_billing;

-- [Scenario 19: Scholarship Impact Auditing]
-- Intent: Track total revenue offsets conceded to active institutional financial aid.
SELECT scholarship_name, AVG(discount_percentage) as average_discount 
FROM scholarships 
GROUP BY scholarship_name;

-- [Scenario 20: Dormitory Occupancy Maps]
-- Intent: Evaluate physical facility space management density metrics.
SELECT building_name, COUNT(room_number) AS occupied_rooms, SUM(monthly_rent) AS expected_rent
FROM dorm_allocations 
GROUP BY building_name;

-- [Scenario 21: High Financial Value Dorm Residents]
-- Intent: Target luxury infrastructure users who also hold unpaid primary tuition flags.
SELECT d.student_id, d.building_name, t.payment_status
FROM dorm_allocations d
JOIN tuition_billing t ON d.student_id = t.student_id
WHERE d.monthly_rent > 480.00;

-- [Scenario 22: Partially Paid Balance Recovery List]
-- Intent: Extract specific student targets for micro-installment updates.
SELECT student_id, (total_owed - amount_paid) AS balance_remaining 
FROM tuition_billing 
WHERE payment_status = 'Partially Paid';

-- [Scenario 23: Commuter Student Profiles]
-- Intent: Identify off-campus students to target with campus transport initiatives.
SELECT s.student_roll_number 
FROM students s
LEFT JOIN dorm_allocations d ON s.student_id = d.student_id
WHERE d.allocation_id IS NULL;

-- [Scenario 24: Critical Due Date Monitor]
-- Intent: Filter accounts breaching financial collection frames within immediate horizons.
SELECT student_id, due_date FROM tuition_billing WHERE due_date <= '2026-03-01';


-- -------------------------------------------------------------------------
-- CATEGORY D: ACADEMIC HISTORY, PERFORMANCE & SECURITY (SCENARIOS 25–32)
-- -------------------------------------------------------------------------

-- [Scenario 25: Grade Distribution & Performance Audits]
-- Intent: Check how many courses have completed grade distribution mappings for historical tracking.
SELECT final_grade, COUNT(*) AS count 
FROM course_enrollments 
GROUP BY final_grade;

-- [Scenario 26: Incomplete Grade Flags]
-- Intent: Pull profiles currently finishing classes that have pending final exam returns.
SELECT student_id, section_id 
FROM course_enrollments 
WHERE final_grade IS NULL;

-- [Scenario 27: Security Footprint Audit Logging]
-- Intent: Monitor manual administrative state overrides on important pipeline structures.
SELECT table_name, old_value, new_value, changed_at 
FROM status_change_audit_logs 
ORDER BY changed_at DESC;

-- [Scenario 28: Status Isolation Checks]
-- Intent: Pull counts of non-standard student trajectories (On Leave/Dropped Out) for retention campaigns.
SELECT enrollment_status, COUNT(*) 
FROM students 
GROUP BY enrollment_status;

-- [Scenario 29: Multi-Section Course Check]
-- Intent: Find courses operating multiple simultaneous section rooms.
SELECT course_id, COUNT(section_id) as total_sections 
FROM class_sections 
GROUP BY course_id 
HAVING total_sections > 1;

-- [Scenario 30: Term Structural Framework Check]
-- Intent: Isolate active university timelines from future staging schemas.
SELECT term_name FROM academic_terms WHERE is_active = TRUE;

-- [Scenario 31: Student Contact Ledger]
-- Intent: Compile parent/student phone directories for urgent alert infrastructure routing.
SELECT s.student_roll_number, a.phone, a.email
FROM students s
JOIN applicants a ON s.applicant_id = a.applicant_id;

-- [Scenario 32: Academic Advisor Contact Map]
-- Intent: Show students exactly who to contact for programmatic path updates.
SELECT s.student_roll_number, f.first_name AS advisor_first, f.email AS advisor_email
FROM students s
JOIN faculty f ON s.academic_advisor_id = f.faculty_id;
