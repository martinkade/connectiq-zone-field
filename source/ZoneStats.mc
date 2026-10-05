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
}
