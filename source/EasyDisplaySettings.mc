import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
using Toybox.Time.Gregorian;

// this class stores the application values and provide default values if needed
class EasyDisplaySettings {
  // enumeration type for infoType
  enum {
      Calories,
      Stress,
      Blood,
      Activity,
      BodyBat
  }
  
  // the values load from/to application storage with defaults
  var dateForm=1; // dd.mm.yyyy
  var dateSep=1; // '.'
  var dateDay=true as Boolean; // show name of day
  var infoType = Calories; // calories

  // keys of the app storage values and to the menu identifiers
  static var DATEFORM ='F' as Char; 
  static var DATESEP = 'S' as Char;
  static var DATEDAY = 'D' as Char;
  static var INFOTYPE = 'T' as Char;

  // constructor für settings in Toybox.Application.Properties and Storage
  function initialize() {
    loadAppStorage();
  }

  // load configuration values from app storage only if they exist and contain the correct 
  // values. Otherwise the default values are used.
  function loadAppStorage() {
    var val;
    val = Application.Storage.getValue(DATEFORM);
    if(val instanceof Number) { if(val>=1 && val<=3) {dateForm = val;} }
    val = Application.Storage.getValue(DATESEP);
    if(val instanceof Number) { if(val>=0 && val<=3) {dateSep = val;} }
    val = Application.Storage.getValue(DATEDAY);    
    if(val instanceof Boolean) {dateDay = val; }
    val = Application.Storage.getValue(INFOTYPE);    
    if(val instanceof Number) {if(val>=Calories && val<= BodyBat) { infoType = val; } }
  }

  // save configuration into application storage.
  function saveAppStorage() {
    try {
    Application.Storage.setValue(DATEFORM, dateForm);
    Application.Storage.setValue(DATESEP, dateSep);
    Application.Storage.setValue(DATEDAY, dateDay);
    Application.Storage.setValue(INFOTYPE, infoType);
    }
    catch(e instanceof Lang.Exception) {
      // ignor error and use default values
      // this can be a Lang.StorageFullException
    }    
  }
}

// the settings menu on the watch (is displayed as a pencil unter the watchface selection)
class EasyDisplaySettingsMenu extends WatchUi.Menu2 {
  var newAppSettings = null;

  // shows the menu (after pressing the pencil this is called)
  // will be called in EasyDisplayApp.getSettingssettingMenu()
  function initialize() {
    Menu2.initialize(null);
    newAppSettings = new EasyDisplaySettings();    // load existing application settings

    try { // can throw WatchUi.InvalidMenuItemTypeException or Lang.UnexpectedTypeException
      Menu2.setTitle(WatchUi.loadResource(Rez.Strings.sEDMTitle));  // display menu title   
      Menu2.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.sDateFormTitle),null,EasyDisplaySettings.DATEFORM,null));
      Menu2.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.sDateSepTitle),null,EasyDisplaySettings.DATESEP,null));
      Menu2.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.sInfoTypeTitle),null,EasyDisplaySettings.INFOTYPE,null));
      Menu2.addItem(new WatchUi.ToggleMenuItem(WatchUi.loadResource(Rez.Strings.sDateDayTitle), null,EasyDisplaySettings.DATEDAY,newAppSettings.dateDay,null));
    }
    catch(e instanceof Lang.Exception) {
      Menu2.setTitle("corrupt menu"); 
    }
  }
}

class EasyDisplaySettingsDelegate extends WatchUi.Menu2InputDelegate {
  var settingMenu=null;

  // will be called in EasyDisplayApp.getSettingssettingMenu()
  function initialize(menu as EasyDisplaySettingsMenu) {
    Menu2InputDelegate.initialize();
    settingMenu = menu;
  }

  function onSelect(item as WatchUi.MenuItem) {
    var id =  item.getId(); // get menu item identifier or Null    
    if(null == id) { return; }  // item with no id - return

    // Main menu: Check selected menu item, execute command but DON'T exit menu only return
    if(id.equals(EasyDisplaySettings.DATEFORM)) { openDateFormatSubMenu(); return; }  // Date Format Submenu
    if(id.equals(EasyDisplaySettings.DATESEP)) { openDateSepSubMenu(); return; }  // Date separator Submenu
    if(id.equals(EasyDisplaySettings.INFOTYPE)) { openInfoTypeSubMenu(); return; }  // Sensor/Information displayed in watch info slot
    if(id.equals(EasyDisplaySettings.DATEDAY)) { settingMenu.newAppSettings.dateDay = !settingMenu.newAppSettings.dateDay; return; }

    // Date Format Sub Menu: Check selected sub menu item
    if(id.equals("df1")) {
      settingMenu.newAppSettings.dateForm=1; 
    }
    else if(id.equals("df2")) {
      settingMenu.newAppSettings.dateForm=2; 
    }
    else if(id.equals("df3")) {
      settingMenu.newAppSettings.dateForm=3; 
    }

    // Date Separator Sub Menu: Check selected sub menu item
    else if(id.equals("ds0")) {
      settingMenu.newAppSettings.dateSep=0;
    }
    else if(id.equals("ds1")) {
      settingMenu.newAppSettings.dateSep=1;
    }
    else if(id.equals("ds2")) {
      settingMenu.newAppSettings.dateSep=2;
    }
    else if(id.equals("ds3")) {
      settingMenu.newAppSettings.dateSep=3; 
    }

    // Info Type Sub Menu: Check selected sub menu item
    else if(id.equals("ts0")) {
      settingMenu.newAppSettings.infoType=EasyDisplaySettings.Calories;
    }
    else if(id.equals("ts1")) {
      settingMenu.newAppSettings.infoType=EasyDisplaySettings.Stress;
    }
    else if(id.equals("ts2")) {
      settingMenu.newAppSettings.infoType=EasyDisplaySettings.Blood;
    }
    else if(id.equals("ts3")) {
      settingMenu.newAppSettings.infoType=EasyDisplaySettings.Activity; 
    }
    else if(id.equals("ts4")) {
      settingMenu.newAppSettings.infoType=EasyDisplaySettings.BodyBat; 
    }

    else { return; }  // not supported ids - return
    
    // for all sub menus save changes and return to main menu
    settingMenu.newAppSettings.saveAppStorage(); // save changed settings to application storage
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // immediate return to main menu or end menu
  }

  // on leave menu save all changes and return (pop current menu settingMenu from stack)
  // you leave a menu pressing the lower back button or swipe from left to right
  function onBack() {
    settingMenu.newAppSettings.saveAppStorage(); // save changes in app storage 
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);  // go to next menu on stack or leave menu
  }

  // needed to show date string preview in menu entry 
  hidden function dateStr(day,mon,yea,daf,ds) as String {
    //var str = "";
    var cs = ".";
    switch(ds) {
      case 0: cs=""; break;
      case 2: cs="/"; break;
      case 3: cs="-"; break;
    }
    var df = "$1$"+cs+"$2$"+cs+"$3$"; // 1
    switch(daf) {
      case 2: df="$2$"+cs+"$1$"+cs+"$3$"; break;
      case 3: df="$3$"+cs+"$2$"+cs+"$1$"; break;
    }
    return Lang.format(df,[day.format("%02d"),mon.format("%02d"),yea.format("%04d")]);
  }

  // show date format sub menu
  hidden function openDateFormatSubMenu() {
    var current = settingMenu.newAppSettings.dateForm;
    var smenu = new WatchUi.Menu2(null);
    var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var d;
    smenu.setTitle("---");
    try { // can throw WatchUi.InvalidMenuItemTypeException or Lang.UnexpectedTypeException
      // in order to reduce menu size only show relevant menus 
      if(current!=1) {    
        d = dateStr(today.day,today.month,today.year,1,settingMenu.newAppSettings.dateSep);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateDDMMYYYY), d,"df1",null));
      }
      if(current!=2) {
        d = dateStr(today.day,today.month,today.year,2,settingMenu.newAppSettings.dateSep);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateMMDDYYYY),d,"df2",null));
      }
      if(current!=3) {
        d = dateStr(today.day,today.month,today.year,3,settingMenu.newAppSettings.dateSep);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateYYYYMMDD),d,"df3",null));
      }
    }
    catch(e instanceof Lang.Exception) {
      smenu.setTitle("corrupt menu"); 
    }

    // push sub menu on settingMenu stack
    WatchUi.pushView(smenu, new EasyDisplaySettingsDelegate(settingMenu), WatchUi.SLIDE_IMMEDIATE);
  }

  // show date separator sub menu
  hidden function openDateSepSubMenu() {
    var smenu = new WatchUi.Menu2(null);
    var current = settingMenu.newAppSettings.dateSep; // current selection - don't show in menu
    var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var d;  // date string store

    smenu.setTitle("---");
    try { // can throw WatchUi.InvalidMenuItemTypeException or Lang.UnexpectedTypeException
      // in order to reduce menu size only show relevant menus 
      if(current!=0) {    
        d = dateStr(today.day,today.month,today.year,settingMenu.newAppSettings.dateForm,0);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateNone), d,"ds0",null));
      }
      if(current!=1) {    
        d = dateStr(today.day,today.month,today.year,settingMenu.newAppSettings.dateForm,1);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateDot),d,"ds1",null));
      }
      if(current!=2) {    
        d = dateStr(today.day,today.month,today.year,settingMenu.newAppSettings.dateForm,2);
        smenu.addItem(new WatchUi.MenuItem( WatchUi.loadResource(Rez.Strings.dateSlash), d,"ds2",null));
      }
      if(current!=3) {    
        d = dateStr(today.day,today.month,today.year,settingMenu.newAppSettings.dateForm,3);
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.dateHyp), d,"ds3",null));
      }
    }
    catch(e instanceof Lang.Exception) {
      smenu.setTitle("corrupt menu"); 
    }

    // show submenu
    WatchUi.pushView(smenu, new EasyDisplaySettingsDelegate(settingMenu), WatchUi.SLIDE_IMMEDIATE);
  }


  // show info type sub menu
  hidden function openInfoTypeSubMenu() {
    var smenu = new WatchUi.Menu2(null);
    var current = settingMenu.newAppSettings.infoType;

    smenu.setTitle("---");    
    try { // can throw WatchUi.InvalidMenuItemTypeException or Lang.UnexpectedTypeException
      // in order to reduce menu size only show relevant menus 
      if(current!=EasyDisplaySettings.Calories) {          
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.typeCalories), null,"ts0",null));
      }
      if(current!=EasyDisplaySettings.Stress) {          
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.typeStress),null,"ts1",null));
      }
      if(current!=EasyDisplaySettings.Blood) {    
        smenu.addItem(new WatchUi.MenuItem( WatchUi.loadResource(Rez.Strings.typeBlood),null,"ts2",null));
      }
      if(current!=EasyDisplaySettings.Activity) {    
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.typeActivity), null,"ts3",null));
      }

      if(current!=EasyDisplaySettings.BodyBat) {    
        smenu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.typeBodyBat), null,"ts4",null));
      }
    }
    catch(e instanceof Lang.Exception) {
      smenu.setTitle("corrupt menu"); 
    }     
    // show submenu
    WatchUi.pushView(smenu, new EasyDisplaySettingsDelegate(settingMenu), WatchUi.SLIDE_IMMEDIATE);
  }

}