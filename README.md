# MIDICRAFT extended LED Feedback v1.1
Lua script for grandMA2 Lighting Consoles to provide LED Feedback on Midi-Controllers from Midicraft

# ToDo:
-add possibility to get colors for macros and effects and not only sequences

-add more user colors to be more flexible

# Changelog
## v 1.1
-ADDED: validation for user-configuration with (hopefully) helpfull error messages
-FIXED: updates for LED-Feedback will now be send everytime the color-cache is updated in addition to a state change of the exec
-FIXED: Bug that did not trigger a color-update on page change when only the buttonpage OR the Fadepage is changed
