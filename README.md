# STREAMFLIX – Community App Store für CasaOS

Selbst gehostete Streaming-Plattform im Netflix-Stil für **deine eigenen** Filme und Serien (Docker, `arm64` und `amd64`).
Mehrere Konten mit Profilen (PIN, Kinderprofil), Meine Liste, Weiterschauen, Empfehlungen, Suche, Untertitel, Audiospuren,
Direct Play oder HLS (FFmpeg), Medienordner-Manager mit Scanner und ein vollständiges Admin-Center. Alles lokal, ohne Cloud.

## Warum ein GitHub-Workflow?
CasaOS baut Apps nicht selbst, es lädt fertige Images. Deshalb enthält das Repository einen **GitHub-Workflow**, der das Image
bei GitHub baut und bei ghcr.io ablegt. Du musst dafür **keine Docker-Befehle** ausführen und **keine Datei bearbeiten**: der Workflow trägt
auch deinen GitHub-Namen automatisch in die Compose-Datei ein.

## Installation
1. **Repository anlegen:** Auf GitHub ein neues **öffentliches** Repository erstellen (z. B. `streamflix-casaos-store`, Standard-Branch `main`).
2. **Hochladen:** Den **Inhalt** der ZIP hochladen (Add file → Upload files). Wichtig: auch der versteckte Ordner `.github`
   muss hinein. Falls dein Browser versteckte Ordner nicht anzeigt/zieht: Auf GitHub „Add file → Create new file“, als Name
   `.github/workflows/build-image.yml` eintippen und den Inhalt der Datei aus der ZIP einfügen.
3. **Warten:** Unter dem Reiter **Actions** läuft „build-image“. Das erste Mal dauert es **ca. 15–30 Minuten** (arm64-Build per Emulation).
   Grüner Haken = fertig. Der Workflow macht zusätzlich einen Commit „Eigenen GitHub-Namen in docker-compose.yml eingetragen“.
4. **Paket öffentlich machen (falls nötig):** GitHub → dein Profil → **Packages** → `streamflix` → **Package settings** → Sichtbarkeit **Public**.
   (Meist ist es schon öffentlich, weil es mit dem öffentlichen Repository verknüpft ist. Ist es privat, kann CasaOS das Image nicht laden.)
5. **Store hinzufügen:** CasaOS → **App Store** → **Quelle hinzufügen** (Add Source) und diese URL eintragen:
   `https://github.com/DEIN-NAME/DEIN-REPO/archive/refs/heads/main.zip`
6. **STREAMFLIX** im App Store suchen (Kategorie Media) → **Installieren**.
7. App öffnen (Standard-Port **8484**) → **Administrator-Konto erstellen** (das erste Konto wird Superadmin).
8. **Admin-Center** (`/admin/`, Menü oben rechts) → **Medienordner** → **Ordner hinzufügen** → **Durchsuchen** → Typ wählen → speichern → Scan starten.

**Alternative ohne Store:** Nach Schritt 3 in CasaOS → App Store → **Custom Install** → `Apps/Streamflix/docker-compose.yml` (nach dem Workflow-Commit) importieren.

## Medien einbinden
Der Container bekommt **ausschließlich lesenden** Zugriff (`:ro`):

| Auf dem CasaOS-Host | Im Container | Typischer Pfad im Admin-Center |
|---|---|---|
| `/DATA` (Hauptspeicher von CasaOS) | `/media/data` | `/media/data/Media/Movies`, `/media/data/Media/TV Shows` |
| `/media` (extern angeschlossene Laufwerke) | `/media/external` | `/media/external/<Laufwerksname>/Filme` |

* Lege Filme/Serien über die CasaOS-**Dateien**-App z. B. unter `Media/Movies` und `Media/TV Shows` ab. Der Ordner-Dialog im Admin-Center hat einen **„Durchsuchen“**-Knopf.
* Das Admin-Panel kann keine zusätzlichen Host-Verzeichnisse freigeben und ändert keine Container-Einstellungen. Alles außerhalb von `/media` wird abgelehnt.
* **USB-Festplatten:** CasaOS hängt sie üblicherweise unter `/media/<Name>` ein. Nach dem Anschließen die App **neu starten** (CasaOS → App → Neustart), damit der neue Mount sichtbar wird. Erscheint dein Laufwerk nicht unter `/media/external`, hängt es bei deiner Version woanders; dann musst du in der App-Einstellung (CasaOS → App → Einstellungen → Volumes) den Host-Pfad der Zeile `/media/external` anpassen.
* Wird ein Laufwerk getrennt, löscht der Scanner **nichts**, er meldet nur „Ordner nicht lesbar“.
* Dateirechte: Der Container läuft als unprivilegierter Benutzer. Medien müssen für „andere“ lesbar sein (CasaOS-Standard ist das in der Regel).

### Ordnerstruktur & Metadaten
```
Filme:   Film (2020).mp4 | Film.2019.1080p.mkv
Serien:  Serienname/Season 1/Serienname.S01E01.mkv   (auch 1x01 oder „Staffel 1“)
```
* Titel/Jahr aus Dateinamen; liegen **Kodi-NFO-Dateien** (`film.nfo`, `tvshow.nfo`) daneben, werden Beschreibung, Genres, Regie, Besetzung, Altersfreigabe übernommen.
* Bilder: `poster.jpg`/`folder.jpg`/`fanart.jpg` werden lokal kopiert; sonst erzeugt FFmpeg Vorschaubilder.
* **Keine Online-Metadatenanbieter** (funktioniert offline). Genres kommen aus NFO, Ordnernamen (`Anime`, `Dokumentationen`) oder manueller Bearbeitung im Admin-Center.
* Untertitel: `.srt/.vtt/.ass` neben dem Video (`Film.de.srt`) und eingebettete Textuntertitel.
* Intro überspringen: aus Kapitelmarken („Intro“) oder pro Serie im Admin-Center einstellbar.

## Wiedergabe & Leistung
* **Direct Play** (kein CPU-Aufwand): MP4/M4V/MOV mit H.264+AAC/MP3, WebM.
* **Remux (HLS)**: z. B. MKV mit H.264 – Video wird nur umgepackt. Sehr leicht.
* **Transkodierung** (x264, Software): HEVC, AVI, 10-Bit usw. Auf kleiner Hardware (z. B. Raspberry Pi) nur in niedriger Auflösung in Echtzeit; Standard 720p und **1 gleichzeitige Transkodierung** (Admin → Einstellungen). Keine Hardware-Beschleunigung enthalten.
* Tipp: Medien möglichst als H.264/AAC (MP4/MKV) vorbereiten.

## Sicherheit
STREAMFLIX hat **eigene Konten** (CasaOS selbst schützt die App nicht). Schalte die Registrierung im Admin-Center ab, wenn niemand sonst ein Konto anlegen soll,
und setze die App nicht ohne VPN (z. B. Tailscale) direkt ins Internet.

## Backups
Admin-Center → Backups: Datenbank + lokale Bilder als ZIP, manuell oder automatisch (Standard täglich, 7 aufbewahrt). Wiederherstellung nur für Superadmins. Originalmedien werden nie gesichert. Dateien liegen unter `/DATA/AppData/streamflix/data/backups`.

## Update
1. Quellcode in `streamflix-src/` ändern und in `Apps/Streamflix/docker-compose.yml` die Version im Image-Tag erhöhen (`…/streamflix:1.0.1`, nach dem Workflow steht dort dein Name).
2. Hochladen, Workflow abwarten, in CasaOS die App aktualisieren bzw. neu installieren (Daten in `/DATA/AppData/streamflix` bleiben, Datenbank-Migrationen laufen automatisch).

## Fehlerbehebung
| Problem | Lösung |
|---|---|
| Workflow rot | Reiter **Actions** → Lauf öffnen → Fehler lesen. Häufig: `.github`-Ordner fehlt oder Actions sind im Repository deaktiviert (Settings → Actions → Allow). Bei „permission denied“ beim Commit: Settings → Actions → General → Workflow permissions → **Read and write**. |
| Installation: Image nicht gefunden / unauthorized | Workflow noch nicht fertig, oder Paket ist privat (Schritt 4). Compose enthält noch `GITHUB_OWNER`? Dann ist der Workflow nicht gelaufen. |
| Store wird nicht erkannt | URL muss auf `…/archive/refs/heads/main.zip` enden, Repo öffentlich, Branch `main`, Ordner `Apps/Streamflix` vorhanden. |
| „Ordner nicht gefunden“ | Pfad muss mit `/media/` beginnen. „Durchsuchen“ nutzen. |
| Keine Titel nach Scan | Ordnertyp prüfen (Filme/Serien), Admin → Medienordner → Scan-Meldungen, Protokoll ansehen. |
| Ruckeln | Admin → Aktive Streams: Modus „Transcode“ ist rechenintensiv. Medien als H.264/AAC bereitstellen. |
| Port 8484 belegt | Beim Installieren in den Einstellungen einen anderen Host-Port wählen. |
| Passwort vergessen | Anderer Admin: Benutzer → Bearbeiten → Passwort zurücksetzen. |

## Entwicklung / Tests
`streamflix-src/` enthält Dockerfile, Anwendung (PHP 8.3 + SQLite + nginx + FFmpeg) und Konfiguration.
End-to-End-Test gegen eine laufende Instanz: `python3 streamflix-src/app/tests/smoke_test.py http://HOST:8484`.

Lizenz: MIT (`LICENSE`). Enthält hls.js (Apache-2.0). Es werden keine Netflix-Marken oder -Assets verwendet.
