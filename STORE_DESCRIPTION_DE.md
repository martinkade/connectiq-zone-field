# Garmin Connect IQ Store Eintrag — Zones (Deutsch)

## Vorgeschlagene App-Titel
* **Empfohlener Titel:** `Zones — HF- & Power-Trainingszonen`
* **Kurzer Titel:** `Zones`
* **Alternativer Titel:** `Zones: Trainingszonen für Laufen & Radsport`

---

## Kurzbeschreibung / Untertitel (Store-Kachel)
> Farbcodierte Trainingszonen für Herzfrequenz und Leistung mit kontinuierlichen Dezimalzonen, Einheiten-Durchschnitt und dualer Zonenzeit-Erfassung.

---

## Ausführliche Beschreibung

Zones ist ein All-in-One Garmin Connect IQ Datenfeld für Läufer und Radsportler, die während des Trainings sofortige und intuitive Orientierung über ihre aktuellen Belastungszonen benötigen.

Egal ob nach Herzfrequenz oder Watt-Leistung trainiert wird: Zones visualisiert deine Trainingszone farbcodiert, als kontinuierlichen Dezimalwert, mit deinem aktuellen Einheiten-Durchschnitt und einer innovativen dualen Zonenzeit-Erfassung.

### Hauptmerkmale
* **2 Messwerte unterstützt:**
  * **Herzfrequenz (bpm):** 5-Zonen-Modell basierend auf sportartspezifischen Schwellenwerten und Maximalpuls direkt aus deinem Garmin Connect Profil.
  * **Radsport-Leistung (Watt):** Dr. Andrew Coggan 7-Zonen-Modell berechnet aus deiner Functional Threshold Power (FTP).
* **Intuitive Farbcodierung:** Schnelle Orientierung auf einen Blick durch standardisierte Farben (Grau, Blau, Grün, Gelb, Orange, Rot, Lila).
* **Kontinuierliche Dezimalzonen:** Präzise Anzeige des Fortschritts innerhalb der Zone (z. B. `3.4`) oder klassische diskrete Anzeige (`Z3`).
* **Duale Zonenzeit-Erfassung:**
  * Zeigt sowohl die **kumulierte Gesamtzeit** in der aktuellen Zone als auch die kontinuierliche **Intervall-Dauer** in Klammern:
    $$\mathbf{14:22\ (1:45)} \quad \text{— [Gesamtzeit in Zone] ([Intervall-Dauer])}$$
  * Die Intervallzeit setzt sich bei jedem Zonenwechsel automatisch auf `0:00` zurück, während die Gesamtzeit der Zone sessionweit weitergezählt wird.
* **Einheiten-Durchschnitt:** Ständige Kontrolle über die durchschnittliche Herzfrequenz bzw. Durchschnittsleistung.
* **Automatische Profil-Synchronisation:** Liest Maximalpulswerte und FTP-Schwellenwerte direkt aus Garmin Connect aus (manuelle Überschreibung in den Einstellungen jederzeit möglich).
* **Optimiert für alle Displays:**
  * **Edge Fahrradcomputer:** Perfekt lesbar auf rechteckigen 1- bis 10-Felder-Seiten.
  * **Garmin Sportuhren:** Automatische Berücksichtigung runder Displayränder (Fenix, Forerunner, Epix, Enduro, Venu) für optimale Lesbarkeit ohne Randabschnitt.

---

### Einstellungen (Garmin Connect Mobile / Express)
Passe das Datenfeld jederzeit über dein Smartphone an:
1. **Messwert:** Herzfrequenz (Standard) oder Leistung (Power)
2. **Eigene FTP:** Individuelle Schwellenleistung in Watt (50 – 600 W)
3. **Zonen-Format:** Kontinuierlich (3.4) oder Diskret (Z3)
4. **Farbdesign:** Akzent-Badge (akkuschonend) oder Vollflächig gefärbt

---

### Trainingszonen-Übersicht

#### Herzfrequenz-Zonen (5-Zonen-Modell)
* **Z0 (Aufwärmen):** $< 50\%$ HFmax — Hellgrau
* **Z1 (Aktive Erholung):** $50\% - 59\%$ HFmax — Dunkelgrau
* **Z2 (Grundlagenausdauer 1):** $60\% - 69\%$ HFmax — Blau
* **Z3 (Grundlagenausdauer 2 / Tempo):** $70\% - 79\%$ HFmax — Grün
* **Z4 (Schwellenbereich):** $80\% - 89\%$ HFmax — Orange
* **Z5 (Maximale Belastung / VO2max):** $\ge 90\%$ HFmax — Rot

#### Leistungszonen (Coggan 7-Zonen-Modell)
* **Z1 (Aktive Erholung):** $< 55\%$ FTP — Hellgrau
* **Z2 (Ausdauer):** $55\% - 75\%$ FTP — Blau
* **Z3 (Tempo):** $76\% - 90\%$ FTP — Grün
* **Z4 (Laktatschwelle):** $91\% - 105\%$ FTP — Gelb
* **Z5 (VO2max):** $106\% - 120\%$ FTP — Orange
* **Z6 (Anaerobe Kapazität):** $121\% - 150\%$ FTP — Rot
* **Z7 (Neuromuskuläre Leistung):** $> 150\%$ FTP — Lila

---

### Einrichtung auf deinem Garmin-Gerät
1. Halte auf der Uhr oder dem Edge-Computer die Taste für das Aktivitätsprofil gedrückt (z. B. Laufen oder Radfahren).
2. Gehe zu **Trainingsseiten** / **Datenfelder** und wähle die gewünschte Seite aus.
3. Wähle ein Datenfeld aus und navigiere zu **Connect IQ** $\rightarrow$ **Zones**.

---

### Checkliste für den Store-Upload
* **App-Icon (500x500):** `assets/cover.png`
* **Hero-Banner (1440x720):** `assets/hero.png`
* **Geräte-Screenshot 1 (Edge):** `assets/screenshots/screenshot_edge1040_power.jpg` (Radsport-Leistung, Z4 Schwelle, <150 KB JPEG)
* **Geräte-Screenshot 2 (Forerunner):** `assets/screenshots/screenshot_forerunner970_hr.jpg` (Lauf-HF, Z3 Grundlagenbereich, <150 KB JPEG)
* **Geräte-Screenshot 3 (Fenix):** `assets/screenshots/screenshot_fenix8_fullbg.jpg` (Vollfarb-Theme, Z5 Maximalbereich, <150 KB JPEG)
