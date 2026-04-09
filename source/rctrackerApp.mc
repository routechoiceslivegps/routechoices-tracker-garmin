import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application;

class rctrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new rctrackerView() ];
    }

}

function getApp() as rctrackerApp {
    return Application.getApp() as rctrackerApp;
}