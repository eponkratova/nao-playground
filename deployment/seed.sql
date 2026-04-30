-- seed.sql: create and populate tables with sample data

-- ── Tables ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.countries (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.locations (
    id SERIAL PRIMARY KEY,
    country_id INT REFERENCES countries(id),
    region VARCHAR(100),
    city VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS public.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.agents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    role_id INT REFERENCES roles(id),
    location_id INT REFERENCES locations(id),
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS public.customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    location_id INT REFERENCES locations(id),
    registered_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS public.sales (
    id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id),
    agent_id INT REFERENCES agents(id),
    amount NUMERIC(10,2) NOT NULL,
    sale_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'completed'
);

-- ── Seed data ─────────────────────────────────────────────────────────────────

INSERT INTO public.countries (name, code) VALUES
    ('Madagascar', 'MG'),
    ('Kenya', 'KE'),
    ('Tanzania', 'TZ'),
    ('Uganda', 'UG');

INSERT INTO public.locations (country_id, region, city) VALUES
    (1, 'Analamanga', 'Antananarivo'),
    (1, 'Boeny', 'Mahajanga'),
    (1, 'Atsimo-Andrefana', 'Toliara'),
    (2, 'Nairobi', 'Nairobi'),
    (2, 'Coast', 'Mombasa'),
    (3, 'Dar es Salaam', 'Dar es Salaam'),
    (4, 'Central', 'Kampala');

INSERT INTO public.roles (name) VALUES
    ('Field Agent'),
    ('Senior Agent'),
    ('Zone Manager'),
    ('Regional Manager');

INSERT INTO public.agents (name, email, role_id, location_id, status) VALUES
    ('Jean Rakoto',      'j.rakoto@example.com',   1, 1, 'active'),
    ('Marie Rasoa',      'm.rasoa@example.com',    1, 2, 'active'),
    ('Paul Andriantsoa', 'p.andrian@example.com',  2, 3, 'active'),
    ('Hery Rasolofo',    'h.rasolo@example.com',   2, 1, 'active'),
    ('Nivo Randria',     'n.randria@example.com',  3, 2, 'active'),
    ('Alice Kamau',      'a.kamau@example.com',    1, 4, 'active'),
    ('David Ochieng',    'd.ochieng@example.com',  2, 5, 'inactive'),
    ('Fatuma Hassan',    'f.hassan@example.com',   3, 6, 'active'),
    ('Grace Nakato',     'g.nakato@example.com',   1, 7, 'active'),
    ('Samuel Byaruhanga','s.byaru@example.com',    4, 7, 'active');

INSERT INTO public.customers (name, phone, location_id, registered_date) VALUES
    ('Rabe Solo',         '+261320001001', 1, '2024-01-15'),
    ('Koto Mialy',        '+261320001002', 1, '2024-02-03'),
    ('Fara Andry',        '+261320001003', 2, '2024-02-20'),
    ('Lova Tsiry',        '+261320001004', 3, '2024-03-08'),
    ('Vola Noro',         '+261320001005', 1, '2024-03-22'),
    ('James Mwangi',      '+254700001001', 4, '2024-01-10'),
    ('Aisha Wanjiru',     '+254700001002', 4, '2024-02-14'),
    ('Peter Kimani',      '+254700001003', 5, '2024-03-01'),
    ('Zawadi Juma',       '+255780001001', 6, '2024-01-28'),
    ('Amina Salim',       '+255780001002', 6, '2024-04-05'),
    ('Ronald Ssekandi',   '+256700001001', 7, '2024-02-09'),
    ('Prossy Namukasa',   '+256700001002', 7, '2024-03-17');

INSERT INTO public.sales (customer_id, agent_id, amount, sale_date, status) VALUES
    (1,  1, 250.00, '2024-01-20', 'completed'),
    (2,  1, 180.00, '2024-02-10', 'completed'),
    (3,  2, 320.00, '2024-02-25', 'completed'),
    (4,  3, 150.00, '2024-03-10', 'completed'),
    (5,  4, 400.00, '2024-03-28', 'completed'),
    (6,  6, 275.00, '2024-01-15', 'completed'),
    (7,  6, 190.00, '2024-02-20', 'completed'),
    (8,  7, 310.00, '2024-03-05', 'cancelled'),
    (9,  8, 220.00, '2024-02-01', 'completed'),
    (10, 8, 450.00, '2024-04-10', 'completed'),
    (11, 9, 175.00, '2024-02-15', 'completed'),
    (12, 9, 290.00, '2024-03-20', 'completed'),
    (1,  4, 130.00, '2024-04-01', 'completed'),
    (6,  6, 500.00, '2024-04-12', 'pending');