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
    // Dynamic adaptation: Pin arc stacked bar to the top bezel curve,
    // active segment radially thicker, indicator below it, hero value below.
    // =============================================================
    private function renderTopDome(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var screenW = width;
        try {
            var devSettings = System.getDeviceSettings();
            if (devSettings has :screenWidth && devSettings.screenWidth != null) {
                screenW = devSettings.screenWidth;
            }
        } catch (e) {}
        if (screenW < width) {
            screenW = width;
        }

        var R = (screenW / 2).toNumber();
        var cx = width / 2;
        var cy = R; // Center of circular display: y = 0 is display top apex
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Adaptive arc radius, stroke width, and pip sizes based on field height
        var arcR = R - 8;
        var penInactive = 8;
        var penActive = 14;
        var pipRadiusOuter = 5;
        var pipRadiusInner = 2;

        if (height < 90) {
            penInactive = 5;
            penActive = 8;
            pipRadiusOuter = 3;
            pipRadiusInner = 1;
            arcR = R - 6;
        } else if (height < 140) {
            penInactive = 6;
            penActive = 10;
            pipRadiusOuter = 4;
            pipRadiusInner = 2;
            arcR = R - 7;
        }

        // Calculate arc angle limits so endpoints remain gracefully inside the field
        var yMaxArc = height - 10;
        if (yMaxArc < 15) {
            yMaxArc = 15;
        }
        var sinMin = (R - yMaxArc).toFloat() / arcR.toFloat();
        if (sinMin < 0.5f) { sinMin = 0.5f; } // max 120° span (150° to 30°)
        if (sinMin > 0.95f) { sinMin = 0.95f; }

        var endAngle = 30;
        try {
            endAngle = Math.toDegrees(Math.asin(sinMin)).toNumber();
        } catch (e) {
            endAngle = 30;
        }
        if (endAngle < 30) { endAngle = 30; }
        if (endAngle > 75) { endAngle = 75; }

        var startAngle = 180 - endAngle;
        var totalAngle = startAngle - endAngle;
        var segAngles = view.mStats.computeSegmentWidths(totalAngle, activeZone, (height < 90) ? 8 : 12);

        var curAngle = startAngle;
        var actStartAngle = startAngle;
        var actSpanAngle = 0;

        // 1. Draw Pinned Top Arc Stacked Bar
        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var span = segAngles[i];
            if (span <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var nextAngle = curAngle - span;
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
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE, curAngle, nextAngle);

            curAngle = nextAngle;
        }

        // 2. Indicator Pip along the active arc segment
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actSpanAngle > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indAngle = actStartAngle.toFloat() - (progress * actSpanAngle.toFloat());
            var indRad = Math.toRadians(indAngle);

            var pipOffset = (penActive / 2) + ((height < 90) ? 3 : 4);
            var pipR = arcR - pipOffset;
            var pipX = cx + (pipR.toFloat() * Math.cos(indRad)).toNumber();
            var pipY = cy - (pipR.toFloat() * Math.sin(indRad)).toNumber();

            var pipCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : view.mZoneResult.color;
            dc.setColor(pipCol, pipCol);
            dc.fillCircle(pipX, pipY, pipRadiusOuter);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillCircle(pipX, pipY, pipRadiusInner);
        }

        // Reset pen width
        dc.setPenWidth(1);

        // 3. Hero Value + Inline Active Zone Badge
        var topUsed = (R - arcR) + (penActive / 2) + ((height < 90) ? 6 : 10);
        var availHeroH = height - topUsed - 3;
        if (availHeroH < 18) {
            availHeroH = 18;
        }
        var heroCenterY = topUsed + (availHeroH / 2);
        var maxW = (width * 0.82).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW, availHeroH);
    }

    // =============================================================
    // 2. Bottom Bowl Screen (Lower Half of Watch Face: OBSCURE_BOTTOM)
    // Dynamic adaptation: Pin arc stacked bar to the bottom bezel curve,
    // active segment radially thicker, indicator above it, hero value above.
    // =============================================================
    private function renderBottomBowl(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        width as Number,
        height as Number
    ) as Void {
        var screenW = width;
        try {
            var devSettings = System.getDeviceSettings();
            if (devSettings has :screenWidth && devSettings.screenWidth != null) {
                screenW = devSettings.screenWidth;
            }
        } catch (e) {}
        if (screenW < width) {
            screenW = width;
        }

        var R = (screenW / 2).toNumber();
        var cx = width / 2;
        var cy = height - R; // Center of circular display: y = height is display bottom apex
        var activeZone = view.mZoneResult.zoneIndex;
        var numZones = (view.mMetricType == 1) ? 7 : 5;

        // Adaptive arc radius, stroke width, and pip sizes based on field height
        var arcR = R - 8;
        var penInactive = 8;
        var penActive = 14;
        var pipRadiusOuter = 5;
        var pipRadiusInner = 2;

        if (height < 90) {
            penInactive = 5;
            penActive = 8;
            pipRadiusOuter = 3;
            pipRadiusInner = 1;
            arcR = R - 6;
        } else if (height < 140) {
            penInactive = 6;
            penActive = 10;
            pipRadiusOuter = 4;
            pipRadiusInner = 2;
            arcR = R - 7;
        }

        // Calculate arc angle limits so endpoints remain gracefully inside the field
        var yMinArc = 10;
        var sinMin = (R - height + yMinArc).toFloat() / arcR.toFloat();
        if (sinMin < 0.5f) { sinMin = 0.5f; } // max 120° span (210° to 330°)
        if (sinMin > 0.95f) { sinMin = 0.95f; }

        var angleOffset = 30;
        try {
            angleOffset = Math.toDegrees(Math.asin(sinMin)).toNumber();
        } catch (e) {
            angleOffset = 30;
        }
        if (angleOffset < 30) { angleOffset = 30; }
        if (angleOffset > 75) { angleOffset = 75; }

        var startAngle = 180 + angleOffset;
        var endAngle = 360 - angleOffset;
        var totalAngle = endAngle - startAngle;
        var segAngles = view.mStats.computeSegmentWidths(totalAngle, activeZone, (height < 90) ? 8 : 12);

        var curAngle = startAngle;
        var actStartAngle = startAngle;
        var actSpanAngle = 0;

        // 1. Draw Pinned Bottom Arc Stacked Bar
        for (var i = 0; i < numZones; i++) {
            var zNum = i + 1;
            var span = segAngles[i];
            if (span <= 0) {
                continue;
            }

            var segCol = view.mCalculator.getZoneColor(view.mMetricType, zNum);
            var nextAngle = curAngle + span;
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
            dc.drawArc(cx, cy, arcR, Graphics.ARC_COUNTER_CLOCKWISE, curAngle, nextAngle);

            curAngle = nextAngle;
        }

        // 2. Indicator Pip along the active arc segment
        var hasValidSignal = (view.mCurrentValue != null && view.mCurrentValue > 0);
        if (hasValidSignal && activeZone >= 1 && activeZone <= numZones && actSpanAngle > 0) {
            var progress = view.mZoneResult.zoneProgress;
            var indAngle = actStartAngle.toFloat() + (progress * actSpanAngle.toFloat());
            var indRad = Math.toRadians(indAngle);

            var pipOffset = (penActive / 2) + ((height < 90) ? 3 : 4);
            var pipR = arcR - pipOffset;
            var pipX = cx + (pipR.toFloat() * Math.cos(indRad)).toNumber();
            var pipY = cy - (pipR.toFloat() * Math.sin(indRad)).toNumber();

            var pipCol = (view.mFullBackgroundColor && activeZone > 0) ? Graphics.COLOR_WHITE : view.mZoneResult.color;
            dc.setColor(pipCol, pipCol);
            dc.fillCircle(pipX, pipY, pipRadiusOuter);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillCircle(pipX, pipY, pipRadiusInner);
        }

        // Reset pen width
        dc.setPenWidth(1);

        // 3. Hero Value + Inline Active Zone Badge
        var bottomUsed = (R - arcR) + (penActive / 2) + ((height < 90) ? 6 : 10);
        var availHeroH = height - bottomUsed - 3;
        if (availHeroH < 18) {
            availHeroH = 18;
        }
        var heroCenterY = 3 + (availHeroH / 2);
        var maxW = (width * 0.82).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW, availHeroH);
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

        // Reset pen width
        dc.setPenWidth(1);

        // Hero Value + Inline Active Zone Badge (Hero centered prominently)
        var heroCenterY = cy - 4;
        var maxW = (width * 0.85).toNumber();
        var availH = (height * 0.52).toNumber();
        drawHeroValueAndBadge(dc, view, cx, heroCenterY, maxW, availH);
    }

    // =============================================================
    // 4. Middle Band Screen (Multi-field horizontal slice / Center Strip)
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
        var padSide = (width > 250) ? 12 : 8;
        var barW = width - (2 * padSide);
        var barBottomY = height - 2;
        var baseBarH = (height > 90) ? 8 : ((height > 60) ? 6 : 4);
        var activeBarH = baseBarH + ((height > 60) ? 3 : 2);
        var minActiveW = (width > 250) ? 16 : 10;

        var segmentWidths = view.mStats.computeSegmentWidths(barW, activeZone, minActiveW);

        // 1. Bottom Stacked Bar
        var curX = padSide;
        var actStartX = padSide;
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
        var triH = (height < 60) ? 3 : 4;
        var triHalfW = (height < 60) ? 2 : 3;
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
        var heroAvailH = indBottomY - triH - 3;
        if (heroAvailH < 18) {
            heroAvailH = 18;
        }
        var heroCenterY = 2 + (heroAvailH / 2);
        var maxAllowedW = barW - 6;
        drawHeroValueAndBadge(dc, view, width / 2, heroCenterY, maxAllowedW, heroAvailH);
    }

    // =============================================================
    // Helper: Draw Hero Value (no unit) + Inline Active Zone Badge
    // Sized dynamically with FIELD HEIGHT AS PRIMARY PRIORITY
    // =============================================================
    private function drawHeroValueAndBadge(
        dc as Graphics.Dc,
        view as ZoneFieldView,
        centerX as Number,
        centerY as Number,
        maxAllowedW as Number,
        availH as Number
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
