#!/bin/bash
# csp: Consumo di Suolo Procapite
# ren: renaturalization


# === PARAMETRI: anni e livello ===
REFERENCE_YEAR=$1
CURRENT_YEAR=$2
MODE=$3  # "append" oppure "overwrite"
LEVEL=$4 # "municipalities", "provinces", "regions"

if [[ "$MODE" != "append" && "$MODE" != "overwrite" ]]; then
  echo "[ERROR] Parametro 3 non valido. Usa 'append' oppure 'overwrite'."
  exit 1
fi

if [[ "$LEVEL" != "municipalities" && "$LEVEL" != "provinces" && "$LEVEL" != "regions" ]]; then
  echo "[ERROR] Parametro 4 non valido. Usa 'municipalities', 'provinces' oppure 'regions'."
  exit 1
fi

FILE_SUOLO="${LEVEL}_sdg11-3-1_${REFERENCE_YEAR}_${CURRENT_YEAR}.gpkg"
FILE_RENAT="${LEVEL}_renaturalization_${REFERENCE_YEAR}_${CURRENT_YEAR}.gpkg"

PG_CONN="PG:host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver"
DOCKER_CONTAINER="postgres"
DOCKER_PSQL_CMD="docker exec $DOCKER_CONTAINER psql -U geoserver -d geoserver -tA -c "
TABLE_SUOLO="${LEVEL}_indicators"
TABLE_RENAT="${LEVEL}_renaturalization"

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/import_log_${LEVEL}_${REFERENCE_YEAR}_${CURRENT_YEAR}.csv"

# ====== FUNZIONI UTILI ======
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}
info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}
warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}
error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}
success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

# ====== CONTROLLO PRESENZA RECORD ======
info "Verifico se ci sono già record per gli anni $CURRENT_YEAR - $REFERENCE_YEAR..."

EXISTING_SUOLO=$($DOCKER_PSQL_CMD "SELECT COUNT(*) FROM $TABLE_SUOLO WHERE current_time = '$CURRENT_YEAR' AND reference_time = '$REFERENCE_YEAR';")
EXISTING_RENAT=$($DOCKER_PSQL_CMD "SELECT COUNT(*) FROM $TABLE_RENAT WHERE current_time = '$CURRENT_YEAR' AND reference_time = '$REFERENCE_YEAR';" 2>/dev/null || echo 0)

echo "EXISTING_SUOLO: $EXISTING_SUOLO"
echo "EXISTING_RENAT: $EXISTING_RENAT"

if [[ "$EXISTING_SUOLO" =~ ^[0-9]+$ && "$EXISTING_RENAT" =~ ^[0-9]+$ ]]; then
  if [ "$EXISTING_SUOLO" -gt 0 ] || [ "$EXISTING_RENAT" -gt 0 ]; then
    warn "Sono già presenti $EXISTING_SUOLO record in $TABLE_SUOLO e $EXISTING_RENAT in $TABLE_RENAT per $CURRENT_YEAR-$REFERENCE_YEAR ($LEVEL)"
    read -p "Vuoi continuare comunque? [s/N] " choice
    [[ "$choice" != "s" && "$choice" != "S" ]] && error "Importazione annullata dall’utente." && exit 1
  fi
else
  warn "Valori non numerici rilevati, salto il controllo duplicati."
fi

# ====== IMPORTAZIONE FILE SUOLO ======
info "Caricamento file $FILE_SUOLO nella tabella $TABLE_SUOLO..."
ogr2ogr \
  -f "PostgreSQL" \
  "$PG_CONN" \
  "$FILE_SUOLO" \
  -nln "$TABLE_SUOLO" \
  "-$MODE"

# ====== IMPORTAZIONE FILE RENATURALIZZAZIONE ======
info "Caricamento file $FILE_RENAT nella tabella $TABLE_RENAT con colonne anno on-the-fly..."
ogr2ogr \
  -f "PostgreSQL" \
  "$PG_CONN" \
  "$FILE_RENAT" \
  -nln "$TABLE_RENAT" \
  -sql "SELECT *, CAST($CURRENT_YEAR AS INTEGER) AS current_time, CAST($REFERENCE_YEAR AS INTEGER) AS reference_time FROM ${LEVEL}_renaturalization_${REFERENCE_YEAR}_${CURRENT_YEAR}" \
  "-$MODE"

# ====== TRANSAZIONE SQL CON ROLLBACK ======
info "Esecuzione del merge dei dati rinaturalizzazione con transazione..."

# 1. ADD rinaturalizzazione if not existent
docker exec -i $DOCKER_CONTAINER bash -c "psql -d geoserver -U geoserver" <<EOF
ALTER TABLE $TABLE_SUOLO ADD COLUMN IF NOT EXISTS rinaturalizzazione NUMERIC;
EOF
echo "[INFO] ADD eseguito correttamente."

# Subito dopo controllo se è andato tutto bene
if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to add column 'rinaturalizzazione' to $TABLE_SUOLO." >&2
  exit
fi

# 2. Poi la transazione UPDATE
docker exec -i $DOCKER_CONTAINER bash -c "psql -e -d geoserver -U geoserver" <<EOF
BEGIN;

UPDATE $TABLE_SUOLO m
SET rinaturalizzazione = r.rinaturalizzazione
FROM $TABLE_RENAT r
WHERE m.pro_com_t = r.pro_com_t
  AND m.comune = r.comune
  AND m.current_time = r.current_time
  AND m.reference_time = r.reference_time;

COMMIT;
EOF

echo "[INFO] Merge eseguito correttamente."

# Controllo dell'esito
if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to execute SQL transaction: rinaturalizzazione update failed." >&2
  exit 1
fi

success "Merge completato correttamente."

# ====== LOG FINALE ======
echo "\"$(date '+%Y-%m-%d %H:%M:%S')\",\"$LEVEL\",\"$REFERENCE_YEAR\",\"$CURRENT_YEAR\",\"$EXISTING_SUOLO\",\"$EXISTING_RENAT\",\"OK\"" >> "$LOGFILE"
success "Log scritto in $LOGFILE"

echo ">> Procedura completata per $LEVEL $CURRENT_YEAR - $REFERENCE_YEAR ✅"

