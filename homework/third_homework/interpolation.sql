-- interpolation.sql
DO $$
DECLARE
    var_interpolation interpolation_type;
    var_temperature INTEGER DEFAULT 22;
    var_result NUMERIC(8,2) DEFAULT 0;
    var_min_temperature NUMERIC(8,2) DEFAULT 0;
    var_max_temperature NUMERIC(8,2) DEFAULT 0;
    var_denominator NUMERIC(8,2) DEFAULT 0;
BEGIN
    RAISE NOTICE 'Расчет интерполяции для температуры %', var_temperature;

    -- Проверка, есть ли температура в справочнике
    IF EXISTS (SELECT 1 FROM public.calc_temperatures_correction WHERE temperature = var_temperature) THEN
        SELECT correction INTO var_result
        FROM public.calc_temperatures_correction
        WHERE temperature = var_temperature;
    ELSE
        -- Получаем диапазон температур
        SELECT MIN(temperature), MAX(temperature)
        INTO var_min_temperature, var_max_temperature
        FROM public.calc_temperatures_correction;

        -- Проверка на выход за границы
        IF var_temperature < var_min_temperature OR var_temperature > var_max_temperature THEN
            RAISE EXCEPTION 'Температура вне допустимого диапазона: % - %', var_min_temperature, var_max_temperature;
        END IF;

        -- Получаем граничные значения
        SELECT x0, y0, x1, y1
        INTO var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
        FROM (
            SELECT t1.temperature AS x0, t1.correction AS y0
            FROM public.calc_temperatures_correction AS t1
            WHERE t1.temperature <= var_temperature
            ORDER BY t1.temperature DESC
            LIMIT 1
        ) AS leftPart
        CROSS JOIN (
            SELECT t1.temperature AS x1, t1.correction AS y1
            FROM public.calc_temperatures_correction AS t1
            WHERE t1.temperature >= var_temperature
            ORDER BY t1.temperature
            LIMIT 1
        ) AS rightPart;

        -- Расчет поправки
        var_denominator := var_interpolation.x1 - var_interpolation.x0;
        IF var_denominator = 0.0 THEN
            RAISE EXCEPTION 'Деление на нуль. Возможно, некорректные данные в таблице с поправками!';
        END IF;

        var_result := (var_temperature - var_interpolation.x0) * (var_interpolation.y1 - var_interpolation.y0) / var_denominator + var_interpolation.y0;
    END IF;

    RAISE NOTICE 'Результат: %', var_result;
END $$;