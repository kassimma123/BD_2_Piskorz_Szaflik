import React, { useState, useEffect } from 'react';

const API_URL = 'http://127.0.0.1:8000/api';

function App() {
  const [reportData, setReportData] = useState([]);

  // Pobieranie raportu z widoku V_Cook_Today
  const fetchReport = async () => {
    try {
      const response = await fetch(`${API_URL}/reports/what-to-cook`);
      
      if (!response.ok) {
        throw new Error(`Błąd serwera: ${response.status}`);
      }
      
      const data = await response.json(); // Odpakowujemy format JSON
      setReportData(data);
    } catch (error) {
      console.error("Błąd pobierania raportu:", error);
    }
  };

  useEffect(() => {
    fetchReport();
  }, []);


  // TODO: funkcje obsługujące bazę danych 
  
  // funkcja do pobierania stanu magazynu (GET /api/inventory)
  // funkcja do rezerwacji dania (POST /api/reservations/reserve)
  // funkcja końca dnia dla Szefa Kuchni (POST /api/admin/end-of-day)

  return (
    <div style={{ 
      fontFamily: '"Segoe UI", Roboto, Helvetica, Arial, sans-serif', 
      padding: '40px', 
      backgroundColor: '#0F172A', 
      color: '#F8FAFC', 
      minHeight: '100vh' 
    }}>
      
      {/* NAGŁÓWEK DASHBOARDU */}
      <header style={{ marginBottom: '40px' }}>
        <h1 style={{ color: '#38BDF8', margin: '0 0 5px 0', fontSize: '2.2rem' }}>
          Inteligenta Spiżarnia
        </h1>
      </header>
      
      {/* CO UGOTOWAĆ */}
      <section style={{ 
        backgroundColor: '#1E293B', 
        padding: '25px', 
        borderRadius: '16px',
        border: '1px solid #334155',
        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.5)'
      }}>
        <h2 style={{ marginTop: 0, color: '#F1F5F9', borderBottom: '1px solid #334155', paddingBottom: '15px' }}>
          Co można ugotować?
        </h2>
        
        <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '20px', textAlign: 'left' }}>
          <thead>
            <tr>
              <th style={{ padding: '15px', color: '#64748B', fontWeight: 'normal', borderBottom: '2px solid #334155' }}>Nazwa Dania</th>
              <th style={{ padding: '15px', color: '#64748B', fontWeight: 'normal', borderBottom: '2px solid #334155' }}>Kategoria</th>
              <th style={{ padding: '15px', color: '#64748B', fontWeight: 'normal', borderBottom: '2px solid #334155' }}>Możliwych Porcji</th>
              <th style={{ padding: '15px', color: '#64748B', fontWeight: 'normal', borderBottom: '2px solid #334155' }}>Najpilniejszy Składnik</th>
            </tr>
          </thead>
          <tbody>
            {reportData.length === 0 ? (
              <tr>
                <td colSpan="4" style={{ padding: '30px', textAlign: 'center', color: '#64748B' }}>
                  Brak dań możliwych do ugotowania (brak świeżych składników).
                </td>
              </tr>
            ) : (
              reportData.map((dish, index) => (
                <tr key={index} style={{ 
                  backgroundColor: index % 2 === 0 ? '#0F172A' : '#1E293B',
                  transition: 'background-color 0.2s'
                }}>
                  <td style={{ padding: '15px', borderBottom: '1px solid #334155', fontWeight: 'bold' }}>
                    {dish["Nazwa Dania"]}
                  </td>
                  <td style={{ padding: '15px', borderBottom: '1px solid #334155', color: '#94A3B8' }}>
                    {dish["Kategoria"]}
                  </td>
                  <td style={{ padding: '15px', borderBottom: '1px solid #334155', color: '#22C55E', fontWeight: 'bold' }}>
                    {dish["Możliwych Porcji"]} szt.
                  </td>
                  <td style={{ padding: '15px', borderBottom: '1px solid #334155', color: '#EF4444' }}>
                    {dish["Najpilniejszy Składnik"]}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </section>

      {/* TODO: wyświetlanie magazynu i przyciski akcji */}

      <div style={{ 
        marginTop: '40px', 
        padding: '25px', 
        border: '2px dashed #38BDF8', 
        backgroundColor: 'rgba(56, 189, 248, 0.05)',
        borderRadius: '16px' 
      }}>
        
      </div>

    </div>
  );
}

export default App;