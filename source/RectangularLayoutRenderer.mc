import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RectangularLayoutRenderer {

    public function render(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        if (height < 60) {
            renderUltraCompact(dc, view, width, height, obscurity);
        } else if (height < 95) {
            renderCompact(dc, view, width, height, obscurity);
        } else {
            renderFull(dc, view, width, height, obscurity);
        }
    }

    // -------------------------------------------------------------
    // Full Layout (for Edge single/dual fields)
    // -------------------------------------------------------------
    private function renderFull(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";

        var cumSec = view.mStats.getCumulativeSeconds(view.mZoneResult.zoneIndex);
        var intSec = view.mStats.getIntervalSeconds();
        var cumStr = view.mStats.formatDuration(cumSec);
        var intStr = view.mStats.formatDuration(intSec);
        var dualZoneTimeStr = Lang.format("$1$ ($2$)", [cumStr, intStr]);

        // Safe insets handling screen bezels
        var padTop = (obscurity & WatchUi.DataField.OBSCURE_TOP) != 0 ? (height * 0.18).toNumber() : (height * 0.08).toNumber();
        var padBottom = (obscurity & WatchUi.DataField.OBSCURE_BOTTOM) != 0 ? (height * 0.22).toNumber() : (height * 0.10).toNumber();
        var padLeft = (obscurity & WatchUi.DataField.OBSCURE_LEFT) != 0 ? (width * 0.16).toNumber() : (width * 0.08).toNumber();
        var padRight = (obscurity & WatchUi.DataField.OBSCURE_RIGHT) != 0 ? (width * 0.16).toNumber() : (width * 0.08).toNumber();

        var headerFont = (height > 150) ? Graphics.FONT_TINY : Graphics.FONT_XTINY;

        // Header: Metric label (left)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, padTop, headerFont, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // Right side: Vertical Stack of Zones (active bar expanded & labeled)
        var stackRight = width - padRight;
        var stackTop = padTop;
        var maxStackH = height - padTop - padBottom - dc.getFontHeight(Graphics.FONT_XTINY) - 8;
        var stackW = renderZoneStack(dc, view, stackRight, stackTop, maxStackH, false);

        // Center / Left: Primary Value + Unit
        var availValW = (stackRight - stackW - 8) - padLeft;
        var valCenterX = padLeft + (availValW / 2);

        var valFont = Graphics.FONT_NUMBER_HOT;
        if (height < 125 || availValW < 140) {
            valFont = Graphics.FONT_NUMBER_MEDIUM;
        } else if (height < 165 || availValW < 180) {
            valFont = Graphics.FONT_NUMBER_MILD;
        }

        if (dc.getTextWidthInPixels(valueStr, valFont) > availValW) {
            valFont = Graphics.FONT_NUMBER_MEDIUM;
        }
        if (dc.getTextWidthInPixels(valueStr, valFont) > availValW) {
            valFont = Graphics.FONT_NUMBER_MILD;
        }
        if (dc.getTextWidthInPixels(valueStr, valFont) > availValW) {
            valFont = Graphics.FONT_LARGE;
        }

        var valW = dc.getTextWidthInPixels(valueStr, valFont);
        var valFontH = dc.getFontHeight(valFont);
        var valY = (height / 2) - (valFontH / 2) - 2;

        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";
        var unitFont = Graphics.FONT_XTINY;
        var unitW = dc.getTextWidthInPixels(unitStr, unitFont);
        var unitH = dc.getFontHeight(unitFont);

        // Draw value and unit centered together in availValW
        var totalNumW = valW + 4 + unitW;
        var numStartX = valCenterX - (totalNumW / 2);
        if (numStartX < padLeft) {
            numStartX = padLeft;
        }

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX, valY, valFont, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Unit drawn at baseline next to digits in active zone color
        var unitY = valY + valFontH - unitH - 4;
        var unitColor = (view.mFullBackgroundColor && view.mZoneResult.zoneIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX + valW + 4, unitY, unitFont, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Footer: Session Average (Left) and In-Zone Time (Right)
        var footerFont = Graphics.FONT_XTINY;
        var footerY = height - padBottom - dc.getFontHeight(footerFont);
        var avgText = "AVG " + avgStr;
        var timeText = "Z" + view.mZoneResult.zoneIndex + " " + dualZoneTimeStr;

        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, footerY, footerFont, avgText, Graphics.TEXT_JUSTIFY_LEFT);

        var timeW = dc.getTextWidthInPixels(timeText, footerFont);
        if (timeW + dc.getTextWidthInPixels(avgText, footerFont) > (width - padLeft - padRight - 10)) {
            timeText = dualZoneTimeStr;
        }
        dc.drawText(width - padRight, footerY, footerFont, timeText, Graphics.TEXT_JUSTIFY_RIGHT);

        // Bottom accent bar if in accent badge mode
        if (!view.mFullBackgroundColor) {
            var barH = (height > 150) ? 5 : 3;
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, height - barH, width, barH);
        }
    }

    // -------------------------------------------------------------
    // Compact Layout (for 3-4 field grids on Edge)
    // -------------------------------------------------------------
    private function renderCompact(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var avgStr = (view.mAvgValue != null && view.mAvgValue > 0) ? view.mAvgValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";

        var cumSec = view.mStats.getCumulativeSeconds(view.mZoneResult.zoneIndex);
        var intSec = view.mStats.getIntervalSeconds();
        var cumStr = view.mStats.formatDuration(cumSec);
        var intStr = view.mStats.formatDuration(intSec);
        var dualZoneTimeStr = Lang.format("$1$ ($2$)", [cumStr, intStr]);

        var padLeft = (obscurity & WatchUi.DataField.OBSCURE_LEFT) != 0 ? (width * 0.12).toNumber() : 6;
        var padRight = (obscurity & WatchUi.DataField.OBSCURE_RIGHT) != 0 ? (width * 0.12).toNumber() : 6;

        // Zone Stack on the right
        var fontSub = Graphics.FONT_XTINY;
        var subH = dc.getFontHeight(fontSub);
        var stackRight = width - padRight;
        var stackTop = 4;
        var maxStackH = height - subH - 10;
        var stackW = renderZoneStack(dc, view, stackRight, stackTop, maxStackH, true);

        // Header: Metric tag
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, 4, fontSub, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // Primary Value + Unit
        var availValW = (stackRight - stackW - 6) - padLeft;
        var valCenterX = padLeft + (availValW / 2);

        var fontVal = Graphics.FONT_LARGE;
        if (dc.getTextWidthInPixels(valueStr, fontVal) > availValW) {
            fontVal = Graphics.FONT_MEDIUM;
        }

        var valW = dc.getTextWidthInPixels(valueStr, fontVal);
        var valH = dc.getFontHeight(fontVal);
        var valY = (height / 2) - (valH / 2) - 2;

        var unitStr = (view.mMetricType == 1) ? "W" : "bpm";
        var unitW = dc.getTextWidthInPixels(unitStr, fontSub);
        var totalNumW = valW + 3 + unitW;
        var numStartX = valCenterX - (totalNumW / 2);
        if (numStartX < padLeft) {
            numStartX = padLeft;
        }

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX, valY, fontVal, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        var unitY = valY + valH - subH - 2;
        var unitColor = (view.mFullBackgroundColor && view.mZoneResult.zoneIndex > 0) ? fgColor : zoneColor;
        if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
            unitColor = subTextColor;
        }
        dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numStartX + valW + 3, unitY, fontSub, unitStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Bottom sub-row: AVG and Dual Time
        var footerY = height - subH - 3;
        var avgText = "AVG " + avgStr;
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, footerY, fontSub, avgText, Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawText(width - padRight, footerY, fontSub, dualZoneTimeStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // Bottom accent bar
        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, height - 3, width, 3);
        }
    }

    // -------------------------------------------------------------
    // Ultra Compact Layout (for 8-10 field grids)
    // -------------------------------------------------------------
    private function renderUltraCompact(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number,
        obscurity as Number
    ) as Void {
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var subTextColor = colors[1];

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0) ? view.mCurrentValue.format("%d") : "--";
        var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";

        var zoneBadgeStr;
        if (view.mDecimalZone && view.mZoneResult.zoneIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (view.mZoneResult.zoneIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.zoneIndex;
        } else {
            zoneBadgeStr = "--";
        }

        var cumSec = view.mStats.getCumulativeSeconds(view.mZoneResult.zoneIndex);
        var cumStr = view.mStats.formatDuration(cumSec);

        var padLeft = 4;
        var padRight = 4;
        var fontVal = Graphics.FONT_MEDIUM;
        var fontSub = Graphics.FONT_XTINY;
        var subH = dc.getFontHeight(fontSub);

        // 1. Metric label (far left)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(padLeft, (height / 2) - (subH / 2), fontSub, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);

        // 2. Value + unit (center-left)
        var unitStr = (view.mMetricType == 1) ? "W" : "";
        var valW = dc.getTextWidthInPixels(valueStr, fontVal);
        var valX = padLeft + dc.getTextWidthInPixels(metricLabel, fontSub) + 6;
        var valY = (height / 2) - (dc.getFontHeight(fontVal) / 2);

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(valX, valY, fontVal, valueStr, Graphics.TEXT_JUSTIFY_LEFT);
        if (unitStr.length() > 0) {
            var unitColor = (view.mFullBackgroundColor && view.mZoneResult.zoneIndex > 0) ? fgColor : zoneColor;
            if (unitColor == Graphics.COLOR_LT_GRAY && !isDark) {
                unitColor = subTextColor;
            }
            dc.setColor(unitColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(valX + valW + 2, (height / 2) + (dc.getFontHeight(fontVal) / 2) - subH - 2, fontSub, unitStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 3. Zone Badge + Mini Stack (center-right)
        var badgeW = dc.getTextWidthInPixels(zoneBadgeStr, fontSub) + 8;
        var badgeH = height - 8;
        var badgeX = (width * 0.52).toNumber();
        var badgeY = 4;

        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 3);
            var badgeTextCol = (zoneColor == Graphics.COLOR_YELLOW || zoneColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
            dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(badgeX + (badgeW / 2), badgeY + (badgeH / 2) - (subH / 2), fontSub, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Mini vertical stack of bars next to the badge
        var numZones = (view.mMetricType == 1) ? 7 : 5;
        var miniStackX = badgeX + badgeW + 4;
        var miniBarW = 12;
        var miniBarH = 2;
        var miniGap = 1;
        var miniTotalH = (numZones * miniBarH) + ((numZones - 1) * miniGap);
        var miniStartY = (height / 2) - (miniTotalH / 2);

        for (var mi = 0; mi < numZones; mi++) {
            var zNum = numZones - mi;
            var bCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var isAct = (view.mZoneResult.zoneIndex == zNum);
            var bW = isAct ? miniBarW : (miniBarW - 3);
            var bX = isAct ? miniStackX : (miniStackX + 3);
            dc.setColor(bCol, bCol);
            dc.fillRectangle(bX, miniStartY + (mi * (miniBarH + miniGap)), bW, miniBarH);
        }

        // 4. Time in zone (far right)
        dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width - padRight, (height / 2) - (subH / 2), fontSub, cumStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // Left accent strip
        if (!view.mFullBackgroundColor) {
            dc.setColor(zoneColor, zoneColor);
            dc.fillRectangle(0, 0, 3, height);
        }
    }

    // -------------------------------------------------------------
    // Rectangular Zone Stack (Right side, active bar labeled & highlighted)
    // -------------------------------------------------------------
    private function renderZoneStack(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        rightX as Number,
        topY as Number,
        availH as Number,
        compactMode as Boolean
    ) as Number {
        var numZones = (view.mMetricType == 1) ? 7 : 5;
        var activeIndex = view.mZoneResult.zoneIndex;
        var zoneColor = view.mZoneResult.color;
        var isDark = view.isDarkTheme();
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];

        // 1. Stack width: ~22-26% of screen width
        var screenW = dc.getWidth();
        var stackW = (screenW * 0.22).toNumber();
        if (stackW < 44) {
            stackW = 44;
        } else if (stackW > 98) {
            stackW = 98;
        }

        var stackLeft = rightX - stackW;
        var indent = (stackW * 0.20).toNumber();
        if (indent < 6) {
            indent = 6;
        }

        // 2. Bar Dimensions: Active bar is taller so zone name fits directly inside it
        var activeH = compactMode ? 18 : 24;
        if (!compactMode && availH > 140) {
            activeH = 28;
        }
        var inactiveH = compactMode ? 3 : 5;
        var barGap = compactMode ? 2 : 3;

        // Calculate total height of the stack and center vertically in availH
        var totalStackH = activeH + ((numZones - 1) * inactiveH) + ((numZones - 1) * barGap);
        var curY = topY + ((availH - totalStackH) / 2);
        if (curY < topY) {
            curY = topY;
        }

        // Zone label text for the highlighted active bar
        var zoneBadgeStr;
        if (view.mDecimalZone && activeIndex > 0) {
            zoneBadgeStr = "Z" + view.mZoneResult.decimalZone.format("%.1f");
        } else if (activeIndex > 0) {
            zoneBadgeStr = "Z" + activeIndex;
        } else {
            zoneBadgeStr = "--";
        }

        var badgeFont = (activeH > 22) ? Graphics.FONT_TINY : Graphics.FONT_XTINY;
        if (dc.getTextWidthInPixels(zoneBadgeStr, badgeFont) > (stackW - 4)) {
            badgeFont = Graphics.FONT_XTINY;
        }
        var fontH = dc.getFontHeight(badgeFont);

        // 3. Render stack from top to bottom (Power: 7..1, HR: 5..1)
        for (var i = 0; i < numZones; i++) {
            var zoneNum = numZones - i;
            var barColor = view.mCalculator.getZoneColor(view.mMetricType, zoneNum);
            var isHighlight = (activeIndex == zoneNum) || (activeIndex == 0 && zoneNum == 1);

            if (isHighlight) {
                // Highlighted active zone bar: Extended to the left, full width, with label inside!
                var barX = stackLeft;
                var curBarW = stackW;

                if (!view.mFullBackgroundColor) {
                    dc.setColor(barColor, barColor);
                    dc.fillRoundedRectangle(barX, curY, curBarW, activeH, 4);

                    var badgeTextCol = (barColor == Graphics.COLOR_YELLOW || barColor == Graphics.COLOR_LT_GRAY) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
                    dc.setColor(badgeTextCol, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawRoundedRectangle(barX, curY, curBarW, activeH, 4);
                }

                dc.drawText(barX + (curBarW / 2), curY + (activeH / 2) - (fontH / 2) - 1, badgeFont, zoneBadgeStr, Graphics.TEXT_JUSTIFY_CENTER);
                curY += activeH + barGap;
            } else {
                // Inactive zone bar: Slim horizontal bar, indented on the left
                var barX = stackLeft + indent;
                var curBarW = stackW - indent;

                dc.setColor(barColor, barColor);
                dc.fillRectangle(barX, curY, curBarW, inactiveH);
                curY += inactiveH + barGap;
            }
        }

        return stackW;
    }
}
