import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
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
            renderTopDome(dc, view, width, height);
        } else if ((obscurity & WatchUi.DataField.OBSCURE_BOTTOM) != 0) {
            renderBottomBowl(dc, view, width, height);
        } else {
            renderMiddleBand(dc, view, width, height);
        }
    }

    // =============================================================
    // 1. Top Dome Screen (Upper Half of Watch Face: OBSCURE_TOP)
    // Dynamic adaptation: Pin arc stacked bar to the top bezel,
    // active segment radially thicker, indicator below it, hero value below.
    // =============================================================
    private function renderTopDome(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = height; // circle center is at bottom chord
        var radius = width / 2;
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Top arc spans 120 degrees: 150 deg (left) clockwise to 30 deg (right)
        var totalAngle = 120;
        var segAngles = view.mStats.computeSegmentWidths(totalAngle, activeZone, 12);

        var arcR = radius - 8;
        var penInactive = 8;
        var penActive = 14;

        var curAngle = 150;
        var actStartAngle = 150;
        var actSpanAngle = 0;

        // 1. Draw Pinned Top Arc Stacked Bar
        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var span = segAngles[i];
            if (span <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var endAngle = curAngle - span;
            var isAct = (zNum == activeZone);

            if (isAct) {
                actStartAngle = curAngle;
                actSpanAngle = span;
                dc.setPenWidth(penActive);
                if (view.mFullBackgroundColor && activeZone > 0) {
                    segCol = Graphics.COLOR_WHITE;
                }
            } else {
                dc.setPenWidth(penInactive);
            }

            dc.setColor(segCol, segCol);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, curAngle, endAngle);

            curAngle = endAngle;
        }

        // 2. Indicator Pip/Caret along the active arc segment
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actSpanAngle > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indAngle = actStartAngle.toFloat() - (progress * actSpanAngle.toFloat());
            var indRad = Math.toRadians(indAngle);

            // Pip position on the inner edge of the active arc
            var pipR = arcR - (penActive / 2) - 4;
            var pipX = cx + (pipR.toFloat() * Math.cos(indRad)).toNumber();
            var pipY = cy - (pipR.toFloat() * Math.sin(indRad)).toNumber();

            var pipCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : view.mZoneResult.color;
            dc.setColor(pipCol, pipCol);
            dc.fillCircle(pipX, pipY, 5);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillCircle(pipX, pipY, 2);
        }

        // 3. Hero Value + Inline Active Zone Badge (positioned below the arc)
        var heroCenterY = (height * 0.58).toNumber();
        var maxW = (width * 0.85).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW);
    }

    // =============================================================
    // 2. Bottom Bowl Screen (Lower Half of Watch Face: OBSCURE_BOTTOM)
    // Dynamic adaptation: Pin arc stacked bar to the bottom bezel,
    // active segment radially thicker, indicator above it, hero value above.
    // =============================================================
    private function renderBottomBowl(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = 0; // circle center is at flat top chord
        var radius = width / 2;
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Bottom arc spans 120 degrees: 210 deg (left) counter-clockwise to 330 deg (right)
        var totalAngle = 120;
        var segAngles = view.mStats.computeSegmentWidths(totalAngle, activeZone, 12);

        var arcR = radius - 8;
        var penInactive = 8;
        var penActive = 14;

        var curAngle = 210;
        var actStartAngle = 210;
        var actSpanAngle = 0;

        // 1. Draw Pinned Bottom Arc Stacked Bar
        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var span = segAngles[i];
            if (span <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var endAngle = curAngle + span;
            var isAct = (zNum == activeZone);

            if (isAct) {
                actStartAngle = curAngle;
                actSpanAngle = span;
                dc.setPenWidth(penActive);
                if (view.mFullBackgroundColor && activeZone > 0) {
                    segCol = Graphics.COLOR_WHITE;
                }
            } else {
                dc.setPenWidth(penInactive);
            }

            dc.setColor(segCol, segCol);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_COUNTER_CLOCKWISE, curAngle, endAngle);

            curAngle = endAngle;
        }

        // 2. Indicator Pip/Caret along the active arc segment
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actSpanAngle > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indAngle = actStartAngle.toFloat() + (progress * actSpanAngle.toFloat());
            var indRad = Math.toRadians(indAngle);

            // Pip position on the upper/inner edge of the bottom arc
            var pipR = arcR - (penActive / 2) - 4;
            var pipX = cx + (pipR.toFloat() * Math.cos(indRad)).toNumber();
            var pipY = cy - (pipR.toFloat() * Math.sin(indRad)).toNumber();

            var pipCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : view.mZoneResult.color;
            dc.setColor(pipCol, pipCol);
            dc.fillCircle(pipX, pipY, 5);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillCircle(pipX, pipY, 2);
        }

        // 3. Hero Value + Inline Active Zone Badge (positioned above the bottom arc)
        var heroCenterY = (height * 0.38).toNumber();
        var maxW = (width * 0.85).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW);
    }

    // =============================================================
    // 3. Full Circular Screen (1-Field Watch Layout)
    // =============================================================
    private function renderFullScreen(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var cx = width / 2;
        var cy = height / 2;
        var radius = width / 2;
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Top Subtle Clock
        drawTopClock(dc, cx, cy - (radius * 0.78).toNumber());

        // Pinned Bottom Arc Stacked Bar (210 deg to 330 deg counter-clockwise)
        var totalAngle = 120;
        var segAngles = view.mStats.computeSegmentWidths(totalAngle, activeZone, 12);

        var arcR = radius - 10;
        var penInactive = 10;
        var penActive = 16;

        var curAngle = 210;
        var actStartAngle = 210;
        var actSpanAngle = 0;

        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var span = segAngles[i];
            if (span <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var endAngle = curAngle + span;
            var isAct = (zNum == activeZone);

            if (isAct) {
                actStartAngle = curAngle;
                actSpanAngle = span;
                dc.setPenWidth(penActive);
                if (view.mFullBackgroundColor && activeZone > 0) {
                    segCol = Graphics.COLOR_WHITE;
                }
            } else {
                dc.setPenWidth(penInactive);
            }

            dc.setColor(segCol, segCol);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_COUNTER_CLOCKWISE, curAngle, endAngle);

            curAngle = endAngle;
        }

        // Indicator Pip on the active segment
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actSpanAngle > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indAngle = actStartAngle.toFloat() + (progress * actSpanAngle.toFloat());
            var indRad = Math.toRadians(indAngle);

            var pipR = arcR - (penActive / 2) - 5;
            var pipX = cx + (pipR.toFloat() * Math.cos(indRad)).toNumber();
            var pipY = cy - (pipR.toFloat() * Math.sin(indRad)).toNumber();

            var pipCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : view.mZoneResult.color;
            dc.setColor(pipCol, pipCol);
            dc.fillCircle(pipX, pipY, 6);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillCircle(pipX, pipY, 2);
        }

        // Hero Value + Inline Active Zone Badge (Hero centered prominently)
        var heroCenterY = cy - 4;
        var maxW = (width * 0.85).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW);
    }

    // =============================================================
    // 4. Middle Band Screen (Multi-field horizontal slice)
    // =============================================================
    private function renderMiddleBand(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var isDark = view.isDarkTheme();
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // In middle band, width has horizontal borders
        var padLeft = 10;
        var padRight = 10;
        var barW = width - padLeft - padRight;
        var barBottomY = height - 3;
        var baseBarH = (height > 90) ? 8 : 6;
        var activeBarH = baseBarH + 4;
        var minActiveW = 16;

        var segmentWidths = view.mStats.computeSegmentWidths(barW, activeZone, minActiveW);

        // 1. Bottom Stacked Bar
        var curX = padLeft;
        var actStartX = padLeft;
        var actW = 0;

        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var segW = segmentWidths[i];
            if (segW <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var isAct = (zNum == activeZone);

            if (isAct) {
                actStartX = curX;
                actW = segW;
                var segY = barBottomY - activeBarH;
                var actCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : segCol;
                dc.setColor(actCol, actCol);
                dc.fillRectangle(curX, segY, segW, activeBarH);
            } else {
                var segY = barBottomY - baseBarH;
                dc.setColor(segCol, segCol);
                dc.fillRectangle(curX, segY, segW, baseBarH);
            }

            curX += segW;
        }

        // 2. Position Indicator Caret
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        var triH = 4;
        var triHalfW = 3;
        var indBottomY = barBottomY - activeBarH - 2;

        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actW > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indX = actStartX + (progress * actW).toNumber();
            var minIndX = actStartX + triHalfW;
            var maxIndX = actStartX + actW - triHalfW;
            if (indX < minIndX) { indX = minIndX; }
            if (indX > maxIndX) { indX = maxIndX; }

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

        // 3. Hero Value + Inline Badge
        var heroAvailH = indBottomY - triH - 4;
        var heroCenterY = 2 + (heroAvailH / 2);
        drawHeroValueAndBadge(dc, view, width / 2, heroCenterY, barW);
    }

    // =============================================================
    // Helper: Draw Hero Value (large, no unit) + Inline Active Zone Badge
    // =============================================================
    private function drawHeroValueAndBadge(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        centerX as Number,
        centerY as Number,
        maxAllowedW as Number
    ) as Void {
        var isDark = view.isDarkTheme();
        var zoneColor = view.mZoneResult.color;
        var colors = view.getTextColor(zoneColor, isDark);
        var fgColor = colors[0];
        var activeZone = view.mZoneResult.zoneIndex;

        var valueStr = (view.mCurrentValue != null && view.mCurrentValue > 0)
            ? view.mCurrentValue.format("%d")
            : "--";

        var badgeStr = (activeZone > 0) ? ("Z" + activeZone) : "--";

        // Select optimal numeric font and badge font (stepped down for clean proportion)
        var fontVal = Graphics.FONT_NUMBER_MEDIUM;
        var fontBadge = Graphics.FONT_SMALL;
        var gap = 8;
        var padBadgeY = 3;

        if (maxAllowedW < 180) {
            fontVal = Graphics.FONT_LARGE;
            fontBadge = Graphics.FONT_XTINY;
            gap = 5;
            padBadgeY = 2;
        } else if (maxAllowedW < 230) {
            fontVal = Graphics.FONT_NUMBER_MILD;
            fontBadge = Graphics.FONT_TINY;
            gap = 6;
            padBadgeY = 2;
        }

        var valW = dc.getTextWidthInPixels(valueStr, fontVal);
        var badgeTxtW = dc.getTextWidthInPixels(badgeStr, fontBadge);
        var badgeTxtH = dc.getFontHeight(fontBadge);
        var badgeBoxH = badgeTxtH + (2 * padBadgeY);
        var padBadgeX = (badgeBoxH * 0.42).toNumber();
        if (padBadgeX < 7) {
            padBadgeX = 7;
        }
        var badgeBoxW = badgeTxtW + (2 * padBadgeX);
        if (badgeBoxW < badgeBoxH) {
            badgeBoxW = badgeBoxH;
        }
        var groupW = valW + gap + badgeBoxW;

        if (groupW > maxAllowedW) {
            if (fontVal == Graphics.FONT_NUMBER_MEDIUM) {
                fontVal = Graphics.FONT_NUMBER_MILD;
                fontBadge = Graphics.FONT_TINY;
            } else if (fontVal == Graphics.FONT_NUMBER_MILD) {
                fontVal = Graphics.FONT_LARGE;
                fontBadge = Graphics.FONT_XTINY;
            }
            valW = dc.getTextWidthInPixels(valueStr, fontVal);
            badgeTxtW = dc.getTextWidthInPixels(badgeStr, fontBadge);
            badgeTxtH = dc.getFontHeight(fontBadge);
            badgeBoxH = badgeTxtH + (2 * padBadgeY);
            padBadgeX = (badgeBoxH * 0.42).toNumber();
            if (padBadgeX < 6) {
                padBadgeX = 6;
            }
            badgeBoxW = badgeTxtW + (2 * padBadgeX);
            if (badgeBoxW < badgeBoxH) {
                badgeBoxW = badgeBoxH;
            }
            groupW = valW + gap + badgeBoxW;
        }

        var startX = centerX - (groupW / 2);
        var valX = startX;
        var badgeX = valX + valW + gap;

        var valFontH = dc.getFontHeight(fontVal);
        var valY = centerY - (valFontH / 2);
        var badgeY = valY + ((valFontH - badgeBoxH) / 2);

        // Draw Value
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(valX, valY, fontVal, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

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

    // =============================================================
    // Helper: Subtle Top Clock for Full Watch Screens
    // =============================================================
    private function drawTopClock(dc as Graphics.Dc, cx as Number, topY as Number) as Void {
        try {
            var clock = System.getClockTime();
            var is24h = true;
            var devSettings = System.getDeviceSettings();
            if (devSettings has :is24Hour) {
                is24h = devSettings.is24Hour;
            }
            var timeStr;
            if (is24h) {
                timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
            } else {
                var h = clock.hour;
                var ampm = (h >= 12) ? "PM" : "AM";
                h = h % 12;
                if (h == 0) { h = 12; }
                timeStr = Lang.format("$1$:$2$ $3$", [h, clock.min.format("%02d"), ampm]);
            }
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, topY, Graphics.FONT_XTINY, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        } catch (e) {}
    }
}
