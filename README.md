# netcard_manager
set up wireless card for WiFi 5, 6

network management script using whiptail for the graphical user interface. 

Features:

whiptail is used for menus (--menu), input boxes (--inputbox), and message boxes (--msgbox).
Dynamic Menus:
The list of network interfaces and channels is dynamically generated and passed to whiptail as an array of options.
Error Handling:
Checks if the user cancels any menu or doesn't select an option, and handles it gracefully.

