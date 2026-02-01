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
using Toybox.UserProfile as UserProfile;


class AIWearableView extends Ui.View {

    var hr = 0;
    var restingHr = 0;
    var vo2max = 0.0;
    var trainingStatus = "N/A";
    
    var lastRecordTime = 0;
    var readingInterval = 300; // Record every 5 minutes for testing
    
    // Scrolling list metrics
    var currentMetricIndex = 0;
    var metrics = [
        { "label" => "HR", "value" => 0, "unit" => "bpm" },
        { "label" => "Resting HR", "value" => 0, "unit" => "bpm" },
        { "label" => "VO2 Max", "value" => 0.0, "unit" => "mL/kg/min" },
        { "label" => "Training Status", "value" => "N/A", "unit" => "" }
    ] as Lang.Array<Lang.Dictionary>;

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

        // Get user stats (resting HR, VO2 Max)
        var profile = UserProfile.getProfile();
        if (profile != null) {
            // Try vo2MaxRunning first, fall back to vo2Max if not available
            if (profile has :vo2MaxRunning && profile.vo2MaxRunning != null) {
                vo2max = profile.vo2MaxRunning;
            } else if (profile has :vo2Max && profile.vo2Max != null) {
                vo2max = profile.vo2Max;
            } else {
                vo2max = 45.0;
            }
        }

        // Estimate training status based on heart rate
        // Simple heuristic: if HR > resting HR + 20, user is active
        if (hr > restingHr + 20) {
            trainingStatus = "Active";
        } else {
            trainingStatus = "Rest";
        }

        // Update metrics array
        metrics[0]["value"] = hr;
        metrics[1]["value"] = restingHr;
        metrics[2]["value"] = vo2max;
        metrics[3]["value"] = trainingStatus;

        // Record reading every interval
        var now = Time.now().value();
        if (now - lastRecordTime >= readingInterval) {
            recordReading(hr, restingHr, vo2max, trainingStatus);
            lastRecordTime = now;
        }

        // Display scrolling metric
        drawMetricDisplay(dc);
        
        // Force continuous updates
        Ui.requestUpdate();
    }

    function drawMetricDisplay(dc as Dc) as Void {
        var metric = metrics[currentMetricIndex];
        var label = metric["label"] as Lang.String;
        var value = metric["value"];
        var unit = metric["unit"] as Lang.String;
        
        var valueStr = "";
        if (value instanceof Lang.Float) {
            valueStr = Lang.format("$1$.1f", [value]);
        } else if (value instanceof Lang.String) {
            valueStr = value as Lang.String;
        } else {
            valueStr = value.toString();
        }

        dc.setColor(G.COLOR_WHITE, G.COLOR_TRANSPARENT);
        
        // Draw metric label
        dc.drawText(dc.getWidth()/2, 40, G.FONT_MEDIUM,
            label, G.TEXT_JUSTIFY_CENTER);
        
        // Draw metric value (large)
        dc.drawText(dc.getWidth()/2, 85, G.FONT_LARGE,
            valueStr, G.TEXT_JUSTIFY_CENTER);
        
        // Draw unit
        if (unit.length() > 0) {
            dc.drawText(dc.getWidth()/2, 130, G.FONT_SMALL,
                unit, G.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw pagination indicator
        var pageIndicator = (currentMetricIndex + 1) + "/" + metrics.size();
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 20, G.FONT_SMALL,
            pageIndicator, G.TEXT_JUSTIFY_CENTER);
    }

    function recordReading(heartRate as Lang.Number, restingHeartRate as Lang.Number, vo2Max as Lang.Float, trainingStatus as Lang.String) as Void {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        // Create timestamp
        var timestamp = Lang.format("$1$:$2$:$3$", 
            [info.hour, info.min, info.sec]);
        
        // Create reading object
        var reading = {
            "timestamp" => timestamp,
            "heartRate" => heartRate,
            "restingHeartRate" => restingHeartRate,
            "vo2Max" => vo2Max,
            "trainingStatus" => trainingStatus
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

class AIWearableInputDelegate extends Ui.BehaviorDelegate {
    
    var view as AIWearableView;
    
    function initialize(viewRef as AIWearableView) {
        BehaviorDelegate.initialize();
        view = viewRef;
    }
    
    function onKey(keyEvent as Ui.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        
        // Down/Select button scrolls to next metric
        if (key == Ui.KEY_DOWN || key == Ui.KEY_ENTER) {
            view.currentMetricIndex = (view.currentMetricIndex + 1) % view.metrics.size();
            Ui.requestUpdate();
            return true;
        }
        
        // Up button scrolls to previous metric
        if (key == Ui.KEY_UP) {
            view.currentMetricIndex = (view.currentMetricIndex - 1 + view.metrics.size()) % view.metrics.size();
            Ui.requestUpdate();
            return true;
        }
        
        return false;
    }
}