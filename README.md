# Proteinregal

Lebensmittel scannen, automatisch bewerten, nach Kriterien ranken. Single-File-App (`index.html`), Daten in Supabase, Deploy auf GitHub Pages.

## Was automatisch kommt (Open Food Facts)

Name, Marke, Inhalt, kcal, Protein/Fett/KH pro 100 g, NOVA-Gruppe (Verarbeitungsgrad), Eco-Score, CO₂ (Agribalyse-Kategorie-Schätzung, nicht produktspezifisch), Kategorien, Bild.

## Was du einträgst

Preis (ein Feld), Geschmack 1–5 (pro Person), Vielseitigkeit 1–5. Notiz optional. Fehlt OFF ein Wert (Gewicht, Nährwerte), erscheinen die Felder im Detail-Sheet.

## Abgeleitete Kriterien

| Kriterium | Formel | Richtung |
|---|---|---|
| Protein / 100 kcal | protein_100g / kcal_100g × 100 | höher besser |
| Protein / € | protein_100g × Inhalt_g / 100 / Preis | höher besser |
| Preis / kg | Preis / (Inhalt_g / 1000) | niedriger besser |
| Geschmack, Vielseitigkeit | manuell | höher besser |
| NOVA, CO₂ / 100 g, kcal / 100 g | OFF | niedriger besser |

Gesamtscore: jedes Kriterium min-max-normiert über alle Produkte, gewichtet gemittelt (Gewichte 0–3 im ⚖︎-Menü, pro Gerät gespeichert). Fehlende Werte zählen nicht in den Score. Sortierung nach Score oder einem Einzelkriterium, Min/Max-Filter pro Kriterium.

Neues Kriterium: ein Eintrag im `CRITERIA`-Array in `index.html`, ggf. Spalte in `products`. Filter, Sortierung, Score und Karten ziehen automatisch nach.

## Setup

1. **Supabase**: Projekt anlegen → SQL Editor → in `schema.sql` `BITTE-AENDERN` durch dein App-Passwort ersetzen → ausführen. Project URL und `anon` Key aus Settings → API kopieren.
2. **index.html**: oben `SUPABASE_URL` und `SUPABASE_ANON_KEY` eintragen.
3. **GitHub Pages**: Repo, `index.html` + README rein, Pages aktivieren. HTTPS ist Pflicht für Kamerazugriff — Pages liefert das.
4. Auf dem Handy öffnen, „Zum Home-Bildschirm“, 🔒 → App-Passwort eingeben, Person anlegen, scannen.

Passwort ändern: `update app_secrets set value = 'neu' where key = 'write_password';`

Ohne Supabase-Keys läuft die App im Nur-lokal-Modus (localStorage) — zum Testen.

## Scanner

Nutzt `BarcodeDetector` (Chrome/Android, schnell) und fällt auf ZXing zurück (iOS Safari). Formate: EAN-13, EAN-8, UPC-A/E. Alternativ EAN eintippen.

## Bekannte Grenzen

- **Lesen ist offen.** Jeder mit anon-Key (steht im Repo) sieht Produkte, Namen und Bewertungen. Schreiben nur mit App-Passwort. Ein Passwort für alle, keine Personen-Auth — Geschmackswerte anderer sind änderbar. Nächste Stufe: Supabase Auth + Policies auf `auth.uid()`.
- **OFF-Abdeckung** bei Eigenmarken (Lidl, Aldi) ist lückenhaft; Nährwerte dann manuell.
- **CO₂** ist eine Kategorie-Schätzung. Für Vergleich Hähnchen vs. Linsen brauchbar, zwischen zwei Joghurts bedeutungslos.
- **Preis** ist pro Produkt, nicht pro Laden/Datum. Preishistorie wäre eine eigene Tabelle.
- OFF-Limit: 100 Produktabfragen/Minute. Kein Problem beim Scannen.
