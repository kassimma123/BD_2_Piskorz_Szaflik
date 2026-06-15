import React, { useState, useEffect } from 'react';

const API_URL = 'http://127.0.0.1:8000/api';

function App() {
  const [users, setUsers] = useState([]);
  const [activeUser, setActiveUser] = useState(null);
  
  const [reportData, setReportData] = useState([]);
  const [reservations, setReservations] = useState([]);

  // Pobieranie użytkowników przy starcie
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const response = await fetch(`${API_URL}/users`);
        if (response.ok) {
          const data = await response.json();
          // unikalni użytkownicy po imieniu i nazwisku
          const uniqueUsers = Array.from(new Map(data.map(item => [`${item.FIRST_NAME} ${item.LAST_NAME}`, item])).values());
          setUsers(uniqueUsers);
        }
      } catch (error) {
        console.error("Błąd pobierania użytkowników:", error);
      }
    };
    fetchUsers();
  }, []);

  // Pobieranie danych po zalogowaniu
  const fetchReport = async () => {
    try {
      const response = await fetch(`${API_URL}/reports/what-to-cook`);
      if (response.ok) {
        const data = await response.json();
        setReportData(data);
      }
    } catch (error) {
      console.error("Błąd pobierania raportu:", error);
    }
  };

  const fetchReservations = async () => {
    try {
      const response = await fetch(`${API_URL}/reservations`);
      if (response.ok) {
        const data = await response.json();
        setReservations(data);
      }
    } catch (error) {
      console.error("Błąd pobierania rezerwacji:", error);
    }
  };

  useEffect(() => {
    if (activeUser) {
      fetchReport();
      fetchReservations();
    }
  }, [activeUser]);

  // Funkcja rezerwacji
  const handleReserve = async (dishId) => {
    try {
      const response = await fetch(`${API_URL}/reservations/reserve`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: activeUser.USER_ID, dish_id: dishId })
      });
      
      const result = await response.json();
      
      if (response.ok) {
        alert("Zarezerwowano składniki! Rozpoczynam gotowanie.");
        fetchReport();
        fetchReservations();
      } else {
        alert("Błąd rezerwacji: " + result.detail);
      }
    } catch (error) {
      console.error("Błąd przy rezerwacji:", error);
    }
  };

  // Zakończenie rezerwacji
  const handleResolve = async (reservationId, actionType) => {
    try {
      const response = await fetch(`${API_URL}/reservations/resolve`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reservation_id: reservationId, action: actionType })
      });
      
      const result = await response.json();
      
      if (response.ok) {
        alert(`Pomyślnie zaktualizowano zlecenie jako ${actionType}.`);
        fetchReport();
        fetchReservations();
      } else {
        alert("Błąd aktualizacji: " + result.detail);
      }
    } catch (error) {
      console.error("Błąd przy rozwiązywaniu:", error);
    }
  };

  // Koniec Dnia - Oddaj Żywność
  const handleEndOfDay = async () => {
    if (!window.confirm("Czy na pewno chcesz zakończyć dzień? (usunie przeterminowane produkty)")) return;

    try {
      const response = await fetch(`${API_URL}/admin/end-of-day`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ admin_user_id: activeUser.USER_ID })
      });
      
      const result = await response.json();
      
      if (response.ok) {
        alert("Zakończono dzień. Przeterminowana żywność została oddana.");
        fetchReport();
      } else {
        alert("Błąd: " + result.detail);
      }
    } catch (error) {
      console.error("Błąd końca dnia:", error);
    }
  };

  // Ekran logowania
  if (!activeUser) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
        <div className="glass-panel" style={{ width: '400px', textAlign: 'center', padding: '3rem 2rem' }}>
          <h2 className="glow-text" style={{ marginBottom: '2rem' }}>Logowanie do Systemu</h2>
          <p style={{ color: '#94a3b8', marginBottom: '1rem' }}>Wybierz swój profil z bazy danych:</p>
          
          <select 
            id="userSelect"
            style={{ 
              width: '100%', 
              padding: '12px', 
              borderRadius: '8px', 
              background: '#0f172a', 
              color: '#fff',
              border: '1px solid #334155',
              marginBottom: '2rem',
              fontSize: '1rem'
            }}
          >
            <option value="">-- Wybierz pracownika --</option>
            {users.map(u => (
              <option key={u.USER_ID} value={u.USER_ID}>
                {u.FIRST_NAME} {u.LAST_NAME} ({u.ROLE})
              </option>
            ))}
          </select>

          <button 
            onClick={() => {
              const select = document.getElementById('userSelect');
              if (!select.value) {
                alert("Wybierz użytkownika!");
                return;
              }
              const selectedUser = users.find(u => u.USER_ID === parseInt(select.value));
              setActiveUser(selectedUser);
            }}
            style={{
              width: '100%',
              padding: '12px',
              background: '#38bdf8',
              color: '#0f172a',
              border: 'none',
              borderRadius: '8px',
              fontWeight: 'bold',
              cursor: 'pointer',
              fontSize: '1rem'
            }}
          >
            Wejdź do Spiżarni
          </button>
        </div>
      </div>
    );
  }

  // Komunikaty robota
  let robotMessage = "Wszystkie systemy działają stabilnie.";
  if (reportData.length === 0) {
    robotMessage = "Magazyn świeci pustkami! Brakuje składników na jakiekolwiek danie z menu.";
  } else if (reservations.filter(r => r.STATUS === 'ACTIVE').length > 0) {
    robotMessage = "Kucharze mają pełne ręce roboty! Zlecono gotowanie. Pamiętaj, aby wydać gotowe dania w panelu na samym dole.";
  } else if (reportData.length > 0) {
    robotMessage = "Mamy świeże produkty! Sprawdź powyżej co możemy dziś przygotować, zanim skończy się ważność składników.";
  }

  // Dashboard
  return (
    <>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 className="glow-text" style={{ margin: 0 }}>System Spiżarni v3.0</h1>
          <p style={{ color: '#94a3b8', margin: '5px 0 0 0', fontSize: '0.9rem' }}>
            Zalogowano jako: <strong>{activeUser.FIRST_NAME} {activeUser.LAST_NAME}</strong> ({activeUser.ROLE})
            <span 
              onClick={() => setActiveUser(null)} 
              style={{ marginLeft: '15px', color: '#38bdf8', cursor: 'pointer', textDecoration: 'underline' }}
            >
              Wyloguj
            </span>
          </p>
        </div>
        
        {activeUser.ROLE === 'CHEF' && (
          <button 
            onClick={handleEndOfDay}
            style={{ 
              padding: '12px 24px', 
              background: 'rgba(244, 63, 94, 0.1)', 
              border: '1px solid #f43f5e', 
              color: '#f43f5e',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 'bold',
              transition: 'all 0.2s',
              boxShadow: '0 0 10px rgba(244, 63, 94, 0.2)'
            }}
            onMouseOver={(e) => e.target.style.background = 'rgba(244, 63, 94, 0.2)'}
            onMouseOut={(e) => e.target.style.background = 'rgba(244, 63, 94, 0.1)'}
          >
            Koniec Dnia (Oddaj Żywność)
          </button>
        )}
      </header>

      <main className="dashboard-layout">
        
        {/* ASYSTENT KULINARNY (W ROGU) */}
        <div className="floating-robot">
          <div className="speech-bubble">
            <strong>Sygnał z systemu:</strong> {robotMessage}
          </div>
          <div className="mini-robot-icon">
            <svg width="60" height="60" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="20" y="30" width="60" height="50" rx="10" fill="#38bdf8" />
              <circle cx="35" cy="50" r="8" fill="#0f172a" />
              <circle cx="65" cy="50" r="8" fill="#0f172a" />
              <circle cx="35" cy="50" r="3" fill="#38bdf8" className="robot-eye-glow" />
              <circle cx="65" cy="50" r="3" fill="#38bdf8" className="robot-eye-glow" />
              <path d="M40 70 Q50 75 60 70" stroke="#0f172a" strokeWidth="3" strokeLinecap="round" />
              <rect x="45" y="10" width="10" height="20" fill="#94a3b8" />
              <circle cx="50" cy="10" r="6" fill="#f43f5e" className="robot-eye-glow" />
            </svg>
          </div>
        </div>

        {/* GŁÓWNY PANEL - KARTY DAŃ */}
        <section className="glass-panel main-panel" style={{ marginBottom: '2rem' }}>
          <h2 style={{ marginTop: 0, color: '#fff', fontSize: '1.5rem', marginBottom: '1.5rem', borderBottom: '1px solid rgba(56, 189, 248, 0.2)', paddingBottom: '1rem' }}>
            Dostępne Operacje Kuchenne
          </h2>
          
          <div className="cards-container">
            {reportData.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '3rem 1rem', color: '#94a3b8' }}>
                <p>Brak optymalnych potraw do ugotowania.</p>
                <p style={{ fontSize: '0.85rem', marginTop: '0.5rem' }}>Oczekuję na uzupełnienie zapasów...</p>
              </div>
            ) : (
              reportData.map((dish, index) => {
                const expDate = new Date(dish["Najpilniejszy Składnik"]);
                const formattedDate = expDate.toLocaleDateString('pl-PL', { 
                  day: 'numeric', month: 'long', year: 'numeric' 
                });
                
                return (
                  <div className="data-card" key={index}>
                    <div className="dish-info" style={{ flex: 1 }}>
                      <h3>{dish["Nazwa Dania"]}</h3>
                      <div className="dish-meta">
                        <span className="tag">{dish["Kategoria"]}</span>
                      </div>
                      
                      <div className="urgency-alert">
                        <span className="urgency-icon">⚠️</span>
                        <span>
                          <strong>Wymaga ugotowania do:</strong> {formattedDate}<br/>
                          <span style={{ fontSize: '0.75rem', opacity: 0.8 }}>Z powodu najszybciej psującego się składnika w przepisie.</span>
                        </span>
                      </div>
                    </div>
                    
                    <div style={{ display: 'flex', gap: '2rem', alignItems: 'center', marginLeft: '1rem' }}>
                      <div className="portions-badge">
                        <span className="num">{dish["Możliwych Porcji"]}</span>
                        <span className="label">Porcji</span>
                      </div>

                      <button 
                        onClick={() => handleReserve(dish["ID Dania"])}
                        style={{
                          padding: '12px 24px',
                          background: 'rgba(56, 189, 248, 0.2)',
                          border: '1px solid #38bdf8',
                          color: '#38bdf8',
                          borderRadius: '8px',
                          cursor: 'pointer',
                          fontWeight: 'bold',
                          transition: 'all 0.2s',
                          whiteSpace: 'nowrap'
                        }}
                        onMouseOver={(e) => e.target.style.background = 'rgba(56, 189, 248, 0.4)'}
                        onMouseOut={(e) => e.target.style.background = 'rgba(56, 189, 248, 0.2)'}
                      >
                        Gotuj (Zarezerwuj)
                      </button>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </section>

        {/* PANEL AKTYWNYCH ZLECEŃ */}
        <section className="glass-panel">
          <h2 style={{ marginTop: 0, color: '#10b981', fontSize: '1.5rem', marginBottom: '1.5rem', borderBottom: '1px solid rgba(16, 185, 129, 0.2)', paddingBottom: '1rem' }}>
            Aktywne Rezerwacje (W Trakcie)
          </h2>

          <div className="cards-container">
            {reservations.filter(r => r.STATUS === 'ACTIVE').length === 0 ? (
              <p style={{ color: '#94a3b8', textAlign: 'center', padding: '1rem' }}>Brak potraw w trakcie przygotowania.</p>
            ) : (
              reservations.filter(r => r.STATUS === 'ACTIVE').map((res, idx) => (
                <div key={idx} style={{ 
                  background: 'rgba(15, 23, 42, 0.6)', 
                  border: '1px solid #334155', 
                  borderRadius: '8px', 
                  padding: '1rem',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <strong style={{ color: '#fff', fontSize: '1.1rem' }}>{res.DISH_NAME}</strong>
                    <div style={{ color: '#94a3b8', fontSize: '0.85rem', marginTop: '4px' }}>
                      Rezerwacja #{res.RESERVATION_ID} • Kucharz: {res.FIRST_NAME} {res.LAST_NAME}
                    </div>
                  </div>
                  
                  <div style={{ display: 'flex', gap: '10px' }}>
                    <button 
                      onClick={() => handleResolve(res.RESERVATION_ID, 'COMPLETED')}
                      style={{ background: '#10b981', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '4px', cursor: 'pointer', fontWeight: 'bold' }}
                    >
                      Wydano 
                    </button>
                    <button 
                      onClick={() => handleResolve(res.RESERVATION_ID, 'CANCELLED')}
                      style={{ background: 'transparent', color: '#f43f5e', border: '1px solid #f43f5e', padding: '8px 16px', borderRadius: '4px', cursor: 'pointer' }}
                    >
                      Anuluj
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </section>

      </main>
    </>
  );
}

export default App;