import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.UserProfile;
import Toybox.Lang;
import Toybox.System;

class ZoneResult {
    public var zoneIndex as Number = 0;
    public var decimalZone as Float = 0.0f;
    public var color as Number = Graphics.COLOR_LT_GRAY;
    public var label as String = "Z0";

    function initialize() {}
}

class ZoneCalculator {
    private var mFtp as Number = 250;
    private var mHrZones as Array<Number>? = null;
    private var mMaxHr as Number = 190;
    private var mPowerZones as Array<Number>? = null;

    function initialize(ftp as Number) {
        mFtp = ftp;
        refreshHrZones();
        refreshPowerZones();
    }

    function setFtp(ftp as Number) as Void {
        mFtp = ftp;
        refreshPowerZones();
    }

    public function getMaxHeartRate() as Number {
        return mMaxHr;
    }

    public function getFtp() as Number {
        return mFtp;
    }

    (:typecheck(false))
    public function refreshHrZones() as Void {
        try {
            var sport = UserProfile.HR_ZONE_SPORT_GENERIC;
            if (UserProfile has :getCurrentSport) {
                var currentSport = UserProfile.getCurrentSport();
                if (currentSport != null) {
                    sport = currentSport;
                }
            }

            var zones = UserProfile.getHeartRateZones(sport);
            if (zones != null && zones.size() >= 5) {
                mHrZones = zones;
                mMaxHr = zones[zones.size() - 1];
            } else {
                fallbackHrZones();
            }
        } catch (ex) {
            fallbackHrZones();
        }
    }

    private function fallbackHrZones() as Void {
        // Fallback using standard age-based max HR formula: 220 - age
        var maxHr = 190;
        try {
            var profile = UserProfile.getProfile();
            if (profile != null && profile.birthYear != null) {
                // Estimate age (default roughly 30 if unavailable)
                var currentYear = 2026;
                var age = currentYear - profile.birthYear;
                if (age > 10 && age < 100) {
                    maxHr = 220 - age;
                }
            }
        } catch (e) {}

        mMaxHr = maxHr;
        // Standard 5-zone HR bounds (50%, 60%, 70%, 80%, 90%, 100%)
        mHrZones = [
            (maxHr * 0.50).toNumber(),
            (maxHr * 0.60).toNumber(),
            (maxHr * 0.70).toNumber(),
            (maxHr * 0.80).toNumber(),
            (maxHr * 0.90).toNumber(),
            maxHr
        ];
    }

    (:typecheck(false))
    private function getActivitySport() as Activity.Sport {
        try {
            if (UserProfile has :getCurrentSport2) {
                var cur = UserProfile.getCurrentSport2();
                if (cur != null && cur.size() > 0 && cur[0] != null) {
                    return cur[0] as Activity.Sport;
                }
            }
        } catch (e) {}
        return Activity.SPORT_CYCLING;
    }

    (:typecheck(false))
    public function refreshPowerZones() as Void {
        var zonesFound = false;
        var actSport = getActivitySport();

        // Try reading power zones directly from UserProfile if supported (newer CIQ SDKs)
        try {
            if (UserProfile has :getPowerZones) {
                var pz = UserProfile.getPowerZones(actSport);
                if (pz != null && pz.size() >= 5) {
                    mPowerZones = pz;
                    zonesFound = true;
                }
            }
        } catch (ex) {}

        // Try reading sport-specific FTP if supported
        try {
            if (!zonesFound && UserProfile has :getFunctionalThresholdPower) {
                var sportFtp = UserProfile.getFunctionalThresholdPower(actSport);
                if (sportFtp != null && sportFtp > 0) {
                    mFtp = sportFtp;
                }
            }
        } catch (ex2) {}

        // Build standard 7-Zone Coggan power zones using FTP if direct zones are not available
        if (!zonesFound) {
            var ftp = (mFtp > 0) ? mFtp : 250;
            mPowerZones = [
                0,                                  // Z1 start: 0%
                (ftp * 0.55).toNumber(),            // Z1 end / Z2 start: 55%
                (ftp * 0.75).toNumber(),            // Z2 end / Z3 start: 75%
                (ftp * 0.90).toNumber(),            // Z3 end / Z4 start: 90%
                (ftp * 1.05).toNumber(),            // Z4 end / Z5 start: 105%
                (ftp * 1.20).toNumber(),            // Z5 end / Z6 start: 120%
                (ftp * 1.50).toNumber(),            // Z6 end / Z7 start: 150%
                (ftp * 2.50).toNumber()             // Z7 upper ceiling (e.g. 250%)
            ];
        }
    }

    public function calculateHrZone(hr as Number?) as ZoneResult {
        var res = new ZoneResult();
        if (hr == null || hr <= 0 || mHrZones == null) {
            res.label = "--";
            res.zoneIndex = 0;
            res.decimalZone = 0.0f;
            res.color = Graphics.COLOR_LT_GRAY;
            return res;
        }

        var zones = mHrZones as Array<Number>;
        var count = zones.size(); // typically 6 thresholds (minZ1, minZ2, minZ3, minZ4, minZ5, maxZ5)
        var minZ1 = zones[0];
        var maxHr = zones[count - 1];

        if (hr < minZ1) {
            // Below Zone 1 (Warmup / Zone 0)
            res.zoneIndex = 0;
            res.decimalZone = (minZ1 > 0) ? (hr.toFloat() / minZ1.toFloat()) : 0.0f;
            res.color = Graphics.COLOR_LT_GRAY;
            res.label = "Z0";
            return res;
        }

        if (hr >= maxHr) {
            // Max or above Zone 5
            res.zoneIndex = 5;
            res.decimalZone = 5.99f;
            res.color = Graphics.COLOR_RED;
            res.label = "Z5";
            return res;
        }

        // Zones 1 through 5
        // zones[0] = bottom of Z1
        // zones[1] = bottom of Z2 (top of Z1)
        // zones[2] = bottom of Z3 (top of Z2)
        // zones[3] = bottom of Z4 (top of Z3)
        // zones[4] = bottom of Z5 (top of Z4)
        // zones[5] = top of Z5 (Max HR)
        for (var i = 1; i < count; i++) {
            var low = zones[i - 1];
            var high = zones[i];
            if (hr < high) {
                var zIndex = i; // 1 to 5
                var span = high - low;
                var frac = (span > 0) ? ((hr - low).toFloat() / span.toFloat()) : 0.0f;
                res.zoneIndex = zIndex;
                res.decimalZone = zIndex.toFloat() + frac;
                res.label = "Z" + zIndex;
                res.color = getHrZoneColor(zIndex);
                return res;
            }
        }

        res.zoneIndex = 5;
        res.decimalZone = 5.0f;
        res.label = "Z5";
        res.color = Graphics.COLOR_RED;
        return res;
    }

    public function calculatePowerZone(pwr as Number?) as ZoneResult {
        var res = new ZoneResult();
        if (pwr == null || pwr < 0 || mPowerZones == null) {
            res.label = "--";
            res.zoneIndex = 0;
            res.decimalZone = 0.0f;
            res.color = Graphics.COLOR_LT_GRAY;
            return res;
        }

        var zones = mPowerZones as Array<Number>;
        var count = zones.size();

        // 7-Zone Coggan:
        // index 0: 0 W
        // index 1: 55% FTP
        // index 2: 75% FTP
        // index 3: 90% FTP
        // index 4: 105% FTP
        // index 5: 120% FTP
        // index 6: 150% FTP
        // index 7: 250% FTP
        if (pwr < zones[1]) {
            // Zone 1
            var span = zones[1] - zones[0];
            var frac = (span > 0) ? (pwr.toFloat() / span.toFloat()) : 0.0f;
            res.zoneIndex = 1;
            res.decimalZone = 1.0f + frac;
            res.label = "Z1";
            res.color = Graphics.COLOR_LT_GRAY;
            return res;
        }

        for (var i = 2; i < count; i++) {
            var low = zones[i - 1];
            var high = zones[i];
            if (pwr < high) {
                var zIndex = i; // 2, 3, 4, 5, 6
                var span = high - low;
                var frac = (span > 0) ? ((pwr - low).toFloat() / span.toFloat()) : 0.0f;
                res.zoneIndex = zIndex;
                res.decimalZone = zIndex.toFloat() + frac;
                res.label = "Z" + zIndex;
                res.color = getPowerZoneColor(zIndex);
                return res;
            }
        }

        // Zone 7+
        res.zoneIndex = 7;
        res.decimalZone = 7.5f;
        res.label = "Z7";
        res.color = Graphics.COLOR_PURPLE;
        return res;
    }

    private function getHrZoneColor(zone as Number) as Number {
        switch (zone) {
            case 1:
                return Graphics.COLOR_DK_GRAY;
            case 2:
                return Graphics.COLOR_BLUE;
            case 3:
                return Graphics.COLOR_GREEN;
            case 4:
                return Graphics.COLOR_ORANGE;
            case 5:
                return Graphics.COLOR_RED;
            default:
                return Graphics.COLOR_LT_GRAY;
        }
    }

    private function getPowerZoneColor(zone as Number) as Number {
        switch (zone) {
            case 1:
                return Graphics.COLOR_LT_GRAY;
            case 2:
                return Graphics.COLOR_BLUE;
            case 3:
                return Graphics.COLOR_GREEN;
            case 4:
                return Graphics.COLOR_YELLOW;
            case 5:
                return Graphics.COLOR_ORANGE;
            case 6:
                return Graphics.COLOR_RED;
            case 7:
                return Graphics.COLOR_PURPLE;
            default:
                return Graphics.COLOR_LT_GRAY;
        }
    }
}
