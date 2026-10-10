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
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var subTextColor = colors[1];

        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Safe insets handling screen bezels & obscurity flags
        var padLeft = (obscurity & WatchUi.DataField.OBSCURE_LEFT) != 0 ? (width * 0.12).toNumber() : 6;
        var padRight = (obscurity & WatchUi.DataField.OBSCURE_RIGHT) != 0 ? (width * 0.12).toNumber() : 6;
        var padTop = (obscurity & WatchUi.DataField.OBSCURE_TOP) != 0 ? (height * 0.14).toNumber() : 4;
        var padBottom = (obscurity & WatchUi.DataField.OBSCURE_BOTTOM) != 0 ? (height * 0.14).toNumber() : 3;

        // Available horizontal space for bottom bar
        var barLeft = padLeft;
        var barWidth = width - padLeft - padRight;
        if (barWidth < 40) {
            barLeft = 4;
            barWidth = width - 8;
        }

        // Dynamic scale sizing based on field height
        var baseBarH;
        var deltaH;
        var triH;
        var triHalfW;
        var minActiveW;

        if (height >= 160) {
            baseBarH = 14;
            deltaH = 8;
            triH = 7;
            triHalfW = 5;
            minActiveW = 24;
        } else if (height >= 110) {
            baseBarH = 10;
            deltaH = 6;
            triH = 6;
            triHalfW = 4;
            minActiveW = 20;
        } else if (height >= 65) {
            baseBarH = 8;
            deltaH = 4;
            triH = 5;
            triHalfW = 3;
            minActiveW = 16;
        } else {
            // Ultra-compact (< 65px)
            baseBarH = 5;
            deltaH = 3;
            triH = 4;
            triHalfW = 3;
            minActiveW = 12;
        }

        var activeBarH = baseBarH + deltaH;
        var barBottomY = height - padBottom;

        // Compute proportional segment widths for Zones 1..numZones
        var segmentWidths = view.mStats.computeSegmentWidths(barWidth, activeZone, minActiveW);

        // 1. Draw Horizontal Stacked Bar Chart (flush to bottom)
        var curX = barLeft;
        var activeStartX = barLeft;
        var activeW = 0;

        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var segW = segmentWidths[i];
            if (segW <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var isAct = (zNum == activeZone);

            if (isAct) {
                activeStartX = curX;
                activeW = segW;
                var segY = barBottomY - activeBarH;

                var actSegCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : segCol;
                dc.setColor(actSegCol, actSegCol);
                dc.fillRectangle(curX, segY, segW, activeBarH);

                // Highlight border around elevated active segment
                var borderCol = (view.mFullBackgroundColor && activeZone > 0)
                    ? Graphics.COLOR_DK_GRAY
                    : (isDark ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
                dc.setColor(borderCol, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(curX, segY, segW, activeBarH);
            } else {
                var segY = barBottomY - baseBarH;

                dc.setColor(segCol, segCol);
                dc.fillRectangle(curX, segY, segW, baseBarH);
            }

            // Segment divider line (1px contrast)
            if (i > 0) {
                var divCol = view.getBaseBackgroundColor();
                dc.setColor(divCol, divCol);
                dc.drawLine(curX, barBottomY - baseBarH, curX, barBottomY);
            }

            curX += segW;
        }

        // 2. Draw Within-Zone Position Indicator (right above elevated active segment)
        var indBottomY = barBottomY - activeBarH - 2;
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);

        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && activeW > 0) {
            var progress = view.mZoneResult.zoneProgress; // 0.0 to 1.0
            var indX = activeStartX + (progress * activeW).toNumber();

            // Clamp indicator marker within active segment bounds
            var minIndX = activeStartX + triHalfW;
            var maxIndX = activeStartX + activeW - triHalfW;
            if (minIndX > maxIndX) {
                indX = activeStartX + (activeW / 2);
            } else {
                if (indX < minIndX) { indX = minIndX; }
                if (indX > maxIndX) { indX = maxIndX; }
            }

            var triTopY = indBottomY - triH;
            var indCol = (view.mFullBackgroundColor && activeZone > 0)
                ? Graphics.COLOR_WHITE
                : (isDark ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);

            dc.setColor(indCol, indCol);
            dc.fillPolygon([
                [indX, indBottomY],
                [indX - triHalfW, triTopY],
                [indX + triHalfW, triTopY]
            ]);
        }

        // 3. Render Hero Section: Large Value + Inline Active Zone Badge
        var heroTopY = padTop;
        var heroBottomY = indBottomY - triH - 3;
        var availHeroH = heroBottomY - heroTopY;
        if (availHeroH < 20) {
            availHeroH = 20;
            heroTopY = 2;
        }

        drawHeroAndBadge(dc, view, heroTopY, availHeroH);

        // 4. Subtle Top Metric Label (only if plenty of vertical room, e.g. height >= 140)
        if (height >= 140) {
            var metricLabel = (view.mMetricType == 0) ? "HR" : "PWR";
            dc.setColor(subTextColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(padLeft, padTop, Graphics.FONT_XTINY, metricLabel, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    // -------------------------------------------------------------
    // Renders the Hero Value + Inline Active Zone Badge (e.g. "148  [Z2]")
    // -------------------------------------------------------------
    private function drawHeroAndBadge(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        topY as Number,
        availH as Number
    ) as Void {
        var screenWidth = dc.getWidth();
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var activeZone = view.mZoneResult.zoneIndex;
        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0)
            ? view.mCurrentValue.format("%d")
            : "--";

        var badgeStr = (activeZone > 0) ? ("Z" + activeZone) : "--";

        var maxAllowedW = screenWidth - 16;

        // Select optimal typography pairing based on availH (primary) and maxAllowedW
        var fontVal;
        var fontBadge;
        var gap = 5;
        var padBadgeY = 2;

        if (availH >= 110 && maxAllowedW >= 220) {
            fontVal = Graphics.FONT_NUMBER_MEDIUM;
            fontBadge = Graphics.FONT_SMALL;
            gap = 8;
            padBadgeY = 3;
        } else if (availH >= 75 && maxAllowedW >= 180) {
            fontVal = Graphics.FONT_NUMBER_MILD;
            fontBadge = Graphics.FONT_TINY;
            gap = 6;
            padBadgeY = 2;
        } else if (availH >= 42 && maxAllowedW >= 120) {
            fontVal = Graphics.FONT_LARGE;
            fontBadge = Graphics.FONT_XTINY;
            gap = 5;
            padBadgeY = 2;
        } else if (availH >= 30 && maxAllowedW >= 90) {
            fontVal = Graphics.FONT_MEDIUM;
            fontBadge = Graphics.FONT_XTINY;
            gap = 4;
            padBadgeY = 1;
        } else if (availH >= 22 && maxAllowedW >= 70) {
            fontVal = Graphics.FONT_SMALL;
            fontBadge = Graphics.FONT_XTINY;
            gap = 3;
            padBadgeY = 1;
        } else {
            fontVal = Graphics.FONT_TINY;
            fontBadge = Graphics.FONT_XTINY;
            gap = 3;
            padBadgeY = 1;
        }

        var valW = dc.getTextWidthInPixels(valueStr, fontVal);
        var badgeTxtW = dc.getTextWidthInPixels(badgeStr, fontBadge);
        var badgeTxtH = dc.getFontHeight(fontBadge);
        var badgeBoxH = badgeTxtH + (2 * padBadgeY);
        var padBadgeX = (badgeBoxH * 0.42).toNumber();
        if (padBadgeX < 5) { padBadgeX = 5; }
        var badgeBoxW = badgeTxtW + (2 * padBadgeX);
        if (badgeBoxW < badgeBoxH) { badgeBoxW = badgeBoxH; }
        var groupW = valW + gap + badgeBoxW;

        // If total width exceeds maxAllowedW, step down to smaller font
        if (groupW > maxAllowedW) {
            if (fontVal == Graphics.FONT_NUMBER_MEDIUM) {
                fontVal = Graphics.FONT_NUMBER_MILD;
                fontBadge = Graphics.FONT_TINY;
            } else if (fontVal == Graphics.FONT_NUMBER_MILD) {
                fontVal = Graphics.FONT_LARGE;
                fontBadge = Graphics.FONT_XTINY;
            } else if (fontVal == Graphics.FONT_LARGE) {
                fontVal = Graphics.FONT_MEDIUM;
            } else if (fontVal == Graphics.FONT_MEDIUM) {
                fontVal = Graphics.FONT_SMALL;
            }
            valW = dc.getTextWidthInPixels(valueStr, fontVal);
            badgeTxtW = dc.getTextWidthInPixels(badgeStr, fontBadge);
            badgeTxtH = dc.getFontHeight(fontBadge);
            badgeBoxH = badgeTxtH + (2 * padBadgeY);
            padBadgeX = (badgeBoxH * 0.42).toNumber();
            if (padBadgeX < 5) { padBadgeX = 5; }
            badgeBoxW = badgeTxtW + (2 * padBadgeX);
            if (badgeBoxW < badgeBoxH) { badgeBoxW = badgeBoxH; }
            groupW = valW + gap + badgeBoxW;
        }

        // Center entire [Value] + [Badge] group horizontally
        var startX = (screenWidth - groupW) / 2;
        if (startX < 4) {
            startX = 4;
        }
        var valX = startX;
        var badgeX = valX + valW + gap;

        // Vertically center in availH
        var valFontH = dc.getFontHeight(fontVal);
        var valY = topY + ((availH - valFontH) / 2);
        if (valY < topY) {
            valY = topY;
        }

        // Draw Value (no unit)
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(valX, valY, fontVal, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

        // Align badge vertically with optical middle of the number font
        var badgeY = valY + ((valFontH - badgeBoxH) / 2);
        if (badgeY < topY) {
            badgeY = topY;
        }

        // Draw Badge as a smooth pill (corner radius = half height)
        var pillRadius = (badgeBoxH / 2).toNumber();
        var badgeTextY = badgeY + ((badgeBoxH - badgeTxtH) / 2) - 1;

        if (view.mFullBackgroundColor && activeZone > 0) {
            // Full background mode: do not fill badge, draw white border with white text
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawRoundedRectangle(badgeX, badgeY, badgeBoxW, badgeBoxH, pillRadius);
            dc.drawText(badgeX + (badgeBoxW / 2), badgeTextY, fontBadge, badgeStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            var bFill = (activeZone > 0) ? zoneColor : Graphics.COLOR_DK_GRAY;
            var bTextCol = (bFill == Graphics.COLOR_YELLOW || bFill == Graphics.COLOR_LT_GRAY)
                ? Graphics.COLOR_BLACK
                : Graphics.COLOR_WHITE;

            dc.setColor(bFill, bFill);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeBoxW, badgeBoxH, pillRadius);

            dc.setColor(bTextCol, Graphics.COLOR_TRANSPARENT);
            dc.drawText(badgeX + (badgeBoxW / 2), badgeTextY, fontBadge, badgeStr, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
