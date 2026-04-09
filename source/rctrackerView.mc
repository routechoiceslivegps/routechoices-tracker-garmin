import Toybox.Activity;
import Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Time;

class rctrackerView extends WatchUi.SimpleDataField {
    var model;
    
    function initialize() {
        SimpleDataField.initialize();
        model = new TrackerModel();
        label = "RouteChoices";
    }

    function compute(info as Info) as Numeric or Time.Duration or String or Null {
        if (model.deviceId == null) {
            return "No Device ID";
        }
        model.onPosition(info);
        var timeSinceLastPush = Time.now().value() - model.lastConnectedTs;
        if (timeSinceLastPush >= 5) {
            model.sendBuffer();
        }
        var isOnline = timeSinceLastPush < 30;
        return model.deviceId + " " + (isOnline ? "LIVE" : "OFFLINE");
    }
}
