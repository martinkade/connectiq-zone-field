# Garmin Connect IQ Store Listing — Zones (English)

## Suggested App Titles
* **Recommended Title:** `Zones — Heart Rate & Power Training Zones`
* **Short Title:** `Zones`
* **Alternative Title:** `Zones: HR & Power Data Field`

---

## Tagline / Short Description (Store Card)
> Glanceable training zones with bottom horizontal stacked bar chart (% time in zone), real-time within-zone indicator, and prominent value with inline zone badge.

---

## Full Description

Zones is a redesigned Garmin Connect IQ Data Field engineered for runners and cyclists who want instant, glanceable training zone feedback during workouts.

Whether you train by Heart Rate or Cycling Power, Zones displays your active intensity zone with a bottom-docked horizontal stacked bar chart showing time spent in each zone, a real-time within-zone position indicator, and a prominent hero value with inline color-coded zone badge.

### Key Features
* **Dual Metric Support:**
  * **Heart Rate (bpm):** Standard 5-Zone model utilizing sport-specific thresholds and Max HR directly from your Garmin Connect user profile.
  * **Power (Watts):** Dr. Andrew Coggan 7-Zone model calculated from your Functional Threshold Power (FTP).
* **Bottom Horizontal Stacked Bar Chart (Time in Zone):**
  * Segments reflect percentage of total session time spent in each zone (5 for Heart Rate, 7 for Power).
  * Flush to the bottom of the data field.
  * The active training zone segment is elevated slightly higher than inactive segments for instant glanceability.
  * Balanced baseline initialization and minimum visible width protection when entering new zones.
* **Real-Time Within-Zone Position Indicator:**
  * Directly above the elevated active segment, a downward-pointing caret indicator (`▼`) pinpoints exactly where your live measured value sits between the zone's lower and upper bounds.
* **Hero Measured Value & Inline Active Zone Badge:**
  * Large, bold digits for your live measured value without distracting unit clutter.
  * Large inline badge to the right displaying the active zone (e.g., `Z2`, `Z4`) with vibrant zone color fill and automatic contrast text.
* **Dynamic Form Factor Adaptation for Wearables:**
  * **Edge Bike Computers & Middle Bands:** Bottom-docked horizontal stacked bar with elevated active segment, indicator, and centered hero value + badge above.
  * **Watches Top Half Screen:** Stacked bar pinned as an arc along the top bezel curve with radially thicker active segment, indicator caret, and hero value + badge below.
  * **Watches Bottom Half Screen:** Stacked bar pinned along the bottom bezel curve with elevated active segment, indicator above, and hero value + badge above.
  * **Watches Full Screen (1-Field):** Pinned bottom bezel arc with indicator and centered hero value + inline badge.
* **Dark Mode & Light Mode Support:** Automatically follows your device's day/night profile or forces Dark Mode / Light Mode based on your personal preference.
* **Automatic Garmin Profile Sync:** Reads sport-specific Max HR and FTP directly from Garmin Connect user profiles, with manual overrides in App Settings.
* **Responsive Across All Displays:**
  * **Edge Bike Computers:** Optimized rectangular 1 to 10-field grids.
  * **Wearable Watches:** Dedicated polar circular and quadrant layouts using native bezel arcs without text clipping.

---

### Configurable App Settings
Customize your preferences via **Garmin Connect Mobile** or **Garmin Express**:
1. **Metric:** Heart Rate (default) or Power
2. **Theme Mode:** Auto (Follow Device), Dark Mode, or Light Mode
3. **Custom FTP:** Set your Functional Threshold Power (50 – 600 W)
4. **Color Theme:** Accent Badge Pill (battery-friendly) or Full Background Fill

---

### Training Zone Reference

#### Heart Rate Zones (5-Zone Model)
* **Z0 (Warm-Up):** $< 50\%$ Max HR — Light Gray
* **Z1 (Active Recovery):** $50\% - 59\%$ Max HR — Dark Gray
* **Z2 (Easy / Aerobic Base):** $60\% - 69\%$ Max HR — Blue
* **Z3 (Aerobic / Tempo):** $70\% - 79\%$ Max HR — Dark Green (High Contrast)
* **Z4 (Threshold):** $80\% - 89\%$ Max HR — Orange
* **Z5 (Maximum / VO2 Max):** $\ge 90\%$ Max HR — Red

#### Power Zones (Coggan 7-Zone Model)
* **Z1 (Active Recovery):** $< 55\%$ FTP — Light Gray
* **Z2 (Endurance):** $55\% - 75\%$ FTP — Blue
* **Z3 (Tempo):** $76\% - 90\%$ FTP — Dark Green (High Contrast)
* **Z4 (Lactate Threshold):** $91\% - 105\%$ FTP — Yellow
* **Z5 (VO2 Max):** $106\% - 120\%$ FTP — Orange
* **Z6 (Anaerobic Capacity):** $121\% - 150\%$ FTP — Red
* **Z7 (Neuromuscular Power):** $> 150\%$ FTP — Purple

---

### How to Add to Your Data Screen
1. On your Garmin watch or Edge computer, open your activity profile settings (e.g., Run or Bike).
2. Go to **Data Screens** and select the screen you wish to customize.
3. Select an individual data field and choose **Connect IQ** $\rightarrow$ **Zones**.

---

### Store Upload Assets Checklist
* **App Icon (500x500):** `assets/cover.png`
* **Hero Banner (1440x720):** `assets/hero.png`
* **Device Screenshot 1 (Edge):** `assets/screenshots/screenshot_edge1040_power.jpg` (Edge 1040: Cycling Power 285W, Z4 Badge, elevated yellow segment & caret indicator, <150 KB JPEG)
* **Device Screenshot 2 (Forerunner):** `assets/screenshots/screenshot_forerunner970_hr.jpg` (Forerunner 970: Running HR 156 bpm, Z3 Badge, bottom bezel arc stacked bar & indicator, <150 KB JPEG)
* **Device Screenshot 3 (Fenix):** `assets/screenshots/screenshot_fenix8_fullbg.jpg` (Fenix 8: Top-half split with pinned top arc stacked bar, Z5 Max & hero value below, <150 KB JPEG)
