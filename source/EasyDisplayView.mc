import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian;
//using Sensor.Info;

// in order to test the watchface on the devcie: 
// 1. Create the binaries for the watch. Ctrl + Shift + P and "Monkey C: Build for Device". 
// 2. Connect the watch with its usb cable to your computer and allow transfer on the watch. 
// 3. Copy the prg file generated in (1.) to the folder Garmin/Apps on your watch
// 4. After disconnecting the watch from usb your new watchface is displayed


class EasyDisplayView extends WatchUi.WatchFace {

    // settings stored in application
    var dateForm;           // selected format of the date 
    var canBurnIn=false;    // true if screen can burn in (needed for always on displays)
    var inLowPower=false;   // low power mode activated - neded to make always on work
    var is24Hour=true;      // default true 
    var stringHR;           // the heart rate value as string
    var ICONSPACE = 5;      // Space between icon and text or icon and icon in pixel
    var dcFirst = false;    // if true the watchface is cleared at first when calling onUpdate

    // list of icons used on the watch face
    var bigDigitList = new [33];    // store normal and always on digits
    var dayNames  = new [7];    // store day names (Mo,...,Sun)
    var typeIcons = new[5]; // calories, .. Sleep
    var batIcon = new[5]; // bat1...5
    // individual bitmaps for the watch face
    var bmBtOn;
    var bmAlarm;
    var bmBat;
    var bmBatLoad;
    var bmSleep;
    var bmHeart;
    var bmMsg;
    var bmStep;
    var bmDist;
    // bitmap for km and mi 
    var bmKm;
    var bmMi;

    // return current heart beats or heart rate of last minute or null if older or not measured
    hidden function getHeartRate() {
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        if (heartRate == null && ActivityMonitor has :getHeartRateHistory) {    // if no current heart rate get last heart rate
            var hrHistory = ActivityMonitor.getHeartRateHistory(new Time.Duration(60), true).next(); // Try to get latest entry from the last minute
            if (hrHistory != null) { heartRate = hrHistory.heartRate; }
        }
        if (heartRate == ActivityMonitor.INVALID_HR_SAMPLE) { heartRate = null; }
        return heartRate;
    }

    // return current pulse oxygen saturation or value of last 3 days or null if older or not measured
    hidden function getSPO() {
        var spo = Activity.getActivityInfo().currentOxygenSaturation;
        if (spo == null && ActivityMonitor has :getOxygenSaturationHistory) {    // if no current heart rate get last heart rate
            var sHistory = ActivityMonitor.getOxygenSaturationHistory(new Time.Duration(60*60*24*3), true).next(); // Try to get latest entry from the last minute
            if (sHistory != null) { spo = sHistory.data; }
        }        
        return spo;
    }

    // return last body battery measurement of all stored measurements or null if never measured (or not supported)
    hidden function getBodyBat() {
        var bBat=null;
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) { // check if getBodyBatteryHistory supported
            bBat = Toybox.SensorHistory.getBodyBatteryHistory({}).next();   // get last measurement of all body battery measurements in SensorHistory
        }
        if(bBat == null) { return null; }  // not supported or no measurement found - return 0
        return bBat.data;   // else return measurment data (integer value)
    }

    // initialize will be called each time a watchface or a basic watchface setting is changed (language, 12h display, watchface, always on, ...)
    function initialize() {
        WatchFace.initialize();
        stringHR = "0";
        var dev=System.getDeviceSettings();
        if(dev has :requiresBurnInProtection) { // needed burn in protection detected (is always on for sq2 models)
        	canBurnIn=dev.requiresBurnInProtection;
        }        
        is24Hour = dev.is24Hour; // true if 24 hour display else false
    }

    // read date settings from Application.Storage into memory and calculate the date format
    // if no date format is set the default format is calculated
    // set the class value dateForm to the defined format or set default format
    function getSettings() as Void {
        var v = Toybox.Application.Storage.getValue(EasyDisplaySettings.DATESEP);   // read separator from application storage
        var ds=".";
        if(v instanceof Number) {   // if entry exist
            switch(v) {                 // translate number to correct date separator character
                case 0: ds = ""; break;
                case 1: ds = "."; break;
                case 2: ds = "/"; break;
                case 3: ds = "-"; break;            
            }
        }

        v = Toybox.Application.Storage.getValue(EasyDisplaySettings.DATEDAY); 
        var day = "$1$ ";   // check if the name of the day will be displayed too
        if(v instanceof Boolean) { 
            if(!v) { day = ""; }
        }       

        v = Toybox.Application.Storage.getValue(EasyDisplaySettings.DATEFORM);  // get the choosen date format
        if(!(v instanceof Number)) { v = 1; }   // default is 1 (dd mm yyyy) if value is not valid
        switch(v) { // build the format string
            case 2: dateForm = day + "$3$" + ds + "$2$" + ds + "$4$"; break;
            case 3: dateForm = day + "$4$" + ds + "$3$" + ds + "$2$"; break;
            default: dateForm = day + "$2$" + ds + "$3$" + ds + "$4$"; break; // default ist day month year
        }
    }

    // (1) called first --> (2) onShow()
    // Is only used for layout stuff - and dc is used for device specific layout calculations
    // don't draw outside onUpdate()!
    function onLayout(dc as Dc) as Void {        
        setLayout(null);    // we don't use layout functions 
    }

    // (2) called 2nd --> (3) onUpdate()
    // Called when this View is brought to the foreground.
    // Load all the resources/bitmaps and all the settings needed before you draw your watch face
    function onShow() as Void {
        dcFirst = true; // after on show delete screen only the first time on show is called
        // load the watch bitmaps for the numbers from resources - defined in /drawables/drawables.xml
        // Biga0 and Bigb0 are two dimm bitmaps of the number 0 that don't share a single pixle in order to realise burn in protection
        bigDigitList = [
            WatchUi.loadResource(Rez.Drawables.Big0),
            WatchUi.loadResource(Rez.Drawables.Big1),
            WatchUi.loadResource(Rez.Drawables.Big2),
            WatchUi.loadResource(Rez.Drawables.Big3),
            WatchUi.loadResource(Rez.Drawables.Big4),
            WatchUi.loadResource(Rez.Drawables.Big5),
            WatchUi.loadResource(Rez.Drawables.Big6),
            WatchUi.loadResource(Rez.Drawables.Big7),
            WatchUi.loadResource(Rez.Drawables.Big8),
            WatchUi.loadResource(Rez.Drawables.Big9),
            WatchUi.loadResource(Rez.Drawables.BigC),
            WatchUi.loadResource(Rez.Drawables.Biga0),
            WatchUi.loadResource(Rez.Drawables.Biga1),
            WatchUi.loadResource(Rez.Drawables.Biga2),
            WatchUi.loadResource(Rez.Drawables.Biga3),
            WatchUi.loadResource(Rez.Drawables.Biga4),
            WatchUi.loadResource(Rez.Drawables.Biga5),
            WatchUi.loadResource(Rez.Drawables.Biga6),
            WatchUi.loadResource(Rez.Drawables.Biga7),
            WatchUi.loadResource(Rez.Drawables.Biga8),
            WatchUi.loadResource(Rez.Drawables.Biga9),
            WatchUi.loadResource(Rez.Drawables.BigaC),
            WatchUi.loadResource(Rez.Drawables.Bigb0),
            WatchUi.loadResource(Rez.Drawables.Bigb1),
            WatchUi.loadResource(Rez.Drawables.Bigb2),
            WatchUi.loadResource(Rez.Drawables.Bigb3),
            WatchUi.loadResource(Rez.Drawables.Bigb4),
            WatchUi.loadResource(Rez.Drawables.Bigb5),
            WatchUi.loadResource(Rez.Drawables.Bigb6),
            WatchUi.loadResource(Rez.Drawables.Bigb7),
            WatchUi.loadResource(Rez.Drawables.Bigb8),
            WatchUi.loadResource(Rez.Drawables.Bigb9),
            WatchUi.loadResource(Rez.Drawables.BigbC)
        ];

        // load the day names from the string resource in order to support language dependencies
        dayNames = [
            WatchUi.loadResource(Rez.Strings.Su),
            WatchUi.loadResource(Rez.Strings.Mo),
            WatchUi.loadResource(Rez.Strings.Tu),
            WatchUi.loadResource(Rez.Strings.We),
            WatchUi.loadResource(Rez.Strings.Th),
            WatchUi.loadResource(Rez.Strings.Fr),
            WatchUi.loadResource(Rez.Strings.Sa)
        ];

        // load the user defined sensor icons
        typeIcons = [
            WatchUi.loadResource(Rez.Drawables.cal),
            WatchUi.loadResource(Rez.Drawables.stress),
            WatchUi.loadResource(Rez.Drawables.blood),
            WatchUi.loadResource(Rez.Drawables.activity),
            WatchUi.loadResource(Rez.Drawables.bbat)
        ];

        // load the different battery images
        batIcon = [
            WatchUi.loadResource(Rez.Drawables.bat1),
            WatchUi.loadResource(Rez.Drawables.bat2),
            WatchUi.loadResource(Rez.Drawables.bat3),
            WatchUi.loadResource(Rez.Drawables.bat4),
            WatchUi.loadResource(Rez.Drawables.bat5)
        ];

        // load the icons from drawable ressources
        bmBtOn = WatchUi.loadResource(Rez.Drawables.bton);
        bmAlarm = WatchUi.loadResource(Rez.Drawables.alarm);
        bmDist = WatchUi.loadResource(Rez.Drawables.dist);
        bmHeart = WatchUi.loadResource(Rez.Drawables.heart);
        bmKm =WatchUi.loadResource(Rez.Drawables.km);
        bmMi =WatchUi.loadResource(Rez.Drawables.mi);
        bmMsg = WatchUi.loadResource(Rez.Drawables.msg);
        bmSleep = WatchUi.loadResource(Rez.Drawables.sleep);
        bmStep = WatchUi.loadResource(Rez.Drawables.step);

        getSettings();  // read settings and calculate dateForm
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        // nothing to do here
    }


    // draw the status informat beginning with y position ypos on the screen (only if in high power mode)
    hidden function drawStatus(dc as Dc, ypos) as Void {
        if(inLowPower) { return; }  // don't draw in low power if allway on display is activated

        var stat = System.getSystemStats();
        var dev = System.getDeviceSettings();
        var batPercent = stat.battery;
        var x = 9;

        // delete screen area - not needed - will be cleared on watch - but not in simulator
        //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        //dc.fillRectangle(x,ypos,dc.getWidth()-x,iconSize);       
        dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_BLACK);

        // draw battery status
        if(stat.charging) { dc.drawBitmap(x,ypos,batIcon[4]); } // show charging icon
        else { 
            var bat;
            if(batPercent > 80) {bat = batIcon[0];} // show green battery full icon
            else if(batPercent > 20) {bat=batIcon[1];}  // show white battery good icon
            else if(batPercent > 10) {bat=batIcon[2];}  // show yellow battery low icon
            else {bat=batIcon[3];}  // show red battery is empty icon
            dc.drawBitmap(x,ypos+2,bat); 
        }                
        x+=(batIcon[0].getWidth() + ICONSPACE);
        dc.drawText(x,ypos,Graphics.FONT_XTINY,batPercent.format("%d")+"%",Gfx.TEXT_JUSTIFY_LEFT);
        x+=dc.getTextWidthInPixels("100%", Graphics.FONT_XTINY)+3;  // add space for lagest number (100%)

        // draw bluetooth icon - phone connected or leave empty
        if(dev.phoneConnected) { dc.drawBitmap(x,ypos,bmBtOn); }  // show connected icon bmBtOn        
        x+=(bmBtOn.getWidth() + ICONSPACE);

        // draw (DNDS) do not disturb icon - useless
        if(dev.doNotDisturb) { dc.drawBitmap(x,ypos+3,bmSleep); }
        x+=bmSleep.getWidth() + ICONSPACE;

        // draw alarm clock with number of alarms (1-3) or leave empty
        if(dev.alarmCount > 0) {
            dc.drawBitmap(x,ypos+3,bmAlarm);
            x+=bmAlarm.getWidth()+ICONSPACE;
            dc.drawText(x,ypos,Graphics.FONT_XTINY,dev.alarmCount.format("%d"),Gfx.TEXT_JUSTIFY_LEFT);
            x+=dc.getTextWidthInPixels(dev.alarmCount.format("%d"), Graphics.FONT_XTINY)+3;
        }
        else {x+=bmAlarm.getWidth()+ICONSPACE; }

        // draw notification with number of notifications (1..20) or leave empty
        if(dev.notificationCount > 0) {
            dc.drawBitmap(x,ypos+9,bmMsg);
            x+=bmMsg.getWidth()+ICONSPACE;
            dc.drawText(x,ypos,Graphics.FONT_XTINY,dev.notificationCount.format("%d"),Gfx.TEXT_JUSTIFY_LEFT);
        }
    }


    hidden function getSelectedSeonsorValue(selInf,info) as String {
        var str = "";
        var erg = 0;
        switch(selInf) {
            case EasyDisplaySettings.Calories: 
                erg = info.calories; 
                if(erg!=null) { str = erg.format("%d"); }
                else { str = "--"; }
                break;
            case EasyDisplaySettings.Stress:
                erg = info.stressScore; 
                if(erg!=null) { str = erg.format("%d"); }
                else { str = "--"; }
                break;
            case EasyDisplaySettings.Blood:
                erg = getSPO();
                if(erg!=null) { str = erg.format("%d")+"%"; }
                else { str ="--%"; }
                break; 
            case EasyDisplaySettings.Activity:            
                erg = info.activeMinutesDay.total;
                if(null!=erg) {str = erg.format("%d");}
                else { str = "--"; }
                break;
            case EasyDisplaySettings.BodyBat:
                erg = getBodyBat();
                if(null!=erg) { str = erg.format("%d"); }
                else { str = "--"; }
                break;     
        }
        return str;
    }

    // you can choose stepgoal, calories, stressScore, activeMinutesDay
    // draw the sensor data beginning with y position ypos on the screen
    hidden function drawSensor(dc as Dc, ypos) as Void {
        if(inLowPower) {return;}
        
        var erg;    
        var x = 1;  // x position
        var info = ActivityMonitor.getInfo();
        var selInf = Application.Storage.getValue(EasyDisplaySettings.INFOTYPE);

        if(! (selInf instanceof Number)) { selInf = 0; }
        else if(selInf<0 || selInf>4) { selInf = 0; }
        // clear area
        //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        //dc.fillRectangle(0,ypos,dc.getWidth(),95);

        // draw heart rate - first icon then heart rate
        dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_BLACK);
        dc.drawBitmap(x,ypos,bmHeart); x+=(bmHeart.getWidth()+ICONSPACE);
        erg = getHeartRate();
        if(null != erg) { stringHR = erg.format("%d"); }
        else { stringHR = "--"; }
        dc.drawText(x,ypos-9,Graphics.FONT_SMALL,stringHR,Gfx.TEXT_JUSTIFY_LEFT);

        // draw user selected sensor with icon
        x=dc.getWidth()/2+10;
        dc.drawBitmap(x,ypos,typeIcons[selInf]); x+=(typeIcons[selInf].getWidth()+ICONSPACE);
        dc.drawText(x,ypos-9,Graphics.FONT_SMALL,getSelectedSeonsorValue(selInf,info),Gfx.TEXT_JUSTIFY_LEFT);
        
        // draw number of steps and distance
        ypos += (bmHeart.getHeight()+8); x=1;
        dc.drawBitmap(x,ypos,bmStep); x+=(bmStep.getWidth()+ICONSPACE);
        erg = info.steps;
        if(erg != null) {
            dc.drawText(x,ypos-9,Graphics.FONT_SMALL,erg.format("%d"),Gfx.TEXT_JUSTIFY_LEFT);
            x+=dc.getTextWidthInPixels(erg.format("%d"), Graphics.FONT_SMALL)+5; // steps
        }
        else {  // can't read step value
            dc.drawText(x,ypos-9,Graphics.FONT_SMALL,"--",Gfx.TEXT_JUSTIFY_LEFT);
            x+=dc.getTextWidthInPixels("--", Graphics.FONT_SMALL)+5; // steps
        }

        // draw distance
        x= dc.getWidth()/2+10;
        dc.drawBitmap(x,ypos,bmDist); x+=(bmDist.getWidth()+ICONSPACE);
        erg = info.distance;
        if(null == erg) { erg = 0; }
        var dist_cm = 0.0 + erg;
        // convert distance in cm to miles or kilometer
        if(System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {  dist_cm = dist_cm / 100000.0;  }
        else {  dist_cm = dist_cm / 160934.0; }        
        dc.drawText(x,ypos-6,Graphics.FONT_TINY,dist_cm.format("%4.1f"),Gfx.TEXT_JUSTIFY_LEFT);
        x+=dc.getTextWidthInPixels(dist_cm.format("%4.1f"), Graphics.FONT_TINY)+2; // steps
        // write km or mi(les) at the end of the distance information
        if(System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
            dc.drawBitmap(x,ypos-6,bmKm);
        }
        else {
            dc.drawBitmap(x,ypos-6,bmMi);
        }
    }

    // helper variables needed for burn in protection - only used if always on Time and date display is used
    var burnT = -1; // 
    var toggle = false; // alternate between two time faces - toggles back and forth
    var dateM = false;  // only true if burn in protection needed and low power (always on) is activated
    var yadd = 0;   // determine the current position of the self moving AM/PM - in order to prevent burn in
    var xadd = 0;   // determine the current position of the self moving date string - in order to prevent burn in
    var BURNIN_TIMEOUT = 3;  // after BURNIN_TIMEOUT the pixel of the watch face must change in order to prevent burn in

    hidden function drawTime(dc as Dc, y, hr, min, sec) as Number {
        // handle midnight
        if(burnT+BURNIN_TIMEOUT >= (24*60) && min+60*hr <(BURNIN_TIMEOUT+1)) { burnT=burnT-(24*60)+BURNIN_TIMEOUT; }
        if(burnT+BURNIN_TIMEOUT <= min+60*hr) {  // burnin timeout is reached and we have to change/move turned on pixels
            if(canBurnIn) { // if you need burn in protection
                toggle = !toggle;   // use alternate bitmap
                dateM = true;   // move date
                if(!inLowPower) { dateM=false; }    // don't do date move if not in low power mode = always on
            }
            burnT=min+60*hr;    // burnT is new current time
        }
        //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        //dc.fillRectangle(0,1,dc.getWidth(),151);
        //dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_TRANSPARENT);
        
        // draw hour
        drawHr(dc,y,hr,toggle);
        
        // draw minute
        y = drawMin(dc,y, min,toggle);

        // draw seconds only if not in lowPower mode
        if(!inLowPower) {
            //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
            //dc.fillRectangle(290,115,59,15);
            dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
            dc.drawText(290,y-dc.getTextDimensions("0",Graphics.FONT_XTINY)[1]-1,Graphics.FONT_XTINY,sec.format("%02d"),Gfx.TEXT_JUSTIFY_LEFT);
        }
        
        return y;
    }

    hidden function drawHr(dc as Dc, y, hr,toggle) as Void {
        var h1,h2,sep; 
        var isam = 0;
        h1 = 0; h2 = 0; sep=10;

        if(!is24Hour) {
            if(hr < 12) {isam = 1; }    
            else { isam = 2; hr -= 12; }
        }
        if(hr >= 0) {
            h1 = hr % 10;
            h2 = (hr - h1)/10;
        }
        if(inLowPower) {
            h1+=11; // pointer to new bitmap
            sep+=11;    // pointer to new separator
            if(h2>0) { h2+=11; }
            if(canBurnIn && toggle) { // if toggle is true then switch to next bitmap
                h1+=11; sep+=11; if(h2>0) { h2+=11; }
            }    
        }
        if(h2>0) { dc.drawBitmap(0,y,bigDigitList[h2]); }   // only show h2 if exist
        dc.drawBitmap(65,y,bigDigitList[h1]);
        dc.drawBitmap(130,y,bigDigitList[sep]);

        // draw a.m. or p.m.
        dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_BLACK);
        var yp1 = y;
        var yp2 = yp1 + Graphics.getFontHeight(Graphics.FONT_XTINY) - 1;
        if(dateM) {
            switch(yadd) {
               case 0: yadd = 5; break;
               case 5: yadd = 9; break;
               case 9: yadd = 4; break;
               case 4: yadd = 0; break;
               default: yadd = 0;
            }
        }
        
        // if 12hr draw AM or PM as needed
        if(isam > 0) {
            if(isam == 1) { // draw am
                dc.drawText(293,yp1+yadd,Graphics.FONT_XTINY,"A",Gfx.TEXT_JUSTIFY_LEFT);
            }
            else { dc.drawText(293,yp1+yadd,Graphics.FONT_XTINY,"P",Gfx.TEXT_JUSTIFY_LEFT); }
            dc.drawText(293,yp2+yadd,Graphics.FONT_XTINY,"M",Gfx.TEXT_JUSTIFY_LEFT);
        }
    }

    // draw the big digit minute of the clock - if always on toggle the bitmap
    hidden function drawMin(dc as Dc,y, min,toggle) as Number {
        var m1=0,m2=0;

        if(min >= 0) {
            m1 = min % 10;
            m2 = (min - m1) / 10;
        }
        if(inLowPower) {
            m1+=11; // reduce pixel to half
            m2+=11;
            if(canBurnIn && toggle) { m1+=11; m2+=11; }
        }
        dc.drawBitmap(160,y,bigDigitList[m2]);
        dc.drawBitmap(225,y,bigDigitList[m1]);
        return y + bigDigitList[m2].getHeight();
    }

    // draw the date string in the format
    hidden function drawDate(dc as Dc,ypos) as Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);  // get current date
        var xp = dc.getWidth()/2;
        var textHeight = dc.getTextDimensions("A",Graphics.FONT_SMALL)[1];
        if(dateM) { // canBurnIn and inLowPower - do the date wiggling
            dateM = false;
            switch(xadd) {  // move the date around these x positions
                case 5: xadd = -1; break;
                case -1: xadd = -7; break;
                case -7: xadd = 0; break;
                case 0: xadd = 5; break;
                default: xadd = 0;
            }
            xp = xp+xadd;
        }        
        // draw date below big digits of clock - first clear area then draw date
        //dc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        //dc.fillRectangle(0,ypos,dc.getWidth(),textHeight);
        dc.setColor(Graphics.COLOR_LT_GRAY,Graphics.COLOR_BLACK);
        dc.drawText(xp,ypos,Graphics.FONT_SMALL,Lang.format(dateForm,[dayNames[today.day_of_week-1],today.day.format("%02d"),today.month.format("%02d"),today.year]),Gfx.TEXT_JUSTIFY_CENTER);
        return ypos+textHeight;
    }

    // (3) is called when:
    // - after onShow() - the view send to foreground
    // - on WatchUi.requestUpdate() 
    // - each minute when in low power mode (always on)
    // - each second when in high power mode (watch display is activated when you turn the wrist)
    // after some seconds in high power mode onEnterSleep() will be callend
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var y = 1;
        // ---------------- Draw time ------------------------------------
        if(dcFirst) { dc.clear(); dcFirst=false; }  // on first call clear complete background
        y = drawTime(dc,y,clockTime.hour,clockTime.min,clockTime.sec) + 10;

        // ---------------- Draw current date -----------------------------
        y = drawDate(dc,y) + 10;   // draw date beginning with line 165     
        // ---------------- Draw sensor data - two lines ------------------------
        drawSensor(dc,y); // draw sensor data beginning with line 228
        
        // ---------------- Draw status line - at bottom of screen  -------------      
        drawStatus(dc,dc.getHeight()-batIcon[0].getHeight()-4); // draw status beginning from bottom of screen
    }


    // when you move your wrist or you tap on button/screen the watch went to high power mode
    function onExitSleep() as Void {
         inLowPower=false; 
         dcFirst=true;  // when always on clear always on watchface and replace with high power wf
         xadd = 0; yadd = 0;
    }

    // normal operation: screen went blank - only in always on: call onUpdate once a minute (no partial update for seconds)
    function onEnterSleep() as Void {
        inLowPower=true; 
        dcFirst=true;   // remove active part of watchface with a clear screen
        xadd = 0; yadd = 0; 
        // onUpdate is now called once a minute - but only if display is always on 
    }
}
