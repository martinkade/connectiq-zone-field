import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class CircularLayoutRenderer {

    public function render(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isAllObscured = (obscurity == 15);
        var isFullScreen = isAllObscured || (height > 180 && width > 180 && ((width - height).abs() <= 20));

        if (isFullScreen) {
            renderFullScreen(dc, view, width, height);
        } else if ((obscurity & WatchUi.DataField.OBSCURE_TOP) != 0) {
            renderTopHalf(dc, view, width, height);
        } else if ((obscurity & WatchUi.DataField.OBSCURE_BOTTOM) != 0) {
            renderBottomHalf(dc, view, width, height);
        } else {
            renderMiddleSlice(dc, view, width, height);
        }
    }

    // -------------------------------------------------------------
    // 1. Full Circular Watch Screen (1-Field layout on round watches)
    // -------------------------------------------------------------
    private function renderFullScreen(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = height / 2;
        var radius = width / 2;

        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];
        var activeIndex = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HEART RATE" : "POWER";
        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";

        var zoneBadgeStr;
        if (view.mDecimalZone && activeIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (activeIndex > 0) {
            zoneBadgeStr = "Z" + activeIndex;
        } else {
            zoneBadgeStr = "--";
        }

        // 1. Radial Tachymeter Bezel Arc Gauge (165° down to 15° clockwise, 150° span centered at 12 o'clock)
        var arcR = radius - 8;
        var totalSweep = 150.0;
        var stepAngle = totalSweep / numZones.toFloat();

        for (var z = 1; z <= numZones; z++) {
            var bColor = view.mCalculator.getZoneColor(view.mMetricType, z);
            var isActive = (activeIndex == z);

            var startA = (165.0 - ((z - 1).toFloat() * stepAngle)).toNumber();
            var endA = (165.0 - (z.toFloat() * stepAngle)).toNumber();

            var penW = isActive ? 12 : 5;
            dc.setPenWidth(penW);
            dc.setColor(bColor, bColor);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, startA - 1, endA + 1);
        }
        dc.setPenWidth(1);

        // 2. Top Section: Metric Label + Active Zone Badge
        var topY = cy - (radius * 0.60).toNumber();
        var fontTiny = Graphics.FONT_XTINY;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, topY, fontTiny, metricLabel, Graphics.TEXT_JUSTIFY_CENTER);

        var badgeW = 60;
        var badgeH = 22;
        var badgeX = cx - (badgeW / 2);
        var badgeY = topY + dc.getFontHeight(fontTiny) + 2;

        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 4);

            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 4);
        }
        dc.drawText(cx, badgeY + (badgeH / 2) - (dc.getFontHeight(fontTiny) / 2) - 1, fontTiny, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 3. Center Section: Huge Primary Value + Baseline Unit
        var valFont = (radius > 170) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MEDIUM;
        var valW = dc.getTextWidthInPixels(valueStr, valFont);
        var unitW = dc.getTextWidthInPixels(unitStr, fontTiny);
        var totalNumW = valW + 4 + unitW;
        var numStartX = cx - (totalNumW / 2);
        var valFontH = dc.getFontHeight(valFont);
        var valY = cy - (valFontH / 2) - 2;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = valY + valFontH - dc.getFontHeight(fontTiny) - 4;
        var unitColor = (view.mFullBackgroundColor && activeIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX + valW + 4, unitY, fontTiny, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 4. Bottom Section: Session Average & In-Zone Timers
        var botY = cy + (radius * 0.38).toNumber();
        var avgText = "AVG " + avgStr;
        var cumSec = view.mStats.getCumulativeSeconds(activeIndex);
        var intSec = view.mStats.getIntervalSeconds();
        var dualTimeStr = Lang.format("$1$ ($2$)", [view.mStats.formatDuration(cumSec), view.mStats.formatDuration(intSec)]);

        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, botY, fontTiny, avgText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, botY + dc.getFontHeight(fontTiny) + 2, fontTiny, dualTimeStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // -------------------------------------------------------------
    // 2. Watch Top Half Screen (2-Field Screen, Top Dome)
    // -------------------------------------------------------------
    private function renderTopHalf(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = height;
        var radius = width / 2;

        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];
        var activeIndex = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";
        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";

        var zoneBadgeStr;
        if (view.mDecimalZone && activeIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (activeIndex > 0) {
            zoneBadgeStr = "Z" + activeIndex;
        } else {
            zoneBadgeStr = "--";
        }

        // 1. Top Bezel Arc (155° down to 25° clockwise, 130° span)
        var arcR = radius - 6;
        var totalSweep = 130.0;
        var stepAngle = totalSweep / numZones.toFloat();

        for (var z = 1; z <= numZones; z++) {
            var bColor = view.mCalculator.getZoneColor(view.mMetricType, z);
            var isActive = (activeIndex == z);

            var startA = (155.0 - ((z - 1).toFloat() * stepAngle)).toNumber();
            var endA = (155.0 - (z.toFloat() * stepAngle)).toNumber();

            var penW = isActive ? 10 : 4;
            dc.setPenWidth(penW);
            dc.setColor(bColor, bColor);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, startA - 1, endA + 1);
        }
        dc.setPenWidth(1);

        // 2. Metric Header + Active Zone Badge
        var fontTiny = Graphics.FONT_XTINY;
        var topY = 16;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 36, topY + 2, fontTiny, metricLabel, Graphics.TEXT_JUSTIFY_RIGHT);

        var badgeW = 48;
        var badgeH = 18;
        var badgeX = cx - 24;
        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, topY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, topY, badgeW, badgeH, 3);
        }
        dc.drawText(badgeX + (badgeW / 2), topY + (badgeH / 2) - (dc.getFontHeight(fontTiny) / 2) - 1, fontTiny, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 3. Primary Value at bottom flat edge where width is maximum
        var valFont = (height > 110) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MEDIUM;
        var valW = dc.getTextWidthInPixels(valueStr, valFont);
        var unitW = dc.getTextWidthInPixels(unitStr, fontTiny);
        var totalNumW = valW + 4 + unitW;
        var startX = cx - (totalNumW / 2);
        var valFontH = dc.getFontHeight(valFont);
        var valY = height - valFontH - 6;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = valY + valFontH - dc.getFontHeight(fontTiny) - 4;
        var unitColor = (view.mFullBackgroundColor && activeIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + valW + 4, unitY, fontTiny, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 4. AVG and Time
        var cumSec = view.mStats.getCumulativeSeconds(activeIndex);
        var timeStr = view.mStats.formatDuration(cumSec);
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(24, height - dc.getFontHeight(fontTiny) - 2, fontTiny, "AVG " + avgStr, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(width - 24, height - dc.getFontHeight(fontTiny) - 2, fontTiny, timeStr, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // -------------------------------------------------------------
    // 3. Watch Bottom Half Screen (2-Field Screen, Bottom Bowl)
    // -------------------------------------------------------------
    private function renderBottomHalf(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = 0;
        var radius = width / 2;

        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];
        var activeIndex = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";
        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";

        var zoneBadgeStr;
        if (view.mDecimalZone && activeIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (activeIndex > 0) {
            zoneBadgeStr = "Z" + activeIndex;
        } else {
            zoneBadgeStr = "--";
        }

        // 1. Primary Value at top flat edge where width is maximum
        var fontTiny = Graphics.FONT_XTINY;
        var valFont = (height > 110) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MEDIUM;
        var valW = dc.getTextWidthInPixels(valueStr, valFont);
        var unitW = dc.getTextWidthInPixels(unitStr, fontTiny);
        var totalNumW = valW + 4 + unitW;
        var startX = cx - (totalNumW / 2);
        var valFontH = dc.getFontHeight(valFont);
        var valY = 4;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = valY + valFontH - dc.getFontHeight(fontTiny) - 4;
        var unitColor = (view.mFullBackgroundColor && activeIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + valW + 4, unitY, fontTiny, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 2. Middle: Metric Tag + Zone Badge Pill
        var midY = valY + valFontH + 2;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 36, midY + 2, fontTiny, metricLabel, Graphics.TEXT_JUSTIFY_RIGHT);

        var badgeW = 48;
        var badgeH = 18;
        var badgeX = cx - 24;
        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, midY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, midY, badgeW, badgeH, 3);
        }
        dc.drawText(badgeX + (badgeW / 2), midY + (badgeH / 2) - (dc.getFontHeight(fontTiny) / 2) - 1, fontTiny, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 3. Bottom Bezel Arc (205° to 335° counter-clockwise, 130° span along bottom bowl)
        var arcR = radius - 6;
        var totalSweep = 130.0;
        var stepAngle = totalSweep / numZones.toFloat();

        for (var z = 1; z <= numZones; z++) {
            var bColor = view.mCalculator.getZoneColor(view.mMetricType, z);
            var isActive = (activeIndex == z);

            var startA = (205.0 + ((z - 1).toFloat() * stepAngle)).toNumber();
            var endA = (205.0 + (z.toFloat() * stepAngle)).toNumber();

            var penW = isActive ? 10 : 4;
            dc.setPenWidth(penW);
            dc.setColor(bColor, bColor);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_COUNTER_CLOCKWISE, startA - 1, endA + 1);
        }
        dc.setPenWidth(1);

        // 4. Stats: AVG and Time
        var cumSec = view.mStats.getCumulativeSeconds(activeIndex);
        var timeStr = view.mStats.formatDuration(cumSec);
        var botY = height - dc.getFontHeight(fontTiny) - 14;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, botY, fontTiny, "AVG " + avgStr + "   " + timeStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // -------------------------------------------------------------
    // 4. Watch Middle Slice / Multi-field Screen
    // -------------------------------------------------------------
    private function renderMiddleSlice(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];
        var activeIndex = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";
        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";

        var zoneBadgeStr;
        if (view.mDecimalZone && activeIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (activeIndex > 0) {
            zoneBadgeStr = "Z" + activeIndex;
        } else {
            zoneBadgeStr = "--";
        }

        var fontTiny = Graphics.FONT_XTINY;

        // Top: Metric tag + AVG + Zone pill
        var topY = 4;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 32, topY + 2, fontTiny, metricLabel + " " + avgStr, Graphics.TEXT_JUSTIFY_RIGHT);

        var badgeW = 48;
        var badgeH = 18;
        var badgeX = cx - 24;
        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, topY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, topY, badgeW, badgeH, 3);
        }
        dc.drawText(badgeX + (badgeW / 2), topY + (badgeH / 2) - (dc.getFontHeight(fontTiny) / 2) - 1, fontTiny, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Center: Primary Value
        var valFont = (height > 90) ? Graphics.FONT_LARGE : Graphics.FONT_MEDIUM;
        var valW = dc.getTextWidthInPixels(valueStr, valFont);
        var unitW = dc.getTextWidthInPixels(unitStr, fontTiny);
        var totalNumW = valW + 4 + unitW;
        var startX = cx - (totalNumW / 2);
        var valFontH = dc.getFontHeight(valFont);
        var valY = (height / 2) - (valFontH / 2) - 2;

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = valY + valFontH - dc.getFontHeight(fontTiny) - 2;
        var unitColor = (view.mFullBackgroundColor && activeIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + valW + 4, unitY, fontTiny, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Bottom: Horizontal Segmented Zone Bar
        var barTotalW = (width * 0.60).toNumber();
        var barX = cx - (barTotalW / 2);
        var barY = height - 10;
        var segW = (barTotalW / numZones).toNumber();

        for (var z = 1; z <= numZones; z++) {
            var bColor = view.mCalculator.getZoneColor(view.mMetricType, z);
            var isActive = (activeIndex == z);
            var curSegH = isActive ? 7 : 4;
            var curSegY = isActive ? (barY - 3) : barY;
            dc.setColor(bColor, bColor);
            dc.fillRectangle(barX + ((z - 1) * segW), curSegY, segW - 2, curSegH);
        }
    }
}
