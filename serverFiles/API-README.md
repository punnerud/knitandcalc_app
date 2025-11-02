# KnitAndCalc Yarn Stash API

## Installasjon på server

### Krav
- PHP 7.0 eller nyere
- SQLite3 støtte aktivert i PHP
- Skrivetilgang til mappen der `api-yarn.php` ligger

### Oppsett

1. **Last opp `api-yarn.php` til serveren**
   ```bash
   # Last opp til https://knitandcalc.com/api-yarn.php
   scp api-yarn.php user@server:/path/to/web/root/
   ```

2. **Sett riktige tillatelser**
   ```bash
   # Gi PHP skrivetilgang til mappen (for å opprette yarn.db)
   chmod 755 /path/to/web/root/
   chmod 644 /path/to/web/root/api-yarn.php
   ```

3. **Test APIet**
   ```bash
   # Test med curl
   curl -X POST https://knitandcalc.com/api-yarn.php \
     -H "Content-Type: application/json" \
     -H "X-Device-Info: iPhone14,2; iOS 17.0" \
     -H "X-App-Version: 1.0.0 (1)" \
     -d '{"userId":"test-user-123","timestamp":"2025-10-08T12:00:00Z","yarnStash":[]}'
   ```

### Database struktur

Filen `yarn.db` opprettes automatisk ved første bruk.

**Tabell: `yarn_stash_submissions`**

| Kolonne | Type | Beskrivelse |
|---------|------|-------------|
| id | INTEGER | Primærnøkkel (auto-increment) |
| user_id | TEXT | Anonym bruker-ID fra app |
| idempotency_key | TEXT | SHA256 hash av yarnStash array (for duplikatsjekk) |
| payload_json | TEXT | Full JSON payload (inkluderer usageStatistics) |
| timestamp_first_received | TEXT | Første gang denne data ble mottatt (ISO 8601) |
| timestamp_last_received | TEXT | Siste gang denne data ble mottatt (ISO 8601) |
| timestamp_file | TEXT | Tidspunkt fra payload |
| ip_address | TEXT | Klient IP-adresse |
| device_info | TEXT | Enhetsinfo (iPhone modell, iOS versjon) |
| app_version | TEXT | App versjon |
| payload_hash | TEXT | SHA256 hash av payload |
| payload_hash_salted | TEXT | SHA256 hash av payload + salt |
| hash_valid | INTEGER | 1 hvis payload hash er validert, 0 ellers |
| salted_hash_valid | INTEGER | 1 hvis salted hash er validert, 0 ellers |
| yarn_count | INTEGER | Antall garn i payload |
| receive_count | INTEGER | Antall ganger samme data er mottatt (default: 1) |
| created_at | DATETIME | Opprettet tidspunkt (database timestamp) |

**Bruksstatistikk (inkludert i `usageStatistics` felt i payload_json):**
- `projectsCount`: Antall prosjekter brukeren har
- `recipesCount`: Antall oppskrifter brukeren har
- `projectsOpenCount`: Antall ganger Prosjekter-visningen er åpnet
- `yarnStashOpenCount`: Antall ganger Garnlager-visningen er åpnet
- `recipesOpenCount`: Antall ganger Oppskrifter-visningen er åpnet
- `yarnCalculatorOpenCount`: Antall ganger Garnkalkulator er åpnet
- `stitchCalculatorOpenCount`: Antall ganger Strikkekalkulator er åpnet
- `rulerOpenCount`: Antall ganger Linjal er åpnet
- `yarnStockCounterOpenCount`: Antall ganger Garnlager Teller er åpnet
- `settingsOpenCount`: Antall ganger Innstillinger er åpnet

**Indekser:**
- `idx_user_id` - For rask søk på bruker-ID
- `idx_idempotency` - For rask søk på user_id + idempotency_key
- `idx_timestamp_received` - For rask søk på tidspunkt

**Idempotency:**
- Hvis samme garnlager-data sendes flere ganger (basert på `idempotency_key`), opprettes ikke nytt innslag
- I stedet oppdateres `timestamp_last_received` og `receive_count` incrementeres
- Dette forhindrer duplikate innslag når brukeren ikke har endret garnlageret sitt

### Request format

**Headers:**
```
Content-Type: application/json
X-Payload-Hash: <sha256 av payload>
X-Payload-Hash-Salted: <sha256 av payload + "essTF4dY6639">
X-Idempotency-Key: <sha256 av yarnStash array>
X-Device-Info: <iPhone modell>; iOS <versjon>
X-App-Version: <versjon> (<build>)
```

**Body:**
```json
{
  "userId": "UUID-string",
  "timestamp": "2025-10-08T12:00:00Z",
  "yarnStash": [
    {
      "id": "uuid",
      "brand": "Garnprodusent",
      "type": "Garntype",
      "weightPerSkein": 50,
      "lengthPerSkein": 175,
      "numberOfSkeins": 5,
      "color": "Farge",
      "colorNumber": "123",
      "lotNumber": "456",
      "notes": "Notater",
      "gauge": "22/10",
      "dateCreated": "2025-10-08T12:00:00Z"
    }
  ],
  "usageStatistics": {
    "projectsCount": 5,
    "recipesCount": 12,
    "projectsOpenCount": 23,
    "yarnStashOpenCount": 45,
    "recipesOpenCount": 8,
    "yarnCalculatorOpenCount": 15,
    "stitchCalculatorOpenCount": 32,
    "rulerOpenCount": 7,
    "yarnStockCounterOpenCount": 3,
    "settingsOpenCount": 6
  }
}
```

### Response format

**Success (200) - Ny data:**
```json
{
  "success": true,
  "message": "Yarn stash data received (new)",
  "received_at": "2025-10-08T12:00:00+00:00",
  "yarn_count": 5,
  "idempotency_key": "abc123...",
  "receive_count": 1,
  "is_update": false
}
```

**Success (200) - Duplikat data (ingen endring):**
```json
{
  "success": true,
  "message": "Yarn stash data updated (no changes)",
  "received_at": "2025-10-08T12:00:00+00:00",
  "yarn_count": 5,
  "idempotency_key": "abc123...",
  "receive_count": 3,
  "is_update": true
}
```

**Error (400/500):**
```json
{
  "error": "Error message"
}
```

### Sikkerhet

- **Hash-validering**: APIet validerer SHA256 hashes for å sikre dataintegritet
  - `X-Payload-Hash`: Beregnes som SHA256 av hele JSON payload
  - `X-Payload-Hash-Salted`: Beregnes som SHA256 av JSON payload + "essTF4dY6639"
  - Valideringsstatus lagres i databasen (`hash_valid`, `salted_hash_valid`)
  - Requests med ugyldige hashes avvises med 400-feil
- IP-adresser lagres for logging/sikkerhet
- Bruker-ID er anonym UUID generert på enheten
- Ingen personlig identifiserbar informasjon lagres

### Database-vedlikehold

```bash
# Se antall unike garnlager
sqlite3 yarn.db "SELECT COUNT(*) FROM yarn_stash_submissions;"

# Se siste 10 innsendinger med receive_count
sqlite3 yarn.db "SELECT id, user_id, yarn_count, receive_count, timestamp_last_received FROM yarn_stash_submissions ORDER BY id DESC LIMIT 10;"

# Se bruksstatistikk fra siste innsendinger
sqlite3 yarn.db "SELECT user_id, json_extract(payload_json, '$.usageStatistics') as stats FROM yarn_stash_submissions ORDER BY id DESC LIMIT 10;"

# Se gjennomsnittlig bruk per funksjon
sqlite3 yarn.db "SELECT
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.projectsOpenCount') AS INTEGER)) as avg_projects,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.yarnStashOpenCount') AS INTEGER)) as avg_yarnstash,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.recipesOpenCount') AS INTEGER)) as avg_recipes,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.yarnCalculatorOpenCount') AS INTEGER)) as avg_yarncalc,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.stitchCalculatorOpenCount') AS INTEGER)) as avg_stitchcalc,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.rulerOpenCount') AS INTEGER)) as avg_ruler,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.yarnStockCounterOpenCount') AS INTEGER)) as avg_counter,
  AVG(CAST(json_extract(payload_json, '$.usageStatistics.settingsOpenCount') AS INTEGER)) as avg_settings
FROM yarn_stash_submissions;"

# Se statistikk per enhet
sqlite3 yarn.db "SELECT device_info, COUNT(*) as count FROM yarn_stash_submissions GROUP BY device_info ORDER BY count DESC;"

# Se brukere med flest duplikate innsendinger
sqlite3 yarn.db "SELECT user_id, SUM(receive_count) as total_receives FROM yarn_stash_submissions GROUP BY user_id ORDER BY total_receives DESC LIMIT 10;"

# Se gjennomsnittlig receive_count
sqlite3 yarn.db "SELECT AVG(receive_count) as avg_receives FROM yarn_stash_submissions;"

# Se innsendinger med høy receive_count (mulig indikasjon på problem)
sqlite3 yarn.db "SELECT user_id, yarn_count, receive_count, timestamp_first_received, timestamp_last_received FROM yarn_stash_submissions WHERE receive_count > 5 ORDER BY receive_count DESC;"

# Se hash-valideringsstatus
sqlite3 yarn.db "SELECT COUNT(*) as total, SUM(hash_valid) as valid_hash, SUM(salted_hash_valid) as valid_salted FROM yarn_stash_submissions;"

# Se innsendinger med feil hash-validering
sqlite3 yarn.db "SELECT id, user_id, hash_valid, salted_hash_valid, timestamp_last_received FROM yarn_stash_submissions WHERE hash_valid = 0 OR salted_hash_valid = 0;"

# Backup database
cp yarn.db yarn_backup_$(date +%Y%m%d).db
```

### Feilsøking

1. **"Database error"**
   - Sjekk at PHP har skrivetilgang til mappen
   - Sjekk at SQLite3 er aktivert i PHP (`php -m | grep sqlite`)

2. **"Invalid JSON"**
   - Valider JSON payload med JSONLint
   - Sjekk at Content-Type header er satt

3. **"Invalid payload hash"**
   - Sjekk at iOS-appen sender riktige hash-verdier
   - Verifiser at salt-verdien er korrekt ("essTF4dY6639")
