-- test_data.sql
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    v_employee_id INTEGER;
    v_temperature NUMERIC(8,2);
    v_pressure NUMERIC(8,2);
    v_wind_direction NUMERIC(8,2);
BEGIN
    -- Добавляем несколько пользователей
    FOR i IN 1..5 LOOP
        INSERT INTO employees (name, birthday, military_rank_id)
        VALUES ('Тестовый пользователь ' || i, '1990-01-01', 1)
        RETURNING id INTO v_employee_id;

        -- Добавляем 100 измерений для каждого пользователя
        FOR j IN 1..100 LOOP
            v_temperature := random() * 116 - 58;  -- Температура от -58 до 58
            v_pressure := random() * 400 + 500;   -- Давление от 500 до 900
            v_wind_direction := random() * 59;    -- Направление ветра от 0 до 59

            INSERT INTO measurment_input_params (measurment_type_id, height, temperature, pressure, wind_direction, wind_speed)
            VALUES (1, random() * 1000, v_temperature, v_pressure, v_wind_direction, random() * 50)
            RETURNING id INTO v_employee_id;

            INSERT INTO measurment_baths (emploee_id, measurment_input_param_id)
            VALUES (v_employee_id, v_employee_id);
        END LOOP;
    END LOOP;
END $$;