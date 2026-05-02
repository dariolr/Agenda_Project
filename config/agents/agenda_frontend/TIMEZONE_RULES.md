# agenda_frontend Timezone Rules

- Usare timezone location/business restituito da API, non device/browser.
- Mostrare slot secondo timezone tenant/location.
- Inviare date/orari nel formato atteso da API.
- Non cambiare frequenza slot senza controllare `online_booking_slot_interval_minutes`.
- Non fare calcoli di disponibilità lato client basati su timezone locale.
