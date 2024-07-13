import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class EasyDisplayApp extends Application.AppBase {
    var viewEDV;    // pointer to EasyDisplayView

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
    // This method runs each time the main application starts or you change your Watchface settings (24h format, ...)
    function getInitialView() as [Views] or [Views, InputDelegates] {
        viewEDV = new EasyDisplayView();
        return [ viewEDV ];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {        
        viewEDV.getSettings();
        WatchUi.requestUpdate();
    }

    // called if app storage changed 
    function onStorageChanged() as Void {
        viewEDV.getSettings();
        WatchUi.requestUpdate();
    }

    // settings can be changed in watch menu, the simulator and qi app
    // the simulate will not send an onStorageChanged signal - so the screen must be updated manually
    function getSettingsView() {
        var menuView = new EasyDisplaySettingsMenu();   // create the menu view
        return [menuView, new EasyDisplaySettingsDelegate(menuView)] as [ WatchUi.Views, WatchUi.InputDelegates ];
  }

}

function getApp() as EasyDisplayApp {
    return Application.getApp() as EasyDisplayApp;
}