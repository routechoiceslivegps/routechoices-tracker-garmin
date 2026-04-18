import Toybox.Lang;
using Toybox.Communications;
using Toybox.Application.Storage;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;


class TrackerModel{
    var API_KEY = "";
    var SERVER_URL = "https://api.routechoices.com";
    var deviceId = null;
    var lastConnectedTs = 0;
    var isRequestingDeviceID = false;
    var isSendingData = false;
    var positions = {};

    function initialize() {
        var jsonSecrets = Application.loadResource(Rez.JsonData.jsonSecrets) as Dictionary;
        API_KEY = jsonSecrets["apiKey"];
        var storedDeviceId = Storage.getValue("device-id");
        if (storedDeviceId == null || storedDeviceId == "") {
            System.println("Device ID not set");
            requestDeviceId();
        } else {
            setDeviceId(storedDeviceId);
            System.println("Device ID set");
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
        isRequestingDeviceID = true;
        System.println("Requesting Device ID");
        var url = SERVER_URL + "/device/";
        var params = null;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Accept" => "application/json",
                "Authorization" => "Bearer " + API_KEY
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
            positions.put(Time.now().value(), info.currentLocation.toDegrees());
        }
        // Never keep more than 6 minutes worth of data to avoid memory issues
        var positionCount = positions.size();
        if (positionCount > 360) {
            var timestamps = positions.keys();
            timestamps.sort(null);
            var oldTimestamps = (timestamps as Array).slice(0, positionCount - 300);
            for (var i = 0; i < oldTimestamps.size(); i++) {
                var ts = oldTimestamps[i];
                positions.remove(ts);
            }
        }
    }

    function onSent(code as Number, data as Dictionary?, tsSent as Array) as Void {
        isSendingData = false;
        if(code == 200 || code == 201) {
            lastConnectedTs = Time.now().value();
            for (var i = 0; i < tsSent.size(); i++) {
                var ts = (tsSent as Array)[i];
                positions.remove(ts);
            }
            if (positions.size() > 0) {
                sendBuffer();
            }
        }
    }
    
    function sendBuffer() {
        if(deviceId == null || isSendingData || positions.size() == 0) {
            return;
        }
        isSendingData = true;
        
        var t = "";
        var lat = "";
        var lon = "";

        var timestamps = positions.keys() as Array;
        timestamps.sort(null);
        var tsSent = timestamps.slice(-15, null);
        for (var i = 0; i < tsSent.size(); i++) {
            var ts = tsSent[i];
            var coords = positions.get(ts) as Array;
            t += ts.toString() + ",";
            lat += coords[0].toString() + ",";
            lon += coords[1].toString() + ",";
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
                "Authorization" => "Bearer " + API_KEY
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :context => tsSent,
        };
        var responseCallback = method(:onSent);
        Communications.makeWebRequest(url, params, options, responseCallback);
    }
}
