using Toybox.Application.Storage as Storage;
using Toybox.IO as IO;
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
            var now = Time.now();
            var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            var filename = Lang.format("/AIWearable_$1$_$2$_$3$.json", 
                [info.year, info.month, info.day]);
            
            var json = exportTodayAsJSON();
            var file = IO.File.open(filename, IO.FILE_MODE_WRITE);
            file.write(json.toUtf8());
            file.close();
            
            Sys.println("✓ Data exported to: " + filename);
            return true;
        } catch (e) {
            Sys.println("✗ Export failed: " + e.getErrorMessage());
            return false;
        }
    }

    function uploadToServer(serverUrl as Lang.String) as Lang.Boolean {
        try {
            var json = exportTodayAsJSON();
            
            var headers = {
                "Content-Type" => "application/json"
            } as Lang.Dictionary<Lang.String, Lang.String>;
            
            var options = {
                :requestMethod => Comm.HTTP_REQUEST_METHOD_POST,
                :headers => headers,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            } as Lang.Dictionary<Lang.String, Lang.Object>;
            
            Comm.makeWebRequest(serverUrl, json, options, method(:onUploadResponse));
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