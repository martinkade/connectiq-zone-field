import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ZoneFieldView extends WatchUi.DataField {
    private var mCalculator as ZoneCalculator;
    private var mStats as ZoneStats;

    // Configurable Settings
    public var mMetricType as Number = 0;       // 0 = Heart Rate, 1 = Power
    public var mFtp as Number = 250;
    public var mDecimalZone as Boolean = true;  // Continuous 3.4 vs Discrete Z3
    public var mFullBackgroundColor as Boolean = false;

    // Computed Runtime State
    private var mCurrentValue as Number? = null;
    private var mAvgValue as Number? = null;
    private var mZoneResult as ZoneResult;

    function initialize() {
        DataField.initialize();
        loadSettings();
        mCalculator = new ZoneCalculator(mFtp);
        mStats = new ZoneStats();
        mZoneResult = new ZoneResult();
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
            var ftpVal = getSettingValue("userFtp");
            if (ftpVal != null) {
                if (ftpVal instanceof Number) {
                    mFtp = ftpVal as Number;
                } else if (ftpVal instanceof String) {
                    mFtp = (ftpVal as String).toNumber();
                }
            }
            var decVal = getSettingValue("decimalZone");
            if (decVal != null) {
                if (decVal instanceof Number) {
                    mDecimalZone = ((decVal as Number) == 0);
                } else if (decVal instanceof Boolean) {
                    mDecimalZone = decVal as Boolean;
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

    // Called once per second by Garmin OS
    function compute(info as Activity.Info) as Void {
        if (mMetricType == 0) {
            // Heart Rate Mode
            mCurrentValue = info.currentHeartRate;
            mAvgValue = info.averageHeartRate;
            mZoneResult = mCalculator.calculateHrZone(mCurrentValue);
        } else {
            // Power Mode (7-Zone Coggan model)
            mCurrentValue = info.currentPower;
            mAvgValue = info.averagePower;
            mZoneResult = mCalculator.calculatePowerZone(mCurrentValue);
        }

        // Accumulate active time in current zone (both cumulative and interval)
        mStats.update(info, mZoneResult.zoneIndex);
    }

    // Main drawing method
    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var obscurity = getObscurityFlags();

        // 1. Clear background
        var defaultBg = getBackgroundColor();
        var zoneColor = mZoneResult.color;

        var bgColor = defaultBg;
        if (mFullBackgroundColor && mZoneResult.zoneIndex > 0) {
            bgColor = zoneColor;
        }
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // 2. Select appropriate layout based on height
        if (height < 60) {
            renderUltraCompactLayout(dc, width, height, obscurity);
        } else if (height < 95) {
            renderCompactLayout(dc, width, height, obscurity);
        } else {
            renderFullLayout(dc, width, height, obscurity);
        }
    }

    // Helper to get high-contrast foreground and subtitle colors
    private function getTextColor(zoneColor as Number, isDarkTheme as Boolean) as [Number, Number] {
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

    // -------------------------------------------------------------
    // Full Layout (for Edge single/dual fields, Watch full/half screens)
    // -------------------------------------------------------------
    private function renderFullLayout(
        dc as Graphics.Dc,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDarkTheme = (getBackgroundColor() == Graphics.COLOR_BLACK);
        var zoneColor = mZoneResult.color;
        var colors = getTextColor(zoneColor, isDarkTheme);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (mCurrentValue != null && mCurrentValue > 0) ? mCurrentValue.format("%d") : "--";
        var avgStr = (mAvgValue != null && mAvgValue > 0) ? mAvgValue.format("%d") : "--";
        var metricLabel = (mMetricType == 0) ? "HR" : "PWR";

        var zoneBadgeStr;
        if (mDecimalZone && mZoneResult.zoneIndex > 0) {
            zoneBadgeStr = mZoneResult.decimalZone.format("%.1f");
        } else {
            zoneBadgeStr = mZoneResult.label;
        }

        var cumSec = mStats.getCumulativeSeconds(mZoneResult.zoneIndex);
        var intSec = mStats.getIntervalSeconds();
        var cumStr = mStats.formatDuration(cumSec);
        var intStr = mStats.formatDuration(intSec);
        var dualZoneTimeStr = Lang.format("$1$ ($2$)", [cumStr, intStr]);

        // Safe insets handling watch bezels vs rectangular Edge screens
        var padTop = (obscurity & DataField.OBSCURE_TOP) != 0 ? (height * 0.18).toNumber() : (height * 0.08).toNumber();
        var padBottom = (obscurity & DataField.OBSCURE_BOTTOM) != 0 ? (height * 0.22).toNumber() : (height * 0.10).toNumber();
        var padLeft = (obscurity & DataField.OBSCURE_LEFT) != 0 ? (width * 0.16).toNumber() : (width * 0.08).toNumber();
        var padRight = (obscurity & DataField.OBSCURE_RIGHT) != 0 ? (width * 0.16).toNumber() : (width * 0.08).toNumber();

        var headerFont = (height > 150) ? Graphics.FONT_TINY : Graphics.FONT_XTINY;
        var headerFontH = dc.getFontHeight(headerFont);

        // Header: Metric label (left)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, padTop, headerFont, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // Header: Zone Badge Pill (right)
        var badgeText = (mZoneResult.zoneIndex > 0) ? ("Z" + zoneBadgeStr) : zoneBadgeStr;
        var badgeTextW = dc.getTextWidthInPixels(badgeText, headerFont);
        var badgeW = badgeTextW + 16;
        if (badgeW < (width * 0.24).toNumber()) {
            badgeW = (width * 0.24).toNumber();
        }
        var badgeH = headerFontH + 4;
        var badgeX = width - padRight - badgeW;
        var badgeY = padTop - 2;

        if (!mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 4);

            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(badgeX + (badgeW / 2), badgeY + 2, headerFont, badgeText, Graphics.TEXT_JUSTIFY_CENTER);

        // Center: Primary Value
        var valFont = Graphics.FONT_NUMBER_HOT;
        if (height < 125) {
            valFont = Graphics.FONT_NUMBER_MEDIUM;
        } else if (height < 165) {
            valFont = Graphics.FONT_NUMBER_MILD;
        }

        if (dc.getTextWidthInPixels(valueStr, valFont) > (width - padLeft - padRight)) {
            valFont = Graphics.FONT_NUMBER_MEDIUM;
        }
        if (dc.getTextWidthInPixels(valueStr, valFont) > (width - padLeft - padRight)) {
            valFont = Graphics.FONT_NUMBER_MILD;
        }

        var valFontH = dc.getFontHeight(valFont);
        var valY = (height / 2) - (valFontH / 2) - 2;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Footer: Session Average (Left) and In-Zone Time (Right)
        var footerFont = Graphics.FONT_XTINY;
        var footerY = height - padBottom - dc.getFontHeight(footerFont);
        var avgText = "AVG " + avgStr;
        var timeText = "Z" + mZoneResult.zoneIndex + " " + dualZoneTimeStr;

        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, footerY, footerFont, avgText, Graphics.TEXT_JUSTIFY_LEFT);

        var timeW = dc.getTextWidthInPixels(timeText, footerFont);
        if (timeW + dc.getTextWidthInPixels(avgText, footerFont) > (width - padLeft - padRight - 10)) {
            timeText = dualZoneTimeStr;
        }
        dc.drawText(width - padRight, footerY, footerFont, timeText, Graphics.TEXT_JUSTIFY_RIGHT);

        // Bottom accent bar if in accent badge mode
        if (!mFullBackgroundColor) {
            var barH = (height > 150) ? 5 : 3;
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, height - barH, width, barH);
        }
    }

    // -------------------------------------------------------------
    // Compact Layout (for 3-4 field grids on Edge or Watches)
    // -------------------------------------------------------------
    private function renderCompactLayout(
        dc as Graphics.Dc,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDarkTheme = (getBackgroundColor() == Graphics.COLOR_BLACK);
        var zoneColor = mZoneResult.color;
        var colors = getTextColor(zoneColor, isDarkTheme);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (mCurrentValue != null && mCurrentValue > 0) ? mCurrentValue.format("%d") : "--";
        var avgStr = (mAvgValue != null && mAvgValue > 0) ? mAvgValue.format("%d") : "--";
        var metricLabel = (mMetricType == 0) ? "HR" : "PWR";

        var zoneBadgeStr;
        if (mDecimalZone && mZoneResult.zoneIndex > 0) {
            zoneBadgeStr = mZoneResult.decimalZone.format("%.1f");
        } else {
            zoneBadgeStr = mZoneResult.label;
        }

        var cumSec = mStats.getCumulativeSeconds(mZoneResult.zoneIndex);
        var intSec = mStats.getIntervalSeconds();
        var cumStr = mStats.formatDuration(cumSec);
        var intStr = mStats.formatDuration(intSec);
        var dualZoneTimeStr = Lang.format("$1$ ($2$)", [cumStr, intStr]);

        var padLeft = (obscurity & DataField.OBSCURE_LEFT) != 0 ? (width * 0.12).toNumber() : 6;
        var padRight = (obscurity & DataField.OBSCURE_RIGHT) != 0 ? (width * 0.12).toNumber() : 6;

        var fontVal = Graphics.FONT_LARGE;
        if (dc.getTextWidthInPixels(valueStr, fontVal) > (width * 0.55).toNumber()) {
            fontVal = Graphics.FONT_MEDIUM;
        }
        var fontSub = Graphics.FONT_XTINY;
        var subH = dc.getFontHeight(fontSub);

        // Primary Value
        var valY = (height / 2) - (dc.getFontHeight(fontVal) / 2) - 4;
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft + (width * 0.32).toNumber(), valY, fontVal, valueStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Zone Badge
        var badgeText = "Z" + zoneBadgeStr;
        var badgeW = dc.getTextWidthInPixels(badgeText, fontSub) + 12;
        var badgeH = subH + 4;
        var badgeX = width - padRight - badgeW;
        var badgeY = 6;

        if (!mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(badgeX + (badgeW / 2), badgeY + 2, fontSub, badgeText, Graphics.TEXT_JUSTIFY_CENTER);

        // Header: Metric tag
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, 4, fontSub, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // Bottom sub-row: AVG and Dual Time
        var footerY = height - subH - 3;
        var avgText = "AVG " + avgStr;
        dc.drawText(padLeft, footerY, fontSub, avgText, Graphics.TEXT_JUSTIFY_LEFT);

        // Dual time
        dc.drawText(width - padRight, footerY, fontSub, dualZoneTimeStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // Bottom accent bar
        if (!mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, height - 3, width, 3);
        }
    }

    // -------------------------------------------------------------
    // Ultra Compact Layout (for 8-10 field grids / narrow Edge strips)
    // -------------------------------------------------------------
    private function renderUltraCompactLayout(
        dc as Graphics.Dc,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDarkTheme = (getBackgroundColor() == Graphics.COLOR_BLACK);
        var zoneColor = mZoneResult.color;
        var colors = getTextColor(zoneColor, isDarkTheme);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (mCurrentValue != null && mCurrentValue > 0) ? mCurrentValue.format("%d") : "--";
        var metricLabel = (mMetricType == 0) ? "HR" : "PWR";

        var zoneBadgeStr;
        if (mDecimalZone && mZoneResult.zoneIndex > 0) {
            zoneBadgeStr = mZoneResult.decimalZone.format("%.1f");
        } else {
            zoneBadgeStr = mZoneResult.label;
        }

        var cumSec = mStats.getCumulativeSeconds(mZoneResult.zoneIndex);
        var intSec = mStats.getIntervalSeconds();
        var cumStr = mStats.formatDuration(cumSec);
        var intStr = mStats.formatDuration(intSec);

        var padLeft = 4;
        var padRight = 4;
        var fontVal = Graphics.FONT_MEDIUM;
        var fontSub = Graphics.FONT_XTINY;

        // Metric label & Zone pill (left)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, (height / 2) - (dc.getFontHeight(fontSub) / 2), fontSub, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // Primary Value (center-left)
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText((width * 0.35).toNumber(), (height / 2) - (dc.getFontHeight(fontVal) / 2), fontVal, valueStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Zone Pill
        var badgeText = "Z" + zoneBadgeStr;
        var badgeW = dc.getTextWidthInPixels(badgeText, fontSub) + 8;
        var badgeH = height - 8;
        var badgeX = (width * 0.54).toNumber();
        var badgeY = 4;

        if (!mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(badgeX + (badgeW / 2), badgeY + (badgeH / 2) - (dc.getFontHeight(fontSub) / 2), fontSub, badgeText, Graphics.TEXT_JUSTIFY_CENTER);

        // Dual Time or Compact Time (right)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        var timeStr = cumStr + " (" + intStr + ")";
        if (dc.getTextWidthInPixels(timeStr, fontSub) > (width - (badgeX + badgeW) - 6)) {
            timeStr = cumStr; // Drop interval if horizontal space is minimal
        }
        dc.drawText(width - padRight, (height / 2) - (dc.getFontHeight(fontSub) / 2), fontSub, timeStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // Left accent strip
        if (!mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, 0, 3, height);
        }
    }
}
