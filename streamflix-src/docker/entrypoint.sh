#!/bin/sh
# Läuft als root nur für Vorbereitungen (Rechte am Datenverzeichnis).
# Der Supervisor startet danach alle Dienste als unprivilegierten Benutzer "app".
set -e
mkdir -p /data /tmp
chown -R app:app /data 2>/dev/null || true
chmod 750 /data 2>/dev/null || true
exec "$@"
