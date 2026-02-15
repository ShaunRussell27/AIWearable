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
    const RUN_TESTS_ON_START = false;
    const METRIC_COUNT = 4;
    const MAX_PENDING_UPLOADS = 3000;
    const MAX_TRACKED_DAYS = 7;
    const PENDING_UPLOAD_KEY = "pending_upload_queue";
    const TRACKED_DAY_KEYS = "tracked_day_keys";
    const SERVER_UPLOAD_URL = "https://aiwearable-production.up.railway.app/api/health-data";
    const LAST_UPLOAD_ATTEMPT_KEY = "last_upload_attempt_epoch";
    const AUTO_UPLOAD_COOLDOWN_SEC = 1800;

    // Scrolling metric index
    var currentMetricIndex = 0;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateKey = Lang.format("hr_$1$_$2$_$3$", [info.year, info.month, info.day]);
        var readings = Storage.getValue(dateKey);
        Sys.println("Stored samples: " + (readings != null ? readings.size() : 0));
        attemptAutoUpload();
                // Request frequent screen updates
        Ui.requestUpdate();
        if (RUN_TESTS_ON_START) {
            var tests = new AIWearableTests();
            tests.runAllTests();
        }
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
            if (profile has :restingHeartRate && profile.restingHeartRate != null) {
                restingHr = profile.restingHeartRate;
            } else {
                restingHr = 60;
            }

            // Try vo2MaxRunning first, fall back to vo2Max if not available
            if (profile has :vo2MaxRunning && profile.vo2MaxRunning != null) {
                vo2max = profile.vo2MaxRunning;
            } else if (profile has :vo2Max && profile.vo2Max != null) {
                vo2max = profile.vo2Max;
            } else {
                vo2max = 45.0;
            }
        } else {
            restingHr = 60;
            vo2max = 45.0;
        }

        // Estimate training status based on heart rate
        // Simple heuristic: if HR > resting HR + 20, user is active
        if (hr > restingHr + 20) {
            trainingStatus = "Active";
        } else {
            trainingStatus = "Rest";
        }

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
        var label = "";
        var valueStr = "";
        var unit = "";

        if (currentMetricIndex == 0) {
            label = "HR";
            valueStr = hr.toString();
            unit = "bpm";
        } else if (currentMetricIndex == 1) {
            label = "Resting HR";
            valueStr = restingHr.toString();
            unit = "bpm";
        } else if (currentMetricIndex == 2) {
            label = "VO2 Max";
            valueStr = Lang.format("$1$.1f", [vo2max]);
            unit = "mL/kg/min";
        } else {
            label = "Training Status";
            valueStr = trainingStatus;
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
        var pageIndicator = (currentMetricIndex + 1) + "/" + METRIC_COUNT;
        dc.drawText(dc.getWidth()/2, dc.getHeight() - 20, G.FONT_SMALL,
            pageIndicator, G.TEXT_JUSTIFY_CENTER);
    }

    function getMetricCount() as Lang.Number {
        return METRIC_COUNT;
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

        var dateStr = Lang.format("$1$-$2$-$3$", [info.year, info.month, info.day]);
        
        var dailyReadingsObj = Storage.getValue(dateKey);
        var dailyReadings = dailyReadingsObj as Lang.Array<Lang.Dictionary>;
        if (dailyReadingsObj == null || dailyReadings == null) {
            dailyReadings = [] as Lang.Array<Lang.Dictionary>;
        }
        
        dailyReadings.add(reading);
        Storage.setValue(dateKey, dailyReadings);

        trackDayKey(dateKey);
        queuePendingUpload(reading, dateStr);
        
        // Print JSON after every save
        var exporter = new DataExporter();
        Sys.println(exporter.exportTodayAsJSON());
    }

    function trackDayKey(dateKey as Lang.String) as Void {
        var trackedObj = Storage.getValue(TRACKED_DAY_KEYS);
        var tracked = trackedObj as Lang.Array<Lang.String>;
        if (trackedObj == null || tracked == null) {
            tracked = [] as Lang.Array<Lang.String>;
        }

        var exists = false;
        for (var i = 0; i < tracked.size(); i++) {
            if (tracked[i] == dateKey) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            tracked.add(dateKey);
        }

        while (tracked.size() > MAX_TRACKED_DAYS) {
            var oldestKey = tracked[0];
            tracked.remove(oldestKey);
            Storage.deleteValue(oldestKey);
        }

        Storage.setValue(TRACKED_DAY_KEYS, tracked);
    }

    function queuePendingUpload(reading as Lang.Dictionary, dateStr as Lang.String) as Void {
        var queueObj = Storage.getValue(PENDING_UPLOAD_KEY);
        var queue = queueObj as Lang.Array<Lang.Dictionary>;
        if (queueObj == null || queue == null) {
            queue = [] as Lang.Array<Lang.Dictionary>;
        }

        var queuedReading = {
            "date" => dateStr,
            "timestamp" => reading["timestamp"],
            "heartRate" => reading["heartRate"],
            "restingHeartRate" => reading["restingHeartRate"],
            "vo2Max" => reading["vo2Max"],
            "trainingStatus" => reading["trainingStatus"]
        };

        queue.add(queuedReading);

        while (queue.size() > MAX_PENDING_UPLOADS) {
            queue.remove(queue[0]);
        }

        Storage.setValue(PENDING_UPLOAD_KEY, queue);
    }

    function attemptAutoUpload() as Void {
        var nowEpoch = Time.now().value();
        var lastAttemptObj = Storage.getValue(LAST_UPLOAD_ATTEMPT_KEY);
        var lastAttempt = 0;
        if (lastAttemptObj != null) {
            lastAttempt = lastAttemptObj;
        }

        if (nowEpoch - lastAttempt < AUTO_UPLOAD_COOLDOWN_SEC) {
            return;
        }

        Storage.setValue(LAST_UPLOAD_ATTEMPT_KEY, nowEpoch);

        var exporter = new DataExporter();
        exporter.uploadToServer(SERVER_UPLOAD_URL);
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
            view.currentMetricIndex = (view.currentMetricIndex + 1) % view.getMetricCount();
            Ui.requestUpdate();
            return true;
        }
        
        // Up button scrolls to previous metric
        if (key == Ui.KEY_UP) {
            var metricCount = view.getMetricCount();
            view.currentMetricIndex = (view.currentMetricIndex - 1 + metricCount) % metricCount;
            Ui.requestUpdate();
            return true;
        }
        
        return false;
    }

    function onMenu() as Lang.Boolean {
        Ui.pushView(new Rez.Menus.MainMenu(), new AIWearableMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
}