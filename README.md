# Katarzyna Piskorz i Iga Szaflik
# (Inteligentna Spiżarnia)

Nowoczesny system zarządzania zapasami i menu restauracji, zaprojektowany w duchu **Zero Waste**. Aplikacja monitoruje stany magazynowe, terminy przydatności do spożycia oraz automatycznie sugeruje kucharzom, co ugotować, aby zminimalizować marnowanie żywności.

## Główne funkcje

* **Zero Waste:** Dynamiczne rekomendacje potraw na podstawie składników o najkrótszej dacie ważności.
* **Niezawodna architektura DB:** Wykorzystanie transakcji, blokad pesymistycznych (`FOR UPDATE`) oraz triggerów w Oracle DB do zabezpieczenia współbieżności.
* **Zarządzanie Rolami (RBAC):** Różne poziomy dostępu dla Szefa Kuchni (CHEF) i Kucharzy (COOK). Tylko Szef Kuchni może uruchomić procedurę końca dnia (przekazanie jedzenia na cele charytatywne).
* **Obsidian Frost UI:** Ciemny interfejs użytkownika z interaktywnym asystentem kulinarnym powiadamiającym o stanie kuchni.

## Stack Technologiczny

* **Baza Danych:** Oracle DB (Relacyjny model, Triggery, Procedury PL/SQL)
* **Backend:** Python + FastAPI (REST API, Pydantic, oracledb)
* **Frontend:** React + Vite (Custom CSS, Fetch API)

## Jak uruchomić

Upewnij się, że Twój lokalny kontener z bazą Oracle jest włączony i zasilony danymi. Następnie uruchom dwa terminale:

**1. Backend (API)**
```bash
cd backend
pip install fastapi uvicorn oracledb pydantic
uvicorn main:app --reload
```
Aplikacja uruchomi się pod adresem: `http://localhost:5173/`

**2. Frontend**
```bash
cd frontend
npm install
npm run dev
```

Aplikacja uruchomi się pod adresem: `http://localhost:5173/`
