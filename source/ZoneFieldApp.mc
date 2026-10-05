import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ZoneFieldApp extends Application.AppBase {
    private var mView as ZoneFieldView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {}

    function onStop(state as Dictionary?) as Void {}

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        mView = new ZoneFieldView();
        return [mView as WatchUi.Views];
    }

    // Called when the user alters settings via Garmin Connect Mobile or Garmin Express
    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.loadSettings();
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as ZoneFieldApp {
    return Application.getApp() as ZoneFieldApp;
}
