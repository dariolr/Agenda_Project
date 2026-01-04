# Model Map — agenda_core

Questo documento elenca i modelli reali usati dai client Flutter e i campi con tipi e nullabilità.
I campi **vincolanti** (snake_case) NON possono essere rinominati.

---

## 📦 Frontend (prenotazione online)

### ServiceCategory
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| name | String | ✗ | `name` |
| description | String | ✓ | `description` |
| sortOrder | int | ✗ (default: 0) | `sort_order` |

### Service
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| categoryId | int | ✗ | `category_id` |
| name | String | ✗ | `name` |
| description | String | ✓ | `description` |
| sortOrder | int | ✗ (default: 0) | `sort_order` |
| durationMinutes | int | ✗ (default: 30) | `duration_minutes` |
| price | double | ✗ (default: 0.0) | `price` |
| isFree | bool | ✗ (default: false) | `is_free` |
| isPriceStartingFrom | bool | ✗ (default: false) | `is_price_starting_from` |
| isBookableOnline | bool | ✗ (default: true) | `is_bookable_online` |

### Staff
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| name | String | ✗ | `name` |
| surname | String | ✗ (default: '') | `surname` |
| avatarUrl | String | ✓ | `avatar_url` |
| sortOrder | int | ✗ (default: 0) | `sort_order` |
| isBookableOnline | bool | ✗ (default: true) | `is_bookable_online` |

### TimeSlot
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| startTime | DateTime | ✗ | `start_time` (ISO8601) |
| endTime | DateTime | ✗ | `end_time` (ISO8601) |
| staffId | int | ✓ | `staff_id` |

### User
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| email | String | ✗ | `email` |
| firstName | String | ✗ | `first_name` |
| lastName | String | ✗ | `last_name` |
| phone | String | ✓ | `phone` |
| createdAt | DateTime | ✗ | `created_at` (ISO8601) |

### BookingRequest (payload POST /bookings)
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| services | List<Service> | ✗ | → `service_ids` (array int) |
| selectedStaff | Staff | ✓ | → `staff_id` (int) |
| selectedSlot | TimeSlot | ✓ | → `start_time` (ISO8601) |
| notes | String | ✓ | `notes` |

**⚠️ Payload finale inviato al server:**
```json
{
  "service_ids": [1, 2],
  "staff_id": 5,
  "start_time": "2025-01-15T10:00:00Z",
  "notes": "optional"
}
```

---

## 🏢 Backend (gestionale)

### ServiceCategory (Backend)
Identico al frontend.

### Service (Backend)
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| categoryId | int | ✗ | `category_id` |
| name | String | ✗ | `name` |
| description | String | ✓ | `description` |
| sortOrder | int | ✗ (default: 0) | `sort_order` |

> **Nota**: Il backend usa `ServiceVariant` per durata/prezzo per location.

### ServiceVariant
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| serviceId | int | ✗ | `service_id` |
| locationId | int | ✗ | `location_id` |
| durationMinutes | int | ✗ | `duration_minutes` |
| processingTime | int | ✓ | `processing_time` |
| blockedTime | int | ✓ | `blocked_time` |
| price | double | ✗ | `price` |
| colorHex | String | ✓ | `color_hex` |
| currency | String | ✓ | `currency` |
| isBookableOnline | bool | ✗ (default: true) | `is_bookable_online` |
| isFree | bool | ✗ (default: false) | `is_free` |
| isPriceStartingFrom | bool | ✗ (default: false) | `is_price_starting_from` |

### Staff (Backend)
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| name | String | ✗ | `name` |
| surname | String | ✗ (default: '') | `surname` |
| color | Color | ✗ | `color_hex` |
| locationIds | List<int> | ✗ | `location_ids` |
| sortOrder | int | ✗ (default: 0) | `sort_order` |
| isDefault | bool | ✗ (default: false) | `is_default` |
| isBookableOnline | bool | ✗ (default: true) | `is_bookable_online` |

### Location
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| name | String | ✗ | `name` |
| address | String | ✓ | `address` |
| city | String | ✓ | `city` |
| region | String | ✓ | `region` |
| country | String | ✓ | `country` |
| phone | String | ✓ | `phone` |
| email | String | ✓ | `email` |
| latitude | double | ✓ | `latitude` |
| longitude | double | ✓ | `longitude` |
| currency | String | ✓ | `currency` |
| isDefault | bool | ✗ (default: false) | `is_default` |

### Booking
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| locationId | int | ✗ | `location_id` |
| clientId | int | ✓ | `client_id` |
| clientName | String | ✓ | `client_name` |
| notes | String | ✓ | `notes` |

### Appointment (booking item)
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| bookingId | int | ✗ | `booking_id` |
| businessId | int | ✗ | `business_id` |
| locationId | int | ✗ | `location_id` |
| staffId | int | ✗ | `staff_id` |
| serviceId | int | ✗ | `service_id` |
| serviceVariantId | int | ✗ | `service_variant_id` |
| clientId | int | ✓ | `client_id` |
| clientName | String | ✗ (default: '') | `client_name` |
| serviceName | String | ✗ (default: '') | `service_name` |
| startTime | DateTime | ✗ | `start_time` (ISO8601) |
| endTime | DateTime | ✗ | `end_time` (ISO8601) |
| price | double | ✓ | `price` |
| extraMinutes | int | ✓ | `extra_minutes` |
| extraMinutesType | ExtraMinutesType | ✓ | `extra_minutes_type` |
| extraBlockedMinutes | int | ✓ | `extra_blocked_minutes` |
| extraProcessingMinutes | int | ✓ | `extra_processing_minutes` |

### Client
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| firstName | String | ✓ | `first_name` |
| lastName | String | ✓ | `last_name` |
| email | String | ✓ | `email` |
| phone | String | ✓ | `phone` |
| gender | String | ✓ | `gender` |
| birthDate | DateTime | ✓ | `birth_date` |
| city | String | ✓ | `city` |
| notes | String | ✓ | `notes` |
| createdAt | DateTime | ✗ | `created_at` |
| lastVisit | DateTime | ✓ | `last_visit` |
| loyaltyPoints | int | ✓ | `loyalty_points` |
| tags | List<String> | ✓ | `tags` |
| isArchived | bool | ✗ (default: false) | `is_archived` |

### Resource
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| locationId | int | ✗ | `location_id` |
| name | String | ✗ | `name` |
| quantity | int | ✗ | `quantity` |
| type | String | ✓ | `type` |
| note | String | ✓ | `note` |

### TimeBlock
| Campo | Tipo | Nullable | JSON key (vincolante) |
|-------|------|----------|----------------------|
| id | int | ✗ | `id` |
| businessId | int | ✗ | `business_id` |
| locationId | int | ✗ | `location_id` |
| staffIds | List<int> | ✗ | `staff_ids` |
| startTime | DateTime | ✗ | `start_time` (ISO8601) |
| endTime | DateTime | ✗ | `end_time` (ISO8601) |
| reason | String | ✓ | `reason` |
| isAllDay | bool | ✗ (default: false) | `is_all_day` |

---

## 🔒 Riepilogo campi vincolanti

Questi campi sono usati attivamente nei client Flutter e **NON devono essere rinominati**:

| Modello | Campi critici |
|---------|---------------|
| Service | `id`, `business_id`, `category_id`, `name`, `duration_minutes`, `price`, `is_free`, `is_price_starting_from`, `is_bookable_online` |
| Staff | `id`, `business_id`, `name`, `surname`, `is_bookable_online`, `sort_order` |
| TimeSlot | `start_time`, `end_time`, `staff_id` |
| BookingRequest | `service_ids`, `staff_id`, `start_time`, `notes` |
| Booking | `id`, `business_id`, `location_id`, `client_id`, `client_name`, `notes` |
| Appointment | `id`, `booking_id`, `business_id`, `location_id`, `staff_id`, `service_id`, `start_time`, `end_time` |
| User | `id`, `email`, `first_name`, `last_name`, `phone`, `created_at` |
| Client | `id`, `business_id`, `first_name`, `last_name`, `email`, `phone`, `created_at` |
