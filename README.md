# EasyDisplay
Garmin watch face for venue sq 2


| Date       | Version | Information on Version changes           |
|:-----------|:--------|:-----------------------------------------|
| 2024-07-01 | 1.0     | Initial version of face and documentaiton|
| 2024-07-13 | 1.1     | Add dynamic battery icons, optimize icons|


## Features

EasyDisplayClock is a Garmin Watchface for Venu SQ2 or Venu SQ2 Music or square displays with larger screen size.
This watchface can be found in the QC Store - and supports language deu, fre jpn spa (and english of corse).
Because Venu SQ2 has an Amoled display an burn in portection with a reduced watchface size is added.
You can customize the watch:

* Change the date display in the way you want to.
* One Sensor reading can be changed: from a) calories to b) stress value to c) pulse oxygene to d) acivity minutes of the day and to e) body battery.

Additionally the heart beat rate, the number of steps today and the distance in km/mi are always displayed.
At the bottom is a status bar that disply battery strength, bluetooth connection, do not disturbe mode, number of alarms set and number of messaged received.

## Programming

### Used tools and programming inspirations

- VSCode-win32-x64-1.90.1
- connectiq-sdk-manager for windows [Garmin SDK Website](https://developer.garmin.com/connect-iq/overview)
- SDK: Connect IQ 7.2.1 (2024-06-26) and watch device (donload with SDK manager)
- Font: TeX Gyre Adventor for clock numbers [Website TeX Gyre Adventor Font](https://www.gust.org.pl/projects/e-foundry/tex-gyre/adventor)
- Sample I used as inspiration: jim_m_58 had posted a great demo watchface in Garmin Forum: [Garmin Forum: ComplexWF](https://forums.garmin.com/developer/connect-iq/f/discussion/349473/simple-example-wf-that-shows-a-bunch-of-things)
- A good pixel graphic program with layers and pattern fill (of your choice)

### Basic program layout

The file structure:  
    \garmin here the test build for the device is exported  
    \garmin_exp here the build for connect iq shop is exported  
    \garmin_exp_images  hear are the images needed for the Garmin IQ store  
    \resurces   the image and string.xml standard resource  
    \resurces-xxx - the language depended strings  
    \source - here are the Monkey c source files  

In order to minimize the number of classes and number of code lines I decided to use only three files containing these classes:

* EasyDisplayApp (EasyDisplayApp.mc): Main class.
* EasyDisplayView (EasyDisplayView.mc): Watch face interface
* EasyDisplaySettings (EasyDisplaySettings.mc): App Settings
* EasyDisplaySettingsMenu (EasyDisplaySettings.mc): App menu functions
* EasyDisplaySettingsDelegate (EasyDisplaySettings.mc): Menu functions


### Watch Face
![wf1](/garmin_exp_images/wf500x500_v2.jpg)

### Class Diagram
![uml1](/garmin_exp_images/uml1.jpg)
![uml2](/garmin_exp_images/uml2.jpg)

### mermaid class diagram - not supported on github
::: mermaid
classDiagram
AppBase <|-- EasyDisplayApp
EasyDisplayApp --> Views
note for EasyDisplayApp "Main class - on watchface activation "
class EasyDisplayApp{
  viewEDV : WatchUi.Views
  
  initialize() Constructor
  getInitialView() Views
  onSettingsChanged() Void
  onStorageChanged() Void
  getSettingsView() List~Menu,Delegate~
  getApp() EasyDisplayApp
}

EasyDisplayView <|-- WatchFace

class EasyDisplayView {
  bigDigitList
  initialize() Constructor
  getSettings() Void
  onLayout(Dc) Void
  onShow() Void
  onUpdate(Dc) Void
  onExitSleep() Void
  onEnterSleep() Void
}
:::

::: mermaid
classDiagram
class enumeration {
  Calories
  Stress
  Blood
  Activity
  BodyBat
}

enumeration -- EasyDisplaySettings

class EasyDisplaySettings {
  dateForm
  dateSep
  dateDay
  infoType : enumeration
  DATEFORM
  DATESEP
  DATEDAY
  INFOTYPE

  initialize() constructor
  loadAppStorage() Void
  saveAppStorage() Void
}

EasyDisplaySettingsMenu --> EasyDisplaySettings
EasyDisplaySettingsMenu --|> Menu2
EasyDisplaySettingsDelegate --|> Menu2InputDelegate
EasyDisplaySettingsDelegate --> EasyDisplaySettingsMenu
class EasyDisplaySettingsMenu {
  newAppSettings : EasyDisplaySettings
  initialize() constructor
}

class EasyDisplaySettingsDelegate {
  settingMenu : Menu2
  initialize(EasyDisplaySettingsMenu) constructor
  onSelect(item)
  onBack()
}
:::
