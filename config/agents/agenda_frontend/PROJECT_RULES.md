# agenda_frontend Agent Rules

Frontend prenotazioni clienti Flutter.

Regole:

- Non mostrare nel booking pubblico elementi non prenotabili online.
- Rispettare visibilità:
  - pubblico
  - non prenotabile online
  - solo direct link
- Direct link deve vincolare il flow quando previsto dal prodotto.
- Non rompere login, register, my-bookings.
- Preservare slug business e query params.
- Lingua booking risolta da location/business/query secondo logica esistente.