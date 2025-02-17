-- functions.sql
-- Создание пользовательского типа данных
CREATE TYPE measurement_input AS (
    temperature NUMERIC(8,2),
    pressure NUMERIC(8,2),
    wind_direction NUMERIC(8,2)
);

-- Функция для проверки входных параметров
CREATE OR REPLACE FUNCTION validate_measurement(
    p_temperature NUMERIC(8,2),
    p_pressure NUMERIC(8,2),
    p_wind_direction NUMERIC(8,2)
) RETURNS measurement_input AS $$
DECLARE
    v_temperature_min NUMERIC(8,2);
    v_temperature_max NUMERIC(8,2);
    v_pressure_min NUMERIC(8,2);
    v_pressure_max NUMERIC(8,2);
    v_wind_direction_min NUMERIC(8,2);
    v_wind_direction_max NUMERIC(8,2);
BEGIN
    -- Получаем граничные значения для температуры
    SELECT min_value, max_value INTO v_temperature_min, v_temperature_max
    FROM measure_settings
    WHERE parameter_name = 'Температура';

    -- Получаем граничные значения для давления
    SELECT min_value, max_value INTO v_pressure_min, v_pressure_max
    FROM measure_settings
    WHERE parameter_name = 'Давление';

    -- Получаем граничные значения для направления ветра
    SELECT min_value, max_value INTO v_wind_direction_min, v_wind_direction_max
    FROM measure_settings
    WHERE parameter_name = 'Направление ветра';

    -- Проверка температуры
    IF p_temperature < v_temperature_min OR p_temperature > v_temperature_max THEN
        RAISE EXCEPTION 'Температура вне допустимого диапазона: % - %', v_temperature_min, v_temperature_max;
    END IF;

    -- Проверка давления
    IF p_pressure < v_pressure_min OR p_pressure > v_pressure_max THEN
        RAISE EXCEPTION 'Давление вне допустимого диапазона: % - %', v_pressure_min, v_pressure_max;
    END IF;

    -- Проверка направления ветра
    IF p_wind_direction < v_wind_direction_min OR p_wind_direction > v_wind_direction_max THEN
        RAISE EXCEPTION 'Направление ветра вне допустимого диапазона: % - %', v_wind_direction_min, v_wind_direction_max;
    END IF;

    -- Возвращаем результат
    RETURN (p_temperature, p_pressure, p_wind_direction);
END;
$$ LANGUAGE plpgsql;