from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, Numeric, JSON, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import List, Optional
import json

# Настройка подключения к базе данных
DATABASE_URL = "postgresql+psycopg2://postgres:postgres@localhost:5432/test3"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Модель для временной таблицы temp_input_params
class TempInputParams(Base):
    __tablename__ = 'temp_input_params'
    id = Column(Integer, primary_key=True, index=True)
    emploee_name = Column(String(100))
    measurment_type_id = Column(Integer, nullable=False)
    height = Column(Numeric(8, 2), default=0)
    temperature = Column(Numeric(8, 2), default=0)
    pressure = Column(Numeric(8, 2), default=0)
    wind_direction = Column(Numeric(8, 2), default=0)
    wind_speed = Column(Numeric(8, 2), default=0)
    bullet_demolition_range = Column(Numeric(8, 2), default=0)
    measurment_input_params_id = Column(Integer)
    error_message = Column(String)
    calc_result = Column(JSON)

# Модель для запроса
class InputParamsRequest(BaseModel):
    emploee_name: str
    measurment_type_id: int
    height: float
    temperature: float
    pressure: float
    wind_direction: float
    wind_speed: float
    bullet_demolition_range: float

# Модель для ответа
class InputParamsResponse(BaseModel):
    id: int
    emploee_name: str
    measurment_type_id: int
    height: float
    temperature: float
    pressure: float
    wind_direction: float
    wind_speed: float
    bullet_demolition_range: float
    measurment_input_params_id: Optional[int]
    error_message: Optional[str]
    calc_result: Optional[dict]

app = FastAPI()

# Функция для получения сессии базы данных
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Эндпоинт для добавления данных
@app.post("/input_params/", response_model=InputParamsResponse)
def create_input_params(input_params: InputParamsRequest):
    db = SessionLocal()
    try:
        # Создаем новую запись в временной таблице
        db_input_params = TempInputParams(
            emploee_name=input_params.emploee_name,
            measurment_type_id=input_params.measurment_type_id,
            height=input_params.height,
            temperature=input_params.temperature,
            pressure=input_params.pressure,
            wind_direction=input_params.wind_direction,
            wind_speed=input_params.wind_speed,
            bullet_demolition_range=input_params.bullet_demolition_range
        )
        db.add(db_input_params)
        db.commit()
        db.refresh(db_input_params)
        return db_input_params
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# Эндпоинт для получения последней записи
@app.get("/input_params/latest/", response_model=InputParamsResponse)
def get_latest_input_params():
    db = SessionLocal()
    try:
        latest_input_params = db.query(TempInputParams).order_by(TempInputParams.id.desc()).first()
        if latest_input_params is None:
            raise HTTPException(status_code=404, detail="No records found")
        return latest_input_params
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
