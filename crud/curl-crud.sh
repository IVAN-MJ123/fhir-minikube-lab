#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-$(../scripts/print-url.sh)}"

extract_id() {
  sed -E 's#.*/Patient/([^/]+)/_history.*#\1#'
}

echo "[*] Usando BASE_URL=${BASE_URL}"

# --- Patient: CREATE ---
echo "[*] Creando Patient..."
PATIENT_LOC="$(curl -sS -D - -o /dev/null \
  -H 'Content-Type: application/fhir+json' \
  -X POST "${BASE_URL}/fhir/Patient" \
  --data-binary "@../data/patient.json" \
  | grep -i '^Location: ' | tr -d '\r')"

PATIENT_ID="$(echo "${PATIENT_LOC}" | extract_id || true)"

echo "    Location: ${PATIENT_LOC}"
echo "    Patient ID: ${PATIENT_ID}"

# --- Patient: READ ---
echo "[*] Leyendo Patient..."
curl -sS "${BASE_URL}/fhir/Patient/${PATIENT_ID}" | jq .

# --- Patient: UPDATE ---
echo "[*] Actualizando Patient..."

UPDATED_JSON=$(jq --arg id "$PATIENT_ID" '. + {id: $id}' ../data/patient-update.json)

echo "$UPDATED_JSON" | curl -sS -X PUT \
  -H 'Content-Type: application/fhir+json' \
  --data-binary @- \
  "${BASE_URL}/fhir/Patient/${PATIENT_ID}" | jq .

# --- Patient: DELETE ---
echo "[*] Eliminando Patient..."
curl -sS -X DELETE \
  "${BASE_URL}/fhir/Patient/${PATIENT_ID}"

echo "[✓] CRUD completado"