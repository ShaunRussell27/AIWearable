using Toybox.Application.Storage as Storage;
// Removed Toybox.IO as it is not supported on vivoactive5
using Toybox.Time as Time;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

class DataExporter {

    const PENDING_UPLOAD_KEY = "pending_upload_queue";

    function exportTodayAsJSON() as Lang.String {
        // Get current date and time
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        // Generate storage key based on current date (format: hr_YYYY_M_D)
        var dateKey = Lang.format("hr_$1$_$2$_$3$", [info.year, info.month, info.day]);
        // Retrieve stored readings array from device storage
        var readings = Storage.getValue(dateKey) as Lang.Array<Lang.Dictionary>;
        // Build JSON string
        var json = "{\n";
        json += "  \"date\": \"" + info.year + "-" + info.month + "-" + info.day + "\",\n";
        json += "  \"readings\": [\n";
        // Iterate through readings and format each as JSON object
        if (readings != null) {
            for (var i = 0; i < readings.size(); i++) {
                var reading = readings[i];
                json += "    {\n";
                json += "      \"timestamp\": \"" + reading["timestamp"] + "\",\n";
                json += "      \"heartRate\": " + reading["heartRate"] + ",\n";
                json += "      \"restingHeartRate\": " + reading["restingHeartRate"] + ",\n";
                json += "      \"vo2Max\": " + reading["vo2Max"] + ",\n";
                json += "      \"trainingStatus\": \"" + reading["trainingStatus"] + "\"\n";
                json += "    }";
                if (i < readings.size() - 1) { json += ","; }
                json += "\n";
            }
        }
        // Close JSON structure and return
        json += "  ]\n";
        json += "}\n";
        return json;
    }

    function saveToFile() as Lang.Boolean {
        try {
            var json = exportTodayAsJSON();
            var now = Time.now();
            var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            var backupKey = Lang.format("backup_$1$_$2$_$3$", 
                [info.year, info.month, info.day]);
            
            // Store JSON as backup in device storage instead of file
            Storage.setValue(backupKey, json);
            
            Sys.println("✓ Data saved to device storage");
            return true;
        } catch (e) {
            Sys.println("✗ Export failed: " + e.getErrorMessage());
            return false;
        }
    }

    function uploadToServer(serverUrl as Lang.String) as Lang.Boolean {
        try {
            var queueObj = Storage.getValue(PENDING_UPLOAD_KEY);
            var pendingReadings = queueObj as Lang.Array<Lang.Dictionary>;
            if (queueObj == null || pendingReadings == null || pendingReadings.size() == 0) {
                Sys.println("ℹ No pending readings to upload");
                return true;
            }

            var now = Time.now();
            var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);

            var headers = {
                "Content-Type" => "application/json"
            } as Lang.Dictionary<Lang.String, Lang.String>;

            var payload = {
                "date" => Lang.format("$1$-$2$-$3$", [info.year, info.month, info.day]),
                "readings" => pendingReadings
            } as Lang.Dictionary<Lang.Object, Lang.Object>;
            
            var options = {
                :method => Comm.HTTP_REQUEST_METHOD_POST,
                :headers => headers,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            } as Lang.Dictionary;
            
            Comm.makeWebRequest(serverUrl, payload, options, method(:onUploadResponse));
            Sys.println("✓ Uploading " + pendingReadings.size() + " queued readings...");
            return true;
        } catch (e) {
            Sys.println("✗ Upload failed: " + e.getErrorMessage());
            return false;
        }
    }

    function onUploadResponse(responseCode as Lang.Number, responseData as Null or Lang.Dictionary or Lang.String) as Void {
        if (responseCode >= 200 && responseCode < 300) {
            Sys.println("✓ Server accepted data (" + responseCode + ")");
            Storage.deleteValue(PENDING_UPLOAD_KEY);
            Sys.println("✓ Cleared pending upload queue");
        } else {
            Sys.println("✗ Server error: " + responseCode);
        }
    }
}