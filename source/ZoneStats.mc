import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;

class ZoneStats {
    // Number of active training zones (5 for Heart Rate, 7 for Coggan Power)
    private var mNumZones as Number = 5;

    // Cumulative seconds for zones 0 through mNumZones (index 0 = unclassified / below Z1)
    private var mZoneSeconds as Array<Number> = [0, 0, 0, 0, 0, 0];
    
    // Interval tracking: seconds continuously spent in the current zone
    private var mActiveZoneIndex as Number = 0;
    private var mIntervalSeconds as Number = 0;

    private var mLastTimerTimeMs as Number? = null;

    function initialize() {
        setNumZones(5);
    }

    // Configures zone model based on metricType (0 = Heart Rate [5 zones], 1 = Power [7 zones])
    public function setMetricType(metricType as Number) as Void {
        setNumZones((metricType == 1) ? 7 : 5);
    }

    public function getMetricType() as Number {
        return (mNumZones == 7) ? 1 : 0;
    }

    public function getNumZones() as Number {
        return mNumZones;
    }

    // Configures zone model for 5 zones (HR) or 7 zones (Power)
    public function setNumZones(numZones as Number) as Void {
        if (numZones != 5 && numZones != 7) {
            numZones = (numZones <= 5) ? 5 : 7;
        }

        if (mNumZones == numZones && mZoneSeconds.size() == (numZones + 1)) {
            return;
        }

        mNumZones = numZones;
        var oldSeconds = mZoneSeconds;
        mZoneSeconds = createZeroArray(mNumZones + 1);
        for (var i = 0; i <= mNumZones; i++) {
            if (i < oldSeconds.size()) {
                mZoneSeconds[i] = oldSeconds[i];
            }
        }

        if (mActiveZoneIndex > mNumZones) {
            mActiveZoneIndex = mNumZones;
        }
    }

    public function reset() as Void {
        mZoneSeconds = createZeroArray(mNumZones + 1);
        mActiveZoneIndex = 0;
        mIntervalSeconds = 0;
        mLastTimerTimeMs = null;
    }

    private function createZeroArray(size as Number) as Array<Number> {
        if (size == 8) {
            return [0, 0, 0, 0, 0, 0, 0, 0];
        } else {
            return [0, 0, 0, 0, 0, 0];
        }
    }

    public function update(info as Activity.Info?, currentZoneIndex as Number) as Void {
        if (info == null) {
            return;
        }

        var timerState = info.timerState;
        var timerTime = info.timerTime; // Total elapsed activity timer time in milliseconds

        // Clamp zone index to [0, mNumZones]
        if (currentZoneIndex < 0) {
            currentZoneIndex = 0;
        } else if (currentZoneIndex > mNumZones) {
            currentZoneIndex = mNumZones;
        }

        // Detect zone transition
        if (currentZoneIndex != mActiveZoneIndex) {
            mActiveZoneIndex = currentZoneIndex;
            mIntervalSeconds = 0;
        }

        // Only accumulate when the activity timer is actively running
        var isTimerActive = (timerState != null && timerState == Activity.TIMER_STATE_ON);

        if (timerTime != null && isTimerActive) {
            if (mLastTimerTimeMs != null && timerTime >= mLastTimerTimeMs) {
                var deltaMs = timerTime - mLastTimerTimeMs;
                var deltaSec = (deltaMs / 1000).toNumber();

                // Cap deltaSec to 5s in case of long pauses or jumps
                if (deltaSec > 0 && deltaSec <= 5) {
                    if (currentZoneIndex >= 0 && currentZoneIndex < mZoneSeconds.size()) {
                        mZoneSeconds[currentZoneIndex] += deltaSec;
                    }
                    mIntervalSeconds += deltaSec;
                }
            }
            mLastTimerTimeMs = timerTime;
        } else {
            // Timer paused or stopped; preserve interval & cumulative time, update reference point
            mLastTimerTimeMs = timerTime;
        }
    }

    public function getCumulativeSeconds(zoneIndex as Number) as Number {
        if (zoneIndex >= 0 && zoneIndex < mZoneSeconds.size()) {
            return mZoneSeconds[zoneIndex];
        }
        return 0;
    }

    public function getIntervalSeconds() as Number {
        return mIntervalSeconds;
    }

    public function getActiveZoneIndex() as Number {
        return mActiveZoneIndex;
    }

    public function getTotalTrackedSeconds(includeZone0 as Boolean) as Number {
        var total = 0;
        var startIdx = includeZone0 ? 0 : 1;
        for (var i = startIdx; i <= mNumZones && i < mZoneSeconds.size(); i++) {
            total += mZoneSeconds[i];
        }
        return total;
    }

    public function getZonePercentage(zoneIndex as Number) as Float {
        var total = getTotalTrackedSeconds(false);
        if (total <= 0) {
            return 0.0f;
        }
        var sec = getCumulativeSeconds(zoneIndex);
        return (sec.toFloat() / total.toFloat()) * 100.0f;
    }

    public function getZoneSeconds() as Array<Number> {
        return mZoneSeconds;
    }

    public function formatDualDuration(zoneIndex as Number) as String {
        var cumSec = getCumulativeSeconds(zoneIndex);
        var intSec = mIntervalSeconds;
        return Lang.format("$1$ ($2$)", [formatDuration(cumSec), formatDuration(intSec)]);
    }

    public function formatDuration(seconds as Number) as String {
        if (seconds < 0) {
            seconds = 0;
        }
        var hours = seconds / 3600;
        var minutes = (seconds % 3600) / 60;
        var secs = seconds % 60;

        if (hours > 0) {
            return Lang.format("$1$:$2$:$3$", [
                hours.format("%d"),
                minutes.format("%02d"),
                secs.format("%02d")
            ]);
        } else {
            return Lang.format("$1$:$2$", [
                minutes.format("%02d"),
                secs.format("%02d")
            ]);
        }
    }

    // Computes pixel (or angular) widths for each active training zone (Zone 1..mNumZones).
    // - Proportional to time spent in each zone.
    // - Guarantees minimum width for the active zone so the elevated segment and indicator are visible.
    // - Falls back to equal distribution if no time is tracked yet (totalSec == 0).
    // - Ensures the sum of segment widths strictly equals availWidth.
    public function computeSegmentWidths(availWidth as Number, activeZone as Number, minActiveW as Number) as Array<Number> {
        var widths = new Array<Number>[mNumZones];
        if (availWidth <= 0) {
            for (var i = 0; i < mNumZones; i++) {
                widths[i] = 0;
            }
            return widths;
        }

        var totalSec = getTotalTrackedSeconds(false); // Excludes Zone 0

        // 1. Initial State: If total tracked time is 0, distribute equally
        if (totalSec <= 0) {
            var baseW = availWidth / mNumZones;
            var acc = 0;
            for (var i = 0; i < mNumZones; i++) {
                widths[i] = baseW;
                acc += baseW;
            }
            widths[mNumZones - 1] += (availWidth - acc);
            return widths;
        }

        // 2. Proportional Distribution with Active Zone Protection
        var isActValid = (activeZone >= 1 && activeZone <= mNumZones);
        var actSec = isActValid ? getCumulativeSeconds(activeZone) : 0;
        var actProportionalW = (totalSec > 0) ? ((actSec.toFloat() / totalSec.toFloat()) * availWidth).toNumber() : 0;

        // Cap minActiveW so it never exceeds half the total available width
        var maxCap = availWidth / 2;
        if (minActiveW > maxCap) {
            minActiveW = maxCap;
        }

        if (isActValid && actProportionalW < minActiveW) {
            // Guarantee minimum width for active zone
            var remWidth = availWidth - minActiveW;
            var remSec = totalSec - actSec;
            var acc = 0;

            for (var i = 0; i < mNumZones; i++) {
                var zNum = i + 1;
                if (zNum == activeZone) {
                    widths[i] = minActiveW;
                    acc += minActiveW;
                } else if (remSec > 0) {
                    var sec = getCumulativeSeconds(zNum);
                    var w = ((sec.toFloat() / remSec.toFloat()) * remWidth).toNumber();
                    widths[i] = w;
                    acc += w;
                } else {
                    var w = remWidth / (mNumZones - 1);
                    widths[i] = w;
                    acc += w;
                }
            }

            // Adjust integer remainder onto largest non-active segment
            var diff = availWidth - acc;
            if (diff != 0) {
                var maxIdx = (activeZone == 1) ? 1 : 0;
                for (var i = 0; i < mNumZones; i++) {
                    if ((i + 1) != activeZone && widths[i] > widths[maxIdx]) {
                        maxIdx = i;
                    }
                }
                widths[maxIdx] += diff;
            }
        } else {
            // Strictly proportional distribution
            var acc = 0;
            var maxIdx = 0;
            for (var i = 0; i < mNumZones; i++) {
                var zNum = i + 1;
                var sec = getCumulativeSeconds(zNum);
                var w = ((sec.toFloat() / totalSec.toFloat()) * availWidth).toNumber();
                widths[i] = w;
                acc += w;
                if (w > widths[maxIdx]) {
                    maxIdx = i;
                }
            }
            widths[maxIdx] += (availWidth - acc);
        }

        return widths;
    }
}
