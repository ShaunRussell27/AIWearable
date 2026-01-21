import Toybox.Graphics;
import Toybox.WatchUi;

//class AIWearableView extends WatchUi.View {

    //function initialize() {
      //  View.initialize();
    //}

    // Load your resources here
    //function onLayout(dc as Dc) as Void {
       // setLayout(Rez.Layouts.MainLayout(dc));
    //}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    //function onShow() as Void {
    //}

    // Update the view
    //function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
      //  View.onUpdate(dc);
    //}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    //function onHide() as Void {
   // }

//}

using Toybox.WatchUi as Ui;
using Toybox.Graphics as G;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Application.Storage as Storage;
using Toybox.Lang as Lang;


class AIWearableView extends Ui.View {

    var hr = 0;
    var stress = 0;
    var lastRecordTime = 0;
    var readingInterval = 300; // Record every 5 minutes for testing

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateKey = Lang.format("hr_$1$_$2$_$3$", [info.year, info.month, info.day]);
        var readings = Storage.getValue(dateKey);
        Sys.println("Stored samples: " + (readings != null ? readings.size() : 0));
                // Request frequent screen updates
        Ui.requestUpdate();
                // Uncomment to run unit tests on app launch
        var tests = new AIWearableTests();
        tests.runAllTests();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(G.COLOR_BLACK, G.COLOR_BLACK);
        dc.clear();

        // Get heart rate from history
        var hrHistory = ActivityMonitor.getHeartRateHistory(null, true);
        if (hrHistory != null) {
            var sample = hrHistory.next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) { 
                hr = sample.heartRate;
            }
        } else {
           hr = 75; // Test data for simulator
        }

        // Record reading every interval
        var now = Time.now().value();
        if (now - lastRecordTime >= readingInterval) {
            recordReading(hr, stress);
            lastRecordTime = now;
        }

        dc.setColor(G.COLOR_WHITE, G.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 60, G.FONT_LARGE,
            "HR: " + hr, G.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth()/2, 120, G.FONT_LARGE,
            "Stress: " + stress, G.TEXT_JUSTIFY_CENTER);
        
        // Force continuous updates
        Ui.requestUpdate();
    }

    function recordReading(heartRate as Lang.Number, stressLevel as Lang.Number) as Void {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Create timestamp
        var timestamp = Lang.format("$1$:$2$:$3$", 
            [info.hour, info.min, info.sec]);
        
        // Create reading object
        var reading = {
            "timestamp" => timestamp,
            "heartRate" => heartRate,
            "stress" => stressLevel
        };
        
        // Get or create today's readings
        var dateKey = Lang.format("hr_$1$_$2$_$3$", 
            [info.year, info.month, info.day]);
        
        var dailyReadings = Storage.getValue(dateKey) as Lang.Array<Lang.Dictionary>;
        if (dailyReadings == null) {
            dailyReadings = [] as Lang.Array<Lang.Dictionary>;
        }
        
        dailyReadings.add(reading);
        Storage.setValue(dateKey, dailyReadings);
        
        // Print JSON after every save
        var exporter = new DataExporter();
        Sys.println(exporter.exportTodayAsJSON());
    }

    function onHide() as Void {
    }
}