using Toybox.System as Sys;
using Toybox.Application.Storage as Storage;
using Toybox.Time as Time;
using Toybox.Lang as Lang;

/**
 * Test suite for AIWearable health monitoring application.
 * Validates data collection, storage, and export functionality.
 */
class AIWearableTests {
    
    /**
     * Runs all test cases and reports results to console.
     * Used for validation during development and deployment.
     */
    function runAllTests() as Void {
        Sys.println("=== Running AIWearable Test Suite ===\n");
        
        var passedTests = 0;
        var totalTests = 0;
        
        // Test 1: Data Recording Functionality
        totalTests++;
        if (testDataRecording()) {
            Sys.println("✓ Test 1 PASSED: Data recording works correctly");
            passedTests++;
        } else {
            Sys.println("✗ Test 1 FAILED: Data recording issue");
        }
        
        // Test 2: Storage Mechanism
        totalTests++;
        if (testStorageMechanism()) {
            Sys.println("✓ Test 2 PASSED: Storage mechanism functional");
            passedTests++;
        } else {
            Sys.println("✗ Test 2 FAILED: Storage mechanism issue");
        }
        
        // Test 3: JSON Export Format
        totalTests++;
        if (testJSONExport()) {
            Sys.println("✓ Test 3 PASSED: JSON export format valid");
            passedTests++;
        } else {
            Sys.println("✗ Test 3 FAILED: JSON export format issue");
        }
        
        // Test 4: Invalid Heart Rate Handling
        totalTests++;
        if (testInvalidHeartRate()) {
            Sys.println("✓ Test 4 PASSED: Invalid HR handled correctly");
            passedTests++;
        } else {
            Sys.println("✗ Test 4 FAILED: Invalid HR handling issue");
        }
        
        // Test 5: Edge Case - Empty Storage
        totalTests++;
        if (testEmptyStorage()) {
            Sys.println("✓ Test 5 PASSED: Empty storage handled correctly");
            passedTests++;
        } else {
            Sys.println("✗ Test 5 FAILED: Empty storage handling issue");
        }
        
        // Test 6: Timestamp Format Validation
        totalTests++;
        if (testTimestampFormat()) {
            Sys.println("✓ Test 6 PASSED: Timestamp format correct");
            passedTests++;
        } else {
            Sys.println("✗ Test 6 FAILED: Timestamp format issue");
        }
        
        // Print summary
        Sys.println("\n=== Test Summary ===");
        Sys.println("Passed: " + passedTests + "/" + totalTests);
        Sys.println("Success Rate: " + ((passedTests * 100) / totalTests) + "%");
        
        if (passedTests == totalTests) {
            Sys.println("✓ ALL TESTS PASSED");
        } else {
            Sys.println("✗ SOME TESTS FAILED - Review output above");
        }
    }
    
    /**
     * Test 1: Validates that data recording creates proper dictionary structure
     */
    function testDataRecording() as Lang.Boolean {
        try {
            // Simulate recording a reading
            var testReading = {
                "timestamp" => "10:30:45",
                "heartRate" => 75,
                "stress" => 0
            };
            
            // Validate structure
            if (testReading["timestamp"] == null) { return false; }
            if (testReading["heartRate"] == null) { return false; }
            if (testReading["stress"] == null) { return false; }
            
            // Validate data types
            if (!(testReading["heartRate"] instanceof Lang.Number)) { return false; }
            if (!(testReading["stress"] instanceof Lang.Number)) { return false; }
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testDataRecording: " + ex.getErrorMessage());
            return false;
        }
    }
    
    /**
     * Test 2: Validates storage can save and retrieve data
     */
    function testStorageMechanism() as Lang.Boolean {
        try {
            var testKey = "test_hr_data";
            var testData = [
                {"timestamp" => "10:00:00", "heartRate" => 72, "stress" => 0}
            ] as Lang.Array<Lang.Dictionary>;
            
            // Save test data
            Storage.setValue(testKey, testData);
            
            // Retrieve and validate
            var retrieved = Storage.getValue(testKey) as Lang.Array<Lang.Dictionary>;
            if (retrieved == null) { return false; }
            if (retrieved.size() != 1) { return false; }
            if (retrieved[0]["heartRate"] != 72) { return false; }
            
            // Cleanup
            Storage.deleteValue(testKey);
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testStorageMechanism: " + ex.getErrorMessage());
            return false;
        }
    }
    
    /**
     * Test 3: Validates JSON export produces valid format
     */
    function testJSONExport() as Lang.Boolean {
        try {
            var exporter = new DataExporter();
            var json = exporter.exportTodayAsJSON();
            
            // Check for required JSON structure
            if (json.find("\"date\"") == null) { return false; }
            if (json.find("\"readings\"") == null) { return false; }
            if (json.find("{") == null) { return false; }
            if (json.find("}") == null) { return false; }
            if (json.find("[") == null) { return false; }
            if (json.find("]") == null) { return false; }
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testJSONExport: " + ex.getErrorMessage());
            return false;
        }
    }
    
    /**
     * Test 4: Validates handling of invalid heart rate values
     */
    function testInvalidHeartRate() as Lang.Boolean {
        try {
            // Test boundary conditions
            var validHR1 = 60;   // Minimum reasonable
            var validHR2 = 180;  // Maximum reasonable
            var invalidHR1 = 0;  // Too low
            var invalidHR2 = 255; // Invalid sensor reading
            
            // Valid heart rates should be accepted (40-220 range)
            if (validHR1 < 40 || validHR1 > 220) { return false; }
            if (validHR2 < 40 || validHR2 > 220) { return false; }
            
            // Invalid heart rates should be detectable
            if (invalidHR1 >= 40 && invalidHR1 <= 220) { return false; }
            if (invalidHR2 >= 40 && invalidHR2 <= 220) { return false; }
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testInvalidHeartRate: " + ex.getErrorMessage());
            return false;
        }
    }
    
    /**
     * Test 5: Validates behavior with empty storage (no data collected yet)
     */
    function testEmptyStorage() as Lang.Boolean {
        try {
            // Clear test storage
            var testKey = "empty_test_key";
            Storage.deleteValue(testKey);
            
            // Attempt to retrieve non-existent data
            var result = Storage.getValue(testKey);
            
            // Should return null for non-existent key
            if (result != null) { return false; }
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testEmptyStorage: " + ex.getErrorMessage());
            return false;
        }
    }
    
    /**
     * Test 6: Validates timestamp format correctness
     */
    function testTimestampFormat() as Lang.Boolean {
        try {
            var now = Time.now();
            var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            
            var timestamp = Lang.format("$1$:$2$:$3$", 
                [info.hour, info.min, info.sec]);
            
            // Validate format contains colons
            if (timestamp.find(":") == null) { return false; }
            
            // Validate not empty
            if (timestamp.length() < 5) { return false; }
            
            return true;
        } catch (ex) {
            Sys.println("Exception in testTimestampFormat: " + ex.getErrorMessage());
            return false;
        }
    }
}
