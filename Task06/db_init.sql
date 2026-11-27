PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS performed_procedures;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS service_categories;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS specializations;
DROP TABLE IF EXISTS patients;

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

CREATE TABLE specializations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE doctors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    phone TEXT NOT NULL UNIQUE,
    specialization_id INTEGER NOT NULL,
    salary_percent REAL NOT NULL CHECK (salary_percent > 0 AND salary_percent <= 100),
    hire_date TEXT NOT NULL DEFAULT (date('now')),
    dismissal_date TEXT DEFAULT NULL CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (specialization_id) REFERENCES specializations(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE service_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    name TEXT NOT NULL UNIQUE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    price REAL NOT NULL CHECK (price >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    phone TEXT NOT NULL UNIQUE,
    birth_date TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    doctor_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL CHECK (end_time > start_time),
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
    notes TEXT,
    UNIQUE (doctor_id, start_time),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE performed_procedures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER UNIQUE,
    doctor_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    performed_at TEXT NOT NULL DEFAULT (datetime('now')),
    price_applied REAL NOT NULL CHECK (price_applied >= 0),
    doctor_percent REAL NOT NULL CHECK (doctor_percent > 0 AND doctor_percent <= 100),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_doctors_active ON doctors(is_active);
CREATE INDEX idx_appointments_doctor_time ON appointments(doctor_id, start_time, end_time);
CREATE INDEX idx_procedures_doctor_date ON performed_procedures(doctor_id, performed_at);

INSERT INTO specializations (id, name) VALUES
    (1, 'Терапевт'),
    (2, 'Хирург'),
    (3, 'Ортодонт'),
    (4, 'Имплантолог'),
    (5, 'Ортопед');

INSERT INTO doctors (id, first_name, last_name, middle_name, phone, specialization_id, salary_percent, hire_date, dismissal_date, is_active) VALUES
    (1, 'Алексей', 'Смирнов', 'Игоревич', '+79001112233', 1, 35.0, '2022-03-15', NULL, 1),
    (2, 'Елена', 'Волкова', 'Сергеевна', '+79002223344', 2, 40.0, '2021-06-01', NULL, 1),
    (3, 'Дмитрий', 'Кузнецов', 'Олегович', '+79003334455', 3, 38.0, '2023-01-10', NULL, 1),
    (4, 'Мария', 'Соколова', 'Андреевна', '+79004445566', 4, 45.0, '2020-09-01', NULL, 1),
    (5, 'Иван', 'Морозов', 'Петрович', '+79005556677', 1, 32.0, '2020-02-10', '2025-12-31', 0);

INSERT INTO service_categories (id, name) VALUES
    (1, 'Терапевтическая стоматология'),
    (2, 'Хирургическая стоматология'),
    (3, 'Имплантация'),
    (4, 'Ортодонтия');

INSERT INTO services (id, category_id, name, duration_minutes, price, is_active) VALUES
    (1, 1, 'Первичная консультация и осмотр', 30, 1200.00, 1),
    (2, 1, 'Лечение среднего кариеса', 60, 4800.00, 1),
    (3, 1, 'Пломбирование корневых каналов', 90, 8500.00, 1),
    (4, 2, 'Простое удаление зуба', 30, 3500.00, 1),
    (5, 2, 'Удаление ретинированного зуба мудрости', 75, 9200.00, 1),
    (6, 3, 'Установка дентального имплантата', 90, 38000.00, 1),
    (7, 4, 'Установка брекет-системы', 120, 45000.00, 1);

INSERT INTO patients (id, first_name, last_name, middle_name, phone, birth_date, created_at) VALUES
    (1, 'Ольга', 'Новикова', 'Дмитриевна', '+79111002030', '1994-05-12', '2025-11-10 10:15:00'),
    (2, 'Сергей', 'Козлов', 'Викторович', '+79112003040', '1988-11-23', '2025-12-01 14:30:00'),
    (3, 'Анна', 'Белова', 'Александровна', '+79113004050', '2001-03-08', '2026-01-20 09:45:00'),
    (4, 'Павел', 'Лебедев', 'Николаевич', '+79114005060', '1979-08-19', '2026-02-14 16:00:00'),
    (5, 'Татьяна', 'Орлова', 'Ивановна', '+79115006070', '1999-12-02', '2026-03-05 11:20:00');

INSERT INTO appointments (id, patient_id, doctor_id, service_id, start_time, end_time, status, notes) VALUES
    (1, 1, 5, 2, '2025-11-15 10:00', '2025-11-15 11:00', 'completed', NULL),
    (2, 2, 1, 3, '2026-10-10 11:00', '2026-10-10 12:30', 'completed', 'Повторный визит'),
    (3, 3, 2, 5, '2026-10-12 14:00', '2026-10-12 15:15', 'completed', NULL),
    (4, 4, 4, 6, '2026-11-05 09:30', '2026-11-05 11:00', 'completed', 'Имплантация в области 36'),
    (5, 5, 3, 7, '2026-11-28 12:00', '2026-11-28 14:00', 'scheduled', 'Подготовка выполнена'),
    (6, 1, 1, 1, '2026-11-29 10:00', '2026-11-29 10:30', 'scheduled', NULL),
    (7, 2, 2, 4, '2026-11-18 15:00', '2026-11-18 15:30', 'cancelled', 'Перенесено пациентом');

INSERT INTO performed_procedures (id, appointment_id, doctor_id, patient_id, service_id, performed_at, price_applied, doctor_percent, quantity) VALUES
    (1, 1, 5, 1, 2, '2025-11-15 10:55:00', 4500.00, 32.0, 1),
    (2, 2, 1, 2, 3, '2026-10-10 12:25:00', 8500.00, 35.0, 1),
    (3, 3, 2, 3, 5, '2026-10-12 15:10:00', 9200.00, 40.0, 1),
    (4, 4, 4, 4, 6, '2026-11-05 10:55:00', 38000.00, 45.0, 1),
    (5, NULL, 1, 5, 1, '2026-11-20 16:20:00', 1200.00, 35.0, 1),
    (6, NULL, 1, 5, 2, '2026-11-20 17:15:00', 4800.00, 35.0, 1);

COMMIT;
