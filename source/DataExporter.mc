using Toybox.Application.Storage as Storage;
// Removed Toybox.IO as it is not supported on vivoactive5
using Toybox.Time as Time;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

class DataExporter {

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
                json += "      \"stress\": " + reading["stress"] + "\n";
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
            var json = exportTodayAsJSON();
            
            var body = ({
                :data => json
            } as Lang.Dictionary<Lang.Object, Lang.Object>);
            
            var headers = {
                "Content-Type" => "application/json"
            } as Lang.Dictionary<Lang.String, Lang.String>;
            
            var options = {
                :method => Comm.HTTP_REQUEST_METHOD_POST,
                :headers => headers,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            } as Lang.Dictionary;
            
            Comm.makeWebRequest(serverUrl, body, options, method(:onUploadResponse));
            Sys.println("✓ Uploading data to server...");
            return true;
        } catch (e) {
            Sys.println("✗ Upload failed: " + e.getErrorMessage());
            return false;
        }
    }

    function onUploadResponse(responseCode as Lang.Number, responseData as Null or Lang.Dictionary or Lang.String) as Void {
        if (responseCode == 200) {
            Sys.println("✓ Server accepted data (200 OK)");
        } else {
            Sys.println("✗ Server error: " + responseCode);
        }
    }
}