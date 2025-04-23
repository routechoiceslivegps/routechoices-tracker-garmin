import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class rctrackerView extends WatchUi.SimpleDataField {
    var model;

    function initialize() {
        SimpleDataField.initialize();
        model = new TrackerModel();
        label = "Routechoices";
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (model.deviceId != "") {
            model.onPosition(info);
            if (model.positions.size() >= 5) {
                model.sendBuffer();
            }
            var status = "OFFLINE";
            if(Time.now().value() - model.isConnectedTs < 30) {
                status = "LIVE";
            }
            return model.deviceId + " " + status;
        }
        return "No Device ID";
    }
}
