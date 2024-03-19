# Device scripts

Handful of scripts for customers to run to setup devices quickly

## Raspberry PI

The raspberry PI bash script helps get the raspbian Pi into a kiosk like mode, easing the setup that would normally be required by hand. By default it will 
 - install the latest chromium browser from apt that is available
 - install some mscore fonts
 - install google color emoji font for nicer emoji display
 - whether the user wants to do a full `apt upgrade`
 - whether to turn on overscaning (only applicable to non-wayland instances)
 - setup a login script to be called upon the GUI starting
   - which starts google chrome at Geckoboard fullscreen
 
### Running

You can run the script with the following one liner

```sh
bash <(curl https://raw.githubusercontent.com/geckoboard/device-scripts/master/raspberrypi)
```

Read and follow the instructions

### Desktop environment support

The bash script only works with LXDE-Pi desktop environment. This is because we hook in the LXDE startup hooks for when the GUI is started, to allow us to start Chromium browser automatically and remove the mouse cursor.

It will also validate before executing that the OS release is Raspbian and the hardware architecture is armv

When the script is completed it will restart the pi to complete the setup but not before the user has

### Uninstall

If a user wants to put their Pi back to normal without formatting it they can do so using the uninstall script this will
remove the LXDE bash script hook for starting chrome and remove some fonts and that.

```sh
bash <(curl https://raw.githubusercontent.com/geckoboard/device-scripts/master/uninstall_scripts/raspberrypi_uninstall)
```

## Windows

The Windows script is written in VBScript just like bash its baked into the core of the Windows operating system and thus is supported on several versions. This again does some steps to help setup Geckoboard in kiosk like mode automatically

 - helps direct setup of auto login
 - ensures chrome browser is installed
 - installs a custom script to prevent the computer sleeping
 - installs a script which will start chrome at Geckoboard fullscreen

### Running 

Download via a browser by navigating to 

https://github.com/geckoboard/device-scripts/releases/download/latest/windows_kiosk.vbs

Once it is downloaded - double click the vbscript it should prompt to allow admin accept this, it will display blackbox. 

Read and follow the instructions

## Uninstalling

If the user wants to not start Chrome automatically they can run the uninstall script which will delete the login hook scripts

https://github.com/geckoboard/device-scripts/releases/download/latest/windows_kiosk_uninstall.vbs

Once it is downloaded - double click the vbscript it should prompt to allow admin accept this, it will display blackbox. 

Read and follow the instructions
