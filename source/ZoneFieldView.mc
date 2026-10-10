import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ZoneFieldView extends WatchUi.DataField {
    public var mCalculator as ZoneCalculator;
    public var mStats as ZoneStats;
    public var mRectRenderer as RectangularLayoutRenderer;
    public var mCircularRenderer as CircularLayoutRenderer;

    // Configurable Settings
    public var mMetricType as Number = 0;       // 0 = Heart Rate, 1 = Power
    public var mThemeMode as Number = 0;        // 0 = Auto (Device), 1 = Dark Mode, 2 = Light Mode
    public var mFtp as Number = 250;
    public var mFullBackgroundColor as Boolean = false;

    // Computed Runtime State
    public var mCurrentValue as Number? = null;
    public var mAvgValue as Number? = null;
    public var mMaxValue as Number? = null;
    public var mActivityTimerMs as Number? = null;
    public var mZoneResult as ZoneResult;

    function initialize() {
        DataField.initialize();
        loadSettings();
        mCalculator = new ZoneCalculator(mFtp);
        mStats = new ZoneStats();
        mStats.setMetricType(mMetricType);
        mZoneResult = new ZoneResult();
        mRectRenderer = new RectangularLayoutRenderer();
        mCircularRenderer = new CircularLayoutRenderer();
    }

    public function loadSettings() as Void {
        try {
            var mType = getSettingValue("metricType");
            if (mType != null) {
                if (mType instanceof Number) {
                    mMetricType = mType as Number;
                } else if (mType instanceof String) {
                    mMetricType = (mType as String).toNumber();
                }
            }
            var themeVal = getSettingValue("themeMode");
            if (themeVal != null) {
                if (themeVal instanceof Number) {
                    mThemeMode = themeVal as Number;
                } else if (themeVal instanceof String) {
                    mThemeMode = (themeVal as String).toNumber();
                }
            }
            var ftpVal = getSettingValue("userFtp");
            if (ftpVal != null) {
                if (ftpVal instanceof Number) {
                    mFtp = ftpVal as Number;
                } else if (ftpVal instanceof String) {
                    mFtp = (ftpVal as String).toNumber();
                }
            }
            var bgVal = getSettingValue("fullBackgroundColor");
            if (bgVal != null) {
                if (bgVal instanceof Number) {
                    mFullBackgroundColor = ((bgVal as Number) == 1);
                } else if (bgVal instanceof Boolean) {
                    mFullBackgroundColor = bgVal as Boolean;
                }
            }

            if (mCalculator != null) {
                mCalculator.setFtp(mFtp);
                mCalculator.refreshHrZones();
            }
            if (mStats != null) {
                mStats.setMetricType(mMetricType);
            }
        } catch (e) {}
    }

    (:typecheck(false))
    private function getSettingValue(key as String) as Object? {
        try {
            if (Application has :Properties) {
                return Application.Properties.getValue(key);
            } else {
                return Application.getApp().getProperty(key);
            }
        } catch (e) {
            return null;
        }
    }

    // Resolves whether Dark Mode is currently active
    public function isDarkTheme() as Boolean {
        if (mThemeMode == 1) {
            return true;
        } else if (mThemeMode == 2) {
            return false;
        } else {
            return (getBackgroundColor() == Graphics.COLOR_BLACK);
        }
    }

    // Returns the base canvas background color based on themeMode
    public function getBaseBackgroundColor() as Number {
        if (mThemeMode == 1) {
            return Graphics.COLOR_BLACK;
        } else if (mThemeMode == 2) {
            return Graphics.COLOR_WHITE;
        } else {
            return getBackgroundColor();
        }
    }

    // Called once per second by Garmin OS
    function compute(info as Activity.Info) as Void {
        if (mMetricType == 0) {
            // Heart Rate Mode
            mCurrentValue = info.currentHeartRate;
            mAvgValue = info.averageHeartRate;
            if (info has :maxHeartRate && info.maxHeartRate != null && info.maxHeartRate > 0) {
                mMaxValue = info.maxHeartRate;
            } else if (mCurrentValue != null && mCurrentValue > 0) {
                if (mMaxValue == null || mCurrentValue > mMaxValue) {
                    mMaxValue = mCurrentValue;
                }
            }
            mZoneResult = mCalculator.calculateHrZone(mCurrentValue);
        } else {
            // Power Mode (7-Zone Coggan model)
            mCurrentValue = info.currentPower;
            mAvgValue = info.averagePower;
            if (info has :maxPower && info.maxPower != null && info.maxPower > 0) {
                mMaxValue = info.maxPower;
            } else if (mCurrentValue != null && mCurrentValue > 0) {
                if (mMaxValue == null || mCurrentValue > mMaxValue) {
                    mMaxValue = mCurrentValue;
                }
            }
            mZoneResult = mCalculator.calculatePowerZone(mCurrentValue);
        }

        // Accumulate active time in current zone (both cumulative and interval)
        mStats.update(info, mZoneResult.zoneIndex);

        if (info.timerTime != null) {
            mActivityTimerMs = info.timerTime;
        } else if (info.elapsedTime != null) {
            mActivityTimerMs = info.elapsedTime;
        }
    }

    // Main drawing method
    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var obscurity = getObscurityFlags();

        // 1. Clear background
        var baseBg = getBaseBackgroundColor();
        var zoneColor = mZoneResult.color;

        var bgColor = baseBg;
        if (mFullBackgroundColor && mZoneResult.zoneIndex > 0) {
            bgColor = zoneColor;
        }
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // 2. Route between Circular Watch Layouts and Rectangular Bike Computer Layouts
        if (isCircularDevice()) {
            mCircularRenderer.render(dc, self, width, height, obscurity);
        } else {
            mRectRenderer.render(dc, self, width, height, obscurity);
        }
    }

    // Detects whether the current device has a circular/round display (e.g. Fenix, Forerunner, Epix)
    public function isCircularDevice() as Boolean {
        try {
            var settings = System.getDeviceSettings();
            if (settings has :screenShape) {
                var shape = settings.screenShape;
                if (shape == System.SCREEN_SHAPE_ROUND || shape == System.SCREEN_SHAPE_SEMI_ROUND) {
                    return true;
                }
            }
        } catch (e) {}
        return false;
    }

    // Helper to get high-contrast foreground and subtitle colors
    public function getTextColor(zoneColor as Number, isDarkTheme as Boolean) as [Number, Number] {
        if (mFullBackgroundColor && mZoneResult.zoneIndex > 0) {
            if (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) {
                return [Graphics.COLOR_BLACK, Graphics.COLOR_DK_GRAY];
            } else {
                return [Graphics.COLOR_WHITE, Graphics.COLOR_WHITE];
            }
        } else {
            var fg = isDarkTheme ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            var sub = isDarkTheme ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
            return [fg, sub];
        }
    }
}
