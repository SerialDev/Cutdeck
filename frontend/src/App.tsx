import { useState, useEffect } from 'react'
import './App.css'

interface BackendStatus {
  status: string
  message: string
}

function App() {
  const [backendStatus, setBackendStatus] = useState<BackendStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const checkBackend = async () => {
      try {
        const response = await fetch('/api/health')
        if (response.ok) {
          const data = await response.json()
          setBackendStatus(data)
        } else {
          setError('Backend returned an error')
        }
      } catch {
        setError('Could not connect to backend')
      } finally {
        setLoading(false)
      }
    }

    checkBackend()
  }, [])

  return (
    <div className="app">
      <header className="header">
        <h1>Cutdeck</h1>
        <p className="subtitle">React 19 + TypeScript + Vite</p>
      </header>

      <main className="main">
        <section className="card">
          <h2>Backend Status</h2>
          {loading && <p className="loading">Checking backend...</p>}
          {error && <p className="error">{error}</p>}
          {backendStatus && (
            <div className="status">
              <p className="status-ok">Connected</p>
              <p>{backendStatus.message}</p>
            </div>
          )}
        </section>

        <section className="card">
          <h2>Tech Stack</h2>
          <ul className="tech-list">
            <li><strong>Frontend:</strong> React 19 + TypeScript + Vite</li>
            <li><strong>Backend:</strong> Python + DaggyD + Cloudflare Pages Functions</li>
            <li><strong>Database:</strong> Cloudflare D1 (SQLite at the edge)</li>
            <li><strong>Storage:</strong> Cloudflare Workers KV</li>
            <li><strong>Tunnel:</strong> Cloudflare Tunnel (cloudflared)</li>
            <li><strong>CI/CD:</strong> GitHub Actions</li>
            <li><strong>Hosting:</strong> Cloudflare Pages</li>
          </ul>
        </section>
      </main>

      <footer className="footer">
        <p>Running via Docker + Cloudflare Tunnel</p>
      </footer>
    </div>
  )
}

export default App
