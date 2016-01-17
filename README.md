# Gamepad Menu

Gamepad button mapper that lives as a menu in your OS X status bar.

When trying to play Broforce (yes, [Broforce](http://www.broforcegame.com)) on a Mac with my SteelSeries Nimbus controller, I noticed most buttons were not supported by the game's gamepad configuration, probably because (for some weird reason) every single button on the Nimbus is pressure sensitive, except the "Menu" button. Existing Mac software for joystick mapping was either paid or crappy. More specifically, they had no configurable threshold for the pressure sensitive buttons, meaning even the simple action buttons had to be pressed down very firmly to trigger a keypress.

Of course, with those limitations, it's hard to get your bro on, so I decided to make my own button mapper. It is aimed exclusively at gamepads and, while focussed on getting Nimbus' pressure sensitive buttons working, supports other gamepads as well.

## Features

* Uses device profiles to map each supported gamepad device to a common control set, which a preset maps to specific keyboard presses.

* Adjustable button threshold for pressure sensitive buttons and triggers.

* Smart thresholding stickiness filter to prevent double key presses on a jittery value.

* Kept simple on purpose. Only maps to keyboard, not mouse. Currently has no UI for creating device profiles or presets; this is done by editing plist files instead.

* To facilitate "Start at Login", the `ServiceManagement.framework` is used together with a helper app, which should work in a sandboxed environment as well (as long as the app lives in /Applications).

## Installation

Just fetch the latest ZIP from the [release section](https://github.com/robbertkl/GamepadMenu/releases) section and put the extracted app into your Applications folder.

You might need to disable OS X Gatekeeper to run it: *System Preferences* > *Security & Privacy* > *General* tab > *Allow apps downloaded from: Anywhere*.

## Device profiles

Device profiles map known gamepad devices to "standardised" controls commonly found on gamepads. See [the Device Profiles folder](Resources/Device Profiles/) for all currently supported devices. A device profile plist contains 2 sections:

* `Identifier` contains a vendor ID + product ID used to identify newly connected devices. If the same device uses different identifiers (e.g. one for USB and another for bluetooth), you can make this an array of dictionaries (see [SteelSeries Nimbus](Resources/Device Profiles/SteelSeries Nimbus.plist) for an example).

* `Elements` contains a mapping from all device elements to the common gamepad controls. They are identified by `<usage-page>:<usage>`. Supported element types are:
    * `Button` - Regular button or trigger, either binary (0..1) or pressure sensitive (0..255). Has 1 key binding.
    * `Axis` - X or Y axis of an analog stick. Has 2 key bindings (left+right or up+down).
    * `Hat Switch` - Single element which maps an entire D-Pad. Has 4 key bindings. See [PlayStation 4 Controller](Resources/Device Profiles/PlayStation 4 Controller.plist) element `1:57` for an example.

A useful tool to check out HID devices and their elements is [Apple's HID Calibrator code sample](https://developer.apple.com/library/mac/samplecode/HID_Calibrator/).

Please note the Xbox 360 controller requires a driver to work on OS X. I'm using [360Controller](https://github.com/360Controller/360Controller), which works perfectly on El Capitan. I only have a wired Xbox 360 controller, so I'm not sure how well it works with the wireless controllers. It would be nice if someone could test it and send me its vendor and product IDs, or a custom device profile if it differs from the wired version.

## Presets

Preset plist files contain the key bindings for each of the mapped common gamepad controls. Use a string value to bind it to a keyboard character, or a number to bind it to a `CGKeyCode`.

## Wishlist

* More supported devices (PR if you have new ones!)
* Storing device profiles and presets in `~/Library/Application Support` for easy manipulation
* UI for creating / editing device profiles
* UI for creating / editing presets
* Auto update device profiles from an online (GitHub?) repository
* Automatic activation of presets when games are launched

## Authors

* Robbert Klarenbeek, <robbertkl@renbeek.nl>

## Credits

* Thanks to [Alex Zielenski](https://twitter.com/#!/alexzielenski) for [StartAtLoginController](https://github.com/alexzielenski/StartAtLoginController), which ties together the ServiceManagement stuff without even a single line of code (gotta love KVO).

* The [vector drawing used for the app icon](Resources/Graphics/AppIcon.ai) was made by [sebi01](http://www.vecteezy.com/members/sebi01) from [Vecteezy.com](http://www.vecteezy.com).

* The [vector drawing used for the status menu icon](Resources/Graphics/StatusMenuTemplate.eps) was made by [Freepik](http://www.freepik.com) from [Flaticon](http://www.flaticon.com).

## License

Gamepad Menu is published under the [MIT License](http://www.opensource.org/licenses/mit-license.php).
