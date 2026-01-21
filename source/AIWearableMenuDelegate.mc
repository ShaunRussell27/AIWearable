import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class AIWearableMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :export_data) {
            var exporter = new DataExporter();
            var success = exporter.saveToFile();
            if (success) {
                System.println("✓ Data exported successfully");
            } else {
                System.println("✗ Data export failed");
            }
        } else if (item == :upload_data) {
            var exporter = new DataExporter();
            exporter.uploadToServer("https://aiwearable-server.railway.app/api/health-data");
        } else if (item == :item_2) {
            System.println("item 2");
        }
    }

}