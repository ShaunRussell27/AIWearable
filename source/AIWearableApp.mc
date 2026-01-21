import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi ;

using Toybox.WatchUi as Ui;
class AIWearableApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new AIWearableView(), new AIWearableDelegate() ];
    }

}

function getApp() as AIWearableApp {
    return Application.getApp() as AIWearableApp;
}