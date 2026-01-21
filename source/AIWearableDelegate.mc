import Toybox.Lang;
import Toybox.WatchUi;

class AIWearableDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new AIWearableMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}