from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import oracledb

app = FastAPI(title="Spiżarnia API", description="Backend inteligentnej spiżarni")

# konfiguracja bazy danych
DB_USER = "spizarnia"
DB_PASSWORD = "123"
DB_DSN = "localhost:1521/FREEPDB1"

# konfiguracja cors
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# modele danych
class ReserveRequest(BaseModel):
    user_id: int
    dish_id: int

class ResolveRequest(BaseModel):
    reservation_id: int
    action: str # 'COMPLETED' lub 'CANCELLED'

class EndOfDayRequest(BaseModel):
    admin_user_id: int

class ResolveShoppingRequest(BaseModel):
    shopping_list_id: int
    action: str

# łączenie z bazą
def get_db_connection():
    try:
        return oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
    except oracledb.DatabaseError as e:
        raise HTTPException(status_code=500, detail=f"Błąd łączenia z bazą: {e}")


# endpointy

# co można ugotować - widok V_Cook_Today
@app.get("/api/reports/what-to-cook")
def get_what_to_cook_report():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM V_Cook_Today")
        columns = [col[0] for col in cursor.description]
        rows = cursor.fetchall()
        return [dict(zip(columns, row)) for row in rows]
    finally:
        cursor.close()
        conn.close()

# rezerwacja - procedura Reserve_Dish 
@app.post("/api/reservations/reserve")
def reserve_dish(req: ReserveRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("Reserve_Dish", [req.user_id, req.dish_id])
        return {"status": "success", "message": f"User {req.user_id} successfully reserved dish {req.dish_id}."}
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        raise HTTPException(status_code=400, detail=error_obj.message)
    finally:
        cursor.close()
        conn.close()

# procedura Resolve_Reservation (COMPLETED lub CANCELLED)
@app.post("/api/reservations/resolve")
def resolve_reservation(req: ResolveRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("Resolve_Reservation", [req.reservation_id, req.action])
        return {"status": "success", "message": f"Reservation {req.reservation_id} resolved as {req.action}."}
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        raise HTTPException(status_code=400, detail=error_obj.message)
    finally:
        cursor.close()
        conn.close()

# procedurę Donate_Expired_Food
@app.post("/api/admin/end-of-day")
def end_of_day_donation(req: EndOfDayRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc("Donate_Expired_Food", [req.admin_user_id])
        return {"status": "success", "message": "End of day procedure completed. Food donated."}
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        raise HTTPException(status_code=403, detail=error_obj.message)
    finally:
        cursor.close()
        conn.close()

# wszystkie partie w magazynie
@app.get("/api/inventory")
def get_inventory_status():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            SELECT i.Batch_ID, p.Product_Name, i.Quantity, i.Reserved_Quantity, 
                   i.Expiration_Date, i.Status 
            FROM Inventory i
            JOIN Product_Catalog p ON i.Product_ID = p.Product_ID
            ORDER BY i.Expiration_Date ASC
        """
        cursor.execute(query)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
        conn.close()
        
# aktywne zlecenia
@app.get("/api/reservations")
def get_reservations():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            SELECT r.Reservation_ID, r.User_ID, u.First_Name, u.Last_Name, 
                   d.Dish_Name, r.Reservation_Date, r.Status 
            FROM Reservations r
            JOIN Users u ON r.User_ID = u.User_ID
            JOIN Dishes d ON r.Dish_ID = d.Dish_ID
            ORDER BY r.Reservation_Date DESC
        """
        cursor.execute(query)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
        conn.close()

# lista użytkowników
@app.get("/api/users")
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = "SELECT User_ID, First_Name, Last_Name, Role FROM Users ORDER BY User_ID ASC"
        cursor.execute(query)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
        conn.close()

# lista zakupów
@app.get("/api/shopping-list")
def get_shopping_list():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            SELECT sl.Shopping_List_ID, p.Product_Name, sl.Date_Added, sl.Status
            FROM Shopping_List sl
            JOIN Product_Catalog p ON sl.Product_ID = p.Product_ID
            ORDER BY sl.Date_Added DESC
        """
        cursor.execute(query)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
        conn.close()

# oznaczanie zakupu
@app.post("/api/shopping-list/resolve")
def resolve_shopping_list(req: ResolveShoppingRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE Shopping_List SET Status = :1 WHERE Shopping_List_ID = :2",
            [req.action, req.shopping_list_id]
        )
        conn.commit()
        return {"status": "success", "message": f"Shopping item {req.shopping_list_id} resolved as {req.action}."}
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        raise HTTPException(status_code=400, detail=error_obj.message)
    finally:
        cursor.close()
        conn.close()

# kupowanie wszystkich elementow na liscie
@app.post("/api/shopping-list/resolve-all")
def resolve_all_shopping_list():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE Shopping_List SET Status = 'COMPLETED' WHERE Status = 'TO_BUY'"
        )
        conn.commit()
        return {"status": "success", "message": "Wszystkie przedmioty zostały zakupione."}
    except oracledb.DatabaseError as e:
        error_obj, = e.args
        raise HTTPException(status_code=400, detail=error_obj.message)
    finally:
        cursor.close()
        conn.close()
