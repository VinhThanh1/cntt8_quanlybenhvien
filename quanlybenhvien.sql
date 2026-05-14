CREATE DATABASE hospital_management;
USE hospital_management;

-- I. TẠO BẢNG
-- 1. Bảng Patients
CREATE TABLE Patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    patient_dob DATE,
    patient_phone VARCHAR(15) UNIQUE,
    patient_address VARCHAR(100)
);


-- 2. Bảng Doctors
CREATE TABLE Doctors (
    doctor_id VARCHAR(10) PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    doctor_specialty VARCHAR(50),
    doctor_experience INT,
    doctor_status TINYINT
);

-- 3. Bảng Appointments
CREATE TABLE Appointments (
    app_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10),
    doctor_id VARCHAR(10),
    app_date DATE,
    app_cost DECIMAL(12,0),
    app_status ENUM(
        'Pending',
        'Completed',
        'Cancelled'
    ),

    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);


-- 4. Bảng Prescriptions
CREATE TABLE Prescriptions (
    app_id VARCHAR(10) PRIMARY KEY,
    pres_medicine_details VARCHAR(255),
    pres_total_meds_cost DECIMAL(12,0),
    FOREIGN KEY (app_id) REFERENCES Appointments(app_id)
);


-- II. THÊM DỮ LIỆU
-- 1. Patients
INSERT INTO Patients
VALUES
('BN001','Nguyễn Thị Hà','2000-05-15','0901111222','Hà Nội'),
('BN002','Trần Thu Bình','1998-08-20','0912222333','Hải Phòng'),
('BN003','Lê Văn Chiến','1999-07-26','0983333444','Hà Nội'),
('BN004','Nguyễn Xuân Bách','1998-03-31','0964444555','Đà Nẵng'),
('BN005','Trần Minh Cường','1995-02-19','0975555666','Hà Nội');


-- 2. Doctors
INSERT INTO Doctors
VALUES
('BS001','Nguyễn Lân Việt','Tim mạch',18,1),
('BS002','Trần Ngọc Lương','Ngoại khoa',15,1),
('BS003','Nguyễn Chấn Hùng','Ung Bướu',16,0),
('BS004','Nguyễn Văn Liệu','Thần Kinh',13,1),
('BS005','Nguyễn Viết Tiến','Phụ khoa',12,1);


-- 3. Appointments
INSERT INTO Appointments
VALUES
('PK001','BN001','BS001','2026-05-13',500000,'Completed'),
('PK002','BN002','BS002','2026-04-16',300000,'Completed'),
('PK003','BN001','BS003','2026-03-29',700000,'Completed'),
('PK004','BN003','BS001','2026-05-13',400000,'Pending'),
('PK005','BN004','BS004','2026-04-12',200000,'Cancelled'),
('PK006','BN002','BS002','2026-05-08',300000,'Completed');


-- 4. Prescriptions
INSERT INTO Prescriptions
VALUES
('PK001','Aspirin, Beta-blocker',1500000),
('PK002','Vitamin C, Paracetamol',130000),
('PK003','Neurobion, Ginkgo Biloba',3500000);


-- III. CẬP NHẬT DỮ LIỆU

/*
1. Tăng chi phí khám thêm 50,000
cho các bác sĩ chuyên khoa Tim mạch

Ý tưởng:
- JOIN Appointments với Doctors
- Tìm bác sĩ có chuyên khoa Tim mạch
- UPDATE app_cost
*/

UPDATE Appointments a
JOIN Doctors d ON a.doctor_id = d.doctor_id
SET a.app_cost = a.app_cost + 50000
WHERE d.doctor_specialty = 'Tim mạch';

/*
2. Xóa bác sĩ Nguyễn Lân Việt

Không xóa được vì:
- Doctors đang liên kết với Appointments
- FOREIGN KEY ngăn xóa để tránh mất dữ liệu

Các bước:
B1: Xóa phiếu khám liên quan
B2: Xóa bác sĩ
*/

DELETE FROM Appointments
WHERE doctor_id = 'BS001';

DELETE FROM Doctors
WHERE doctor_id = 'BS001';


-- IV. TRUY VẤN VẬN HÀNH

/*
1. Lấy phiếu khám đã hoàn thành
- Chỉ lấy Completed
- Sắp xếp ngày mới nhất lên đầu
*/

SELECT app_id, doctor_id, app_date, app_cost
FROM Appointments
WHERE app_status = 'Completed'
ORDER BY app_date DESC;

/*
2. Tìm bệnh nhân ở Hà Nội
và số điện thoại bắt đầu bằng 090
LIKE '090%'
% nghĩa là phía sau có thể là bất kỳ ký tự nào
*/

SELECT patient_id, patient_phone, patient_name
FROM Patients
WHERE patient_address = 'Hà Nội'
AND patient_phone LIKE '090%';

/*
3. Hiển thị 3 người tiếp theo trên TV
- LIMIT 3 = lấy 3 người
- OFFSET 2 = bỏ qua 2 người đầu
*/

SELECT patient_id, patient_name, patient_dob
FROM Patients
LIMIT 3 OFFSET 2;

-- V. BÁO CÁO & THỐNG KÊ
/*

1. Xuất hóa đơn viện phí

Tổng tiền =
Tiền khám + Tiền thuốc

CASE WHEN:
- Nếu không có tiền thuốc (NULL)
- Đổi thành 0 để cộng không lỗi

*/

SELECT p.patient_id, p.patient_name, d.doctor_name,

    a.app_cost +
    CASE
        WHEN pr.pres_total_meds_cost IS NULL THEN 0
        ELSE pr.pres_total_meds_cost
    END
    AS total_payment
FROM Appointments a JOIN Patients p ON a.patient_id = p.patient_id
						JOIN Doctors d ON a.doctor_id = d.doctor_id
							LEFT JOIN Prescriptions pr ON a.app_id = pr.app_id;

/*
2. KPI bác sĩ

COUNT:
- Đếm số lượt khám

SUM:
- Cộng tổng doanh thu

CASE WHEN:
- Nếu không có tiền thuốc
- Đổi NULL thành 0
*/

SELECT d.doctor_id, d.doctor_name, COUNT(a.app_id) AS total_visits,
    SUM(
        a.app_cost +
        CASE
            WHEN pr.pres_total_meds_cost IS NULL THEN 0
            ELSE pr.pres_total_meds_cost
        END
    ) AS total_revenue

FROM Doctors d JOIN Appointments a ON d.doctor_id = a.doctor_id
				LEFT JOIN Prescriptions pr ON a.app_id = pr.app_id
GROUP BY d.doctor_id, d.doctor_name
HAVING COUNT(a.app_id) >= 2;

/*
3. QA kiểm tra bác sĩ khám xong nhưng không kê thuốc

LEFT JOIN:
- Lấy tất cả phiếu khám

Nếu không có đơn thuốc:
pr.app_id sẽ NULL
*/

SELECT a.app_id, a.patient_id, a.app_date
FROM Appointments a LEFT JOIN Prescriptions pr ON a.app_id = pr.app_id
WHERE a.app_status = 'Completed'
AND pr.app_id IS NULL;


-- VI. PHÂN TÍCH DỮ LIỆU CHUYÊN SÂU
/*
1. Bác sĩ có kinh nghiệm cao hơn trung bình

AVG:
- Tính kinh nghiệm trung bình

Subquery:
- Lấy giá trị trung bình
- So sánh từng bác sĩ
*/

SELECT doctor_id, doctor_name, doctor_experience
FROM Doctors
WHERE doctor_experience >
(
    SELECT AVG(doctor_experience)
    FROM Doctors
);

/*
2. Bệnh nhân tạo phiếu khám nhưng chưa khám

Pending = đang chờ khám

DISTINCT:
- Tránh trùng bệnh nhân
*/
SELECT DISTINCT p.patient_id, p.patient_name, p.patient_phone
FROM Patients p JOIN Appointments a ON p.patient_id = a.patient_id
WHERE a.app_status = 'Pending';