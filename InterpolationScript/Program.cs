using System;
using System.Diagnostics;
using Npgsql;

class Program
{
    static void Main(string[] args)
    {
 
        string connString = "Host=127.0.0.1:5432;Username=postgres;Password=postgres;Database=test2";
 
        Stopwatch stopwatch = new Stopwatch();
        stopwatch.Start();
 
        using (var conn = new NpgsqlConnection(connString))
        {
            conn.Open();
 
            double startTemp = 0;
            double endTemp = 40;
            double step = 0.01;
 
            for (double temp = startTemp; temp <= endTemp; temp += step)
            {
                double correction = CalculateCorrection(conn, temp);
                Console.WriteLine($"Температура: {temp:F2}°C, Поправка: {correction:F2}");
            }
        }
 
        stopwatch.Stop();
        Console.WriteLine($"Время выполнения: {stopwatch.ElapsedMilliseconds} мс");
    }

    static double CalculateCorrection(NpgsqlConnection conn, double temperature)
    {
        // Проверка, есть ли точное значение в таблице
        using (var cmd = new NpgsqlCommand("SELECT correction FROM calc_temperatures_correction WHERE temperature = @temp", conn))
        {
            cmd.Parameters.AddWithValue("temp", temperature);
            var result = cmd.ExecuteScalar();
            if (result != null)
            {
                return Convert.ToDouble(result);
            }
        }

        // Получение граничных значений для интерполяции
        using (var cmd = new NpgsqlCommand(@"
            SELECT t1.temperature AS x0, t1.correction AS y0, t2.temperature AS x1, t2.correction AS y1
            FROM (
                SELECT temperature, correction
                FROM calc_temperatures_correction
                WHERE temperature <= @temp
                ORDER BY temperature DESC
                LIMIT 1
            ) AS t1
            CROSS JOIN (
                SELECT temperature, correction
                FROM calc_temperatures_correction
                WHERE temperature >= @temp
                ORDER BY temperature ASC
                LIMIT 1
            ) AS t2", conn))
        {
            cmd.Parameters.AddWithValue("temp", temperature);
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                {
                    double x0 = reader.GetDouble(0);
                    double y0 = reader.GetDouble(1);
                    double x1 = reader.GetDouble(2);
                    double y1 = reader.GetDouble(3);

                    
                    if (x1 == x0)
                    {
                        throw new InvalidOperationException("Деление на нуль. Некорректные данные в таблице с поправками.");
                    }

                    double correction = (temperature - x0) * (y1 - y0) / (x1 - x0) + y0;
                    return correction;
                }
                else
                {
                    throw new InvalidOperationException("Не удалось найти граничные значения для интерполяции.");
                }
            }
        }
    }
}