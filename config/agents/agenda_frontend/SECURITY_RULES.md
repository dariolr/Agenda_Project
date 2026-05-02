# agenda_frontend Security Rules

- Access token solo in memoria.
- Refresh token solo in cookie httpOnly.
- Non salvare refresh token in localStorage/sessionStorage.
- CORS credentials solo con origin esplicito.
- HTTPS obbligatorio in produzione.
- Logout deve pulire stato locale e sessione server.
