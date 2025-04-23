import Toybox.Lang;
using Toybox.Communications;
using Toybox.Application.Storage;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;


class TrackerModel{
    var SERVER_URL = "https://api.routechoices.com";
    var deviceId = null;
    var isRequestingDeviceID = false;
    var positions = {};
    var isSending = false;
    var isConnectedTs = 0;
    var fromIdx = 0;
    var toIdx = 0;
    var apiKey = "";

    function initialize() {
        deviceId = Storage.getValue("device-id");
        var jsonSecrets = Application.loadResource(Rez.JsonData.jsonSecrets);
        apiKey = jsonSecrets["apiKey"];
        if (deviceId != null) {
            System.println("Device ID set" + deviceId);
        } else {
            System.println("Device ID not set");
            requestDeviceId();
        }
    }

    function onDeviceId(code as Number, data as Dictionary?) as Void {
        isRequestingDeviceID = false;
        if (code == 200 || code == 201) {
            System.println("Device ID Request Successful.");
            setDeviceId(data.get("device_id"));
        } else {
            System.println("Device ID Request Failed " + code.toString());
            requestDeviceId();
        }
    }

    function requestDeviceId() {
        if(isRequestingDeviceID) {
            return ;
        }
        System.println("Requesting Device ID");
        isRequestingDeviceID = true;
        var url = SERVER_URL + "/device/";
        var params = null;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Accept" => "application/json",
                "Authorization" => "Bearer " + apiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, params, options, method(:onDeviceId));
    }

    function setDeviceId(id) {
        if (id == null or id == "") {
            return;
        }
        deviceId = id;
        Storage.setValue("device-id", id);
    }

    function onPosition(info) {
        if (info.currentLocation) {
            positions.put(positions.size(), [Time.now().value(), info.currentLocation.toDegrees()]);
        }
    }

    function onSent(code as Number, data as Dictionary?) as Void {
        isSending = false;
        if(code == 200 || code == 201) {
            isConnectedTs = Time.now().value();
            var vals = positions.values();
            var newPositions = {};
            for (var i = 0; i < vals.size(); i++) {
                if (i < fromIdx || i >= toIdx) {
                    newPositions.put(newPositions.size(), vals[i]);
                }
            }
            positions = newPositions;
            if (fromIdx > 0) {
                sendBuffer();
            }
        }
    }
    
    function sendBuffer() {
        if(deviceId == null || isSending || positions.size() == 0) {
            return;
        }
        isSending = true;
        var t = "";
        var lat = "";
        var lon = "";
        toIdx = positions.size();
        fromIdx = toIdx - 5;
        if (fromIdx < 0) {
            fromIdx = 0;
        }
        for (var i = fromIdx; i < toIdx; i++) {
            t += positions[i][0].toString() + ",";
            lat += positions[i][1][0].toString() + ",";
            lon += positions[i][1][1].toString() + ",";
        }
        var params = {
            "device_id" => deviceId,
            "timestamps" => t,
            "latitudes" => lat,
            "longitudes" => lon,
        };
        var url = SERVER_URL + "/locations/";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Accept" => "application/json",
                "Authorization" => "Bearer " + apiKey
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        var responseCallback = method(:onSent);
        Communications.makeWebRequest(url, params, options, responseCallback);
    }
}
