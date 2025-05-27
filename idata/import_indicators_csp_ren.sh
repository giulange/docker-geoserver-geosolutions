#!/bin/bash

# === PARAMETRI: anni ===
CURRENT_YEAR=$1
REFERENCE_YEAR=$2

# === NOMI FILE DINAMICI ===
FILE_SUOLO="municipalities_sdg11-3-1_${CURRENT_YEAR}_${REFERENCE_YEAR}.gpkg"
FILE_RENAT="municipalities_renaturalization_${CURRENT_YEAR}_${REFERENCE_YEAR}.gpkg"

# === PARAMETRI CONNESSIONE POSTGIS ===
PG_CONN="PG:host=localhost port=5432 dbname=geoserver user=geoserver password=geoserver"

# === TABELLE TARGET ===
TABLE_SUOLO="municipalities_indicators"
TABLE_RENAT="municipalities_renaturalization"

echo ">> Caricamento $FILE_SUOLO in tabella $TABLE_SUOLO..."
ogr2ogr \
  -f "PostgreSQL" \
  "$PG_CONN" \
  "$FILE_SUOLO" \
  -nln "$TABLE_SUOLO" \
  -append

echo ">> Caricamento $FILE_RENAT in tabella $TABLE_RENAT con aggiunta anni $CURRENT_YEAR - $REFERENCE_YEAR..."
ogr2ogr \
  -f "PostgreSQL" \
  "$PG_CONN" \
  "$FILE_RENAT" \
  -nln "$TABLE_RENAT" \
  -sql "SELECT *, $CURRENT_YEAR AS current_time, $REFERENCE_YEAR AS reference_time FROM municipalities_renaturalization" \
  -append

echo ">> Verifica esistenza colonna 'rinaturalizzazione' nella tabella $TABLE_SUOLO..."
psql -d geoserver -U geoserver -c "
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = '$TABLE_SUOLO' AND column_name = 'rinaturalizzazione'
  ) THEN
    ALTER TABLE $TABLE_SUOLO ADD COLUMN rinaturalizzazione NUMERIC;
  END IF;
END
\$\$;
"

echo ">> Merge dei valori di rinaturalizzazione nella tabella $TABLE_SUOLO..."
psql -d geoserver -U geoserver -c "
UPDATE $TABLE_SUOLO m
SET rinaturalizzazione = r.rinaturalizzazione
FROM $TABLE_RENAT r
WHERE m.PRO_COM_T = r.PRO_COM_T
  AND m.COMUNE = r.COMUNE
  AND m.current_time = r.current_time
  AND m.reference_time = r.reference_time;
"

echo ">> Procedura completata per $CURRENT_YEAR - $REFERENCE_YEAR ✅"

