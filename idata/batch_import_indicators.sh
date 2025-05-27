#!/bin/bash
# DESCRIPTION
#  Execute the `import_indicators_csp_ren.sh` script in a loop.
#
# CALL
#  ./batch_import_indicators.sh 2015 2023

START_YEAR=$1
END_YEAR=$2
LEVELS=("municipalities" "provinces" "regions")  # puoi modificare questa lista

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG_MISSING="$LOG_DIR/missing.csv"
echo "level,reference_year,current_year" > "$LOG_MISSING"

for LEVEL in "${LEVELS[@]}"; do
  FIRST_RUN=true
  for (( REF=$START_YEAR; REF<=$END_YEAR; REF++ )); do
    for (( CUR=REF+1; CUR<=$END_YEAR; CUR++ )); do

      FILE_SUOLO="${LEVEL}_sdg11-3-1_${REF}_${CUR}.gpkg"
      FILE_RENAT="${LEVEL}_renaturalization_${REF}_${CUR}.gpkg"

      if [[ -f "$FILE_SUOLO" && -f "$FILE_RENAT" ]]; then
        if $FIRST_RUN; then
          MODE="overwrite"
          FIRST_RUN=false
        else
          MODE="append"
        fi
        echo "[INFO] Trovati file per $LEVEL $REF-$CUR: avvio importazione con mode=$MODE."
        ./import_indicators_csp_ren.sh "$REF" "$CUR" "$MODE" "$LEVEL"
      else
        echo "[WARN] File mancanti per $LEVEL $REF-$CUR"
        echo "$LEVEL,$REF,$CUR" >> "$LOG_MISSING"
      fi

    done
  done
done

echo "\n[INFO] Completato ciclo su tutti gli anni e livelli. Log dei file mancanti in: $LOG_MISSING"

