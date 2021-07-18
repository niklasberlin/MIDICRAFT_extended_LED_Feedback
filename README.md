# MIDICRAFT extended LED Feedback v1.2
Lua script for grandMA2 Lighting Consoles to provide LED Feedback on Midi-Controllers from Midicraft

# Demoshow
The Demoshow is created with GrandMA2 onPC Version 3.9.60.18 and shows the use of the script with a Midicraft .PUSH

# ToDo:
-add possibility to get colors for macros and effects and not only sequences

-add more user colors to be more flexible

# Changelog
## v1.2.1
-FIXED: lokup of color "seagreen" now works as intended (issue #4)

-FIXED: spelling error of color violett (issue #3)

## v1.2
-FIXED: Bug where the color was incorrect if the sequence was on

## v 1.1
-ADDED: validation for user-configuration with (hopefully) helpfull error messages

-FIXED: updates for LED-Feedback will now be send everytime the color-cache is updated in addition to a state change of the exec

-FIXED: Bug that did not trigger a color-update on page change when only the buttonpage OR the Fadepage is changed
