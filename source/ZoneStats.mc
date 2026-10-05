import Toybox.Activity;
import Toybox.Lang;
import Toybox.System;

class ZoneStats {
    // Cumulative seconds for zones 0 through 7
    private var mZoneSeconds as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0];
    
    // Interval tracking: seconds continuously spent in the current zone
    private var mActiveZoneIndex as Number = 0;
    private var mIntervalSeconds as Number = 0;

    private var mLastTimerTimeMs as Number? = null;

    function initialize() {
        reset();
    }

    public function reset() as Void {
        mZoneSeconds = [0, 0, 0, 0, 0, 0, 0, 0];
        mActiveZoneIndex = 0;
        mIntervalSeconds = 0;
        mLastTimerTimeMs = null;
    }

    public function update(info as Activity.Info?, currentZoneIndex as Number) as Void {
        if (info == null) {
            return;
        }

        var timerState = info.timerState;
        var timerTime = info.timerTime; // Total elapsed activity timer time in milliseconds

        // Detect zone transition
        if (currentZoneIndex != mActiveZoneIndex) {
            mActiveZoneIndex = currentZoneIndex;
            mIntervalSeconds = 0;
        }

        // Only accumulate when the activity timer is actively running
        var isTimerActive = (timerState == Activity.TIMER_STATE_ON);

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
