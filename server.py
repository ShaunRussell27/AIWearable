"""
Flask server for AIWearable health data collection and AI model access
Stores watch health data and serves it to AI models via REST API
"""

from flask import Flask, request, jsonify
from datetime import datetime
import json
import os
from pathlib import Path

app = Flask(__name__)

# Directory to store received data
DATA_DIR = "health_data"
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

# In-memory storage for all data
all_readings = []


@app.route('/api/health-data', methods=['POST'])
def receive_health_data():
    """
    Receive JSON health data from the watch
    Expected format:
    {
        "date": "2026-1-21",
        "readings": [
            {
                "timestamp": "10:30:45",
                "heartRate": 75,
                "restingHeartRate": 60,
                "vo2Max": 45.5,
                "trainingStatus": "Active"
            }
        ]
    }
    """
    try:
        # Get raw JSON from request
        data = request.get_json() or request.get_data(as_text=True)
        
        if isinstance(data, str):
            data = json.loads(data)
        
        print(f"\n{'='*50}")
        print(f"✓ Received data from watch")
        print(f"  Date: {data.get('date')}")
        readings = data.get('readings', [])
        print(f"  Readings: {len(readings)} samples")
        
        # Add to in-memory storage
        for reading in readings:
            reading_entry = {
                "date": data.get('date'),
                "timestamp": reading.get('timestamp'),
                "heartRate": reading.get('heartRate'),
                "restingHeartRate": reading.get('restingHeartRate'),
                "vo2Max": reading.get('vo2Max'),
                "trainingStatus": reading.get('trainingStatus')
            }
            all_readings.append(reading_entry)
        
        # Save to file as backup
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = os.path.join(DATA_DIR, f"reading_{timestamp}.json")
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"  Saved to: {filename}")
        print(f"  Total readings in memory: {len(all_readings)}")
        print(f"{'='*50}\n")
        
        # Return success response
        response = {
            "status": "success",
            "message": "Data received and stored",
            "samples_received": len(readings),
            "total_samples": len(all_readings)
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        print(f"✗ Error receiving data: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route('/api/status', methods=['GET'])
def server_status():
    """Health check endpoint"""
    return jsonify({
        "status": "Server running",
        "timestamp": datetime.now().isoformat(),
        "total_readings": len(all_readings)
    }), 200


@app.route('/api/data', methods=['GET'])
def get_all_data():
    """
    Retrieve all stored data for AI model
    Returns all readings in memory with metadata
    """
    try:
        # Group by date
        data_by_date = {}
        for reading in all_readings:
            date = reading['date']
            if date not in data_by_date:
                data_by_date[date] = []
            data_by_date[date].append(reading)
        
        response = {
            "status": "success",
            "total_readings": len(all_readings),
            "dates": len(data_by_date),
            "data": data_by_date,
            "readings": all_readings  # Flat list for easy access
        }
        
        return jsonify(response), 200
    
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route('/api/data/latest', methods=['GET'])
def get_latest_data():
    """Get the most recent readings"""
    try:
        limit = request.args.get('limit', 10, type=int)
        latest = all_readings[-limit:] if all_readings else []
        
        return jsonify({
            "status": "success",
            "limit": limit,
            "readings": latest
        }), 200
    
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route('/api/data/stats', methods=['GET'])
def get_data_stats():
    """Get statistics about collected data"""
    try:
        if not all_readings:
            return jsonify({
                "status": "success",
                "total_readings": 0,
                "heart_rates": [],
                "stress_levels": []
            }), 200
        
        heart_rates = [r['heartRate'] for r in all_readings if r.get('heartRate') is not None]
        stress_levels = [r['stress'] for r in all_readings if r.get('stress') is not None]
        
        stats = {
            "status": "success",
            "total_readings": len(all_readings),
            "heart_rate": {
                "min": min(heart_rates) if heart_rates else None,
                "max": max(heart_rates) if heart_rates else None,
                "avg": sum(heart_rates) / len(heart_rates) if heart_rates else None
            },
            "stress": {
                "min": min(stress_levels) if stress_levels else None,
                "max": max(stress_levels) if stress_levels else None,
                "avg": sum(stress_levels) / len(stress_levels) if stress_levels else None
            }
        }
        
        return jsonify(stats), 200
    
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 400


if __name__ == '__main__':
    # Local development only
    print("\n" + "="*50)
    print("AIWearable Server Starting")
    print("="*50)
    print(f"Data directory: {os.path.abspath(DATA_DIR)}")
    print(f"Server running on: http://0.0.0.0:5000")
    print("\nAPI Endpoints:")
    print("  POST /api/health-data    - Receive data from watch")
    print("  GET  /api/status         - Check server health")
    print("  GET  /api/data           - Get all stored data (for AI model)")
    print("  GET  /api/data/latest    - Get latest N readings")
    print("  GET  /api/data/stats     - Get data statistics")
    print("="*50 + "\n")
    app.run(host='0.0.0.0', port=5000, debug=True)
