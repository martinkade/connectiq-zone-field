# Zones — Garmin Connect IQ Data Field

A high-performance Garmin Connect IQ Data Field that provides instant, glanceable training zone feedback with color-coded badges, continuous or discrete zone values, dual active-zone timers, and session averages for both **Heart Rate** and **Power**.

Designed to adapt seamlessly across **Garmin Edge bike computers** (rectangular grids) and **Garmin wearable watches** (round AMOLED/MIP screens with curved bezel awareness).

---

## Features

* **Supported Metrics:**
  * **Heart Rate (Default):** Standard 5-Zone model utilizing sport-specific thresholds and Max HR directly from your Garmin Connect user profile.
  * **Power (Cycling):** Dr. Andrew Coggan 7-Zone model calculated from your Functional Threshold Power (FTP).
* **Color-Coded Zone Indicator:**
  * **Continuous Zone Format:** Displays fractional progress through the zone (e.g., `3.4`).
  * **Discrete Zone Format:** Displays classic integer badges (e.g., `Z3`).
  * **Flexible Color Themes:** Choose between clean **Accent Badge** pills with bottom status bar, or bold **Full Background Fill** for high visibility.
* **Dual In-Zone Timer:**
  * Displays both **cumulative time** spent in the current active zone across the entire workout and continuous **interval time** spent in the zone since last transition:
    $$\mathbf{14:22\ (1:45)} \quad \text{— [Cumulative Session Time] ([Interval Time])}$$
  * Automatically freezes when the workout timer is paused and resets the interval timer upon transitioning to another zone.
* **Session Average:**
  * Always displays current session average (`AVG 148` bpm or `AVG 245` W).
* **Cross-Device Responsive Design:**
  * **Edge Bike Computers:** Maximizes wide rectangular screen real estate across 1, 2, 4, 8, and 10-field layouts.
  * **Wearable Watches:** Automatically reads `getObscurityFlags()` to adapt padding and fonts to curved watch bezels (Fenix, Forerunner, Epix, Enduro, Venu).
* **Full Localization:**
  * English (`en` / `eng`)
  * German (`de` / `deu`)

---

## Device Screenshots

| Garmin Edge 1040 (Cycling Power) | Garmin Forerunner 970 (Running HR) | Garmin Fenix 8 (Full BG Theme) |
| :---: | :---: | :---: |
| ![Edge 1040](assets/screenshots/screenshot_edge1040_power.jpg) | ![Forerunner 970](assets/screenshots/screenshot_forerunner970_hr.jpg) | ![Fenix 8](assets/screenshots/screenshot_fenix8_fullbg.jpg) |
| *Widescreen Edge layout with Coggan Z4 Power* | *Round AMOLED layout with Z3 Aerobic HR* | *High-visibility full background fill mode* |

---

## Training Zone Models

### Heart Rate Zones (5-Zone Model)
*Sourced dynamically from Garmin Connect profile via `Toybox.UserProfile.getHeartRateZones()`:*

| Zone | Name | Typical % Max HR | Color |
| :---: | :--- | :---: | :--- |
| **Z0** | Warm-Up / Below Zone 1 | $< 50\%$ | Light Gray |
| **Z1** | Warm Up / Active Recovery | $50\% - 59\%$ | Dark Gray |
| **Z2** | Easy / Aerobic Base | $60\% - 69\%$ | Blue |
| **Z3** | Aerobic / Tempo | $70\% - 79\%$ | Green |
| **Z4** | Threshold | $80\% - 89\%$ | Orange |
| **Z5** | Maximum / VO2 Max | $\ge 90\%$ | Red |

### Power Zones (Coggan 7-Zone Model)
*Calculated from user FTP (auto-detected via UserProfile or custom app setting):*

| Zone | Description | % of FTP | Color |
| :---: | :--- | :---: | :--- |
| **Z1** | Active Recovery | $< 55\%$ | Light Gray |
| **Z2** | Endurance | $55\% - 75\%$ | Blue |
| **Z3** | Tempo | $76\% - 90\%$ | Green |
| **Z4** | Lactate Threshold | $91\% - 105\%$ | Yellow |
| **Z5** | VO2 Max | $106\% - 120\%$ | Orange |
| **Z6** | Anaerobic Capacity | $121\% - 150\%$ | Red |
| **Z7** | Neuromuscular Power | $> 150\%$ | Purple |

---

## App Settings (Garmin Connect Mobile / Express)

All settings can be adjusted in the Garmin Connect Mobile app or Garmin Express without restarting your activity:

| Setting Key | Options / Range | Default | Description |
| :--- | :--- | :---: | :--- |
| **Metric** | `Heart Rate` (0) / `Power` (1) | Heart Rate | Primary metric tracked |
| **FTP (Watts)** | `50` – `600` Watts | 250 W | Functional Threshold Power |
| **Zone Format** | `Continuous (e.g. 3.4)` / `Discrete (e.g. Z3)` | Continuous | Numeric format for zone value |
| **Color Style** | `Accent Badge` / `Full Background Fill` | Accent Badge | Full screen coloring vs. accent pill |

---

## Project Structure

```text
ZoneField/
├── .vscode/
│   ├── launch.json              # 1-click debugging configurations (Edge, Forerunner, Fenix)
│   └── settings.json            # Connect IQ developer key configuration
├── assets/                      # Store graphics & device screenshots
│   ├── cover.png                # 500x500 Connect IQ Store App Icon
│   ├── hero.png                 # 1440x720 Connect IQ Store Hero Banner
│   └── screenshots/             # High-resolution device screenshots (<150KB JPEG)
│       ├── screenshot_edge1040_power.jpg
│       ├── screenshot_forerunner970_hr.jpg
│       └── screenshot_fenix8_fullbg.jpg
├── bin/                         # Compiled binaries (.prg) and store bundles (.iq)
├── resources/                   # Base resources & default strings (English)
│   ├── drawables/               # 40x40 base launcher icon
│   ├── settings/                # properties.xml and settings.xml
│   └── strings/                 # strings.xml
├── resources-eng/               # Explicit English string translations
│   └── strings/strings.xml
├── resources-deu/               # German string translations (Deutsch)
│   └── strings/strings.xml
├── resources-edge1040/          # Native 40x40 launcher icon for Edge 1040
├── resources-edge1050/          # Native 68x68 launcher icon for Edge 1050
├── resources-edge830/           # Native 35x35 launcher icon for Edge 830/840/530/540
├── resources-fenix843mm/        # Native 60x60 launcher icon for Fenix 8
├── resources-fr970/             # Native 65x65 launcher icon for Forerunner 970 / 965
├── source/
│   ├── ZoneCalculator.mc        # HR & 7-zone power math, sport detection, colors
│   ├── ZoneStats.mc             # Cumulative and interval duration tracking
│   ├── ZoneFieldView.mc         # Adaptive multi-layout rendering engine
│   └── ZoneFieldApp.mc          # Application lifecycle & live settings handler
├── build_release.sh             # Production deployment script (generates .iq bundle)
├── build_sim.sh                 # Simulator build helper script
├── developer_key.der            # PKCS#8 DER private developer key
├── manifest.xml                 # Connect IQ app permissions and supported devices
├── monkey.jungle                # Connect IQ build jungle definition
└── README.md
```

---

## Prerequisites

1. **Java Runtime:** OpenJDK 17 or 21 (required by Garmin `monkeyc`):
   ```bash
   brew install openjdk@21
   sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
   ```
2. **Garmin Connect IQ SDK:**
   * Install via Homebrew: `brew install --cask connectiq-sdk-manager`
   * Open the SDK Manager and download the latest SDK (System 7 / SDK 7.x/9.x) and your desired device definitions (Edge 1040, Forerunner 970, etc.).
3. **VS Code / Cursor (Optional):**
   * Install the official **Monkey C** extension from Garmin.

---

## Development & Testing

### Option 1: VS Code / Cursor
Open the project folder, open the **Run & Debug** pane (`Cmd+Shift+D`), select your device (e.g. `Run ZoneField (Edge 1040)` or `Run ZoneField (Forerunner 970)`), and press **`F5`**.

### Option 2: Terminal Helper Script
Build and run directly from the command line:

```bash
# Build for Edge 1040:
./build_sim.sh edge1040

# Build and launch in simulator:
./build_sim.sh edge1040 run

# Build for Forerunner 970:
./build_sim.sh fr970 run
```

### Feeding Sensor Data in the Simulator
1. **Start Activity Timer:** Press the device's physical `START / STOP` button or press **`F7`** in the simulator to activate time accumulation.
2. **Simulate Sensors:** Open **Simulation $\rightarrow$ Activity Data...** and drag the **Heart Rate** or **Power** sliders to watch zone colors, decimal badges, and interval counters react in real time.
3. **Test App Settings:** Open **File $\rightarrow$ Edit Persistent Storage $\rightarrow$ Edit Application Properties Data** to toggle between Heart Rate and Power mode or change FTP.

---

## Building for the Connect IQ Store

To create a signed, upload-ready application bundle (`.iq` file) containing optimized release binaries for all configured devices:

```bash
./build_release.sh
```

This compiles with release optimizations (`-r`) and packages the bundle into `bin/ZoneField.iq`:

```text
======================================================
  ✓ SUCCESS: Application bundle created successfully! 
======================================================
File: bin/ZoneField.iq (84K)

Packaged Target Devices:
  • edge1040
  • edge1050
  • edge830
  • fenix843mm
  • fr970
```

Upload `bin/ZoneField.iq` directly to the [Garmin Connect IQ Developer Dashboard](https://apps.garmin.com/developer/dashboard).

---

## License

MIT License. Designed and developed for Garmin Connect IQ devices.
