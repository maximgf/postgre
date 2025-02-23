-- measure_settings.sql
CREATE TABLE measure_settings (
    id SERIAL PRIMARY KEY,
    parameter_name VARCHAR(255) NOT NULL,
    min_value NUMERIC(8,2) NOT NULL,
    max_value NUMERIC(8,2) NOT NULL,
    unit VARCHAR(50) NOT NULL
);

INSERT INTO measure_settings (parameter_name, min_value, max_value, unit)
VALUES 
    ('Температура', -58, 58, 'Цельсии'),
    ('Давление', 500, 900, 'мм рт ст'),
    ('Направление ветра', 0, 59, 'градусы');