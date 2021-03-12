# UDLF
Universal Door Latch Framework mod for Teardown

# DISCLAIMER:
This does not change doors in maps that have not been set up to use it. That means that no built in maps will have this functionality.

# What it does:

This script allows for a generalized approach to latching doors without the need to give joints individual names and write custom scripts to look for those names specifically.

# Permissions:
This is meant to be used in maps. If you do set up doors to use this script, just remember to put it in your required list.

# How it works:

When the door is near enough to the closed position (limit "0"), it will apply a slight force to keep it closed. When you grab the door, it removes that force, allowing you to open the door. following this, it will remain loose until the door returns to its closed position. That means that if you leave a car door open, you could use your brakes to close it. This is different than other implementations that use interactions (button prompt) that switch the direction of the force. This is due mostly to my own preference, but also due to how the script checks for each door. It could probably be easily changed though if you prefer that method.





# For developers:

An example map is available here: https://steamcommunity.com/sharedfiles/filedetails/?id=2414412110

Add "Latch" tag to the VOX of each shape. DO NOT TAG THE JOINT! Otherwise, the script will not work.

Add built in sound effects by extending the tag to "Latch=Vehicle" or "Latch=Structure". If you add custom sounds, this will function as a fallback for if a file is not included. Fallback does not currently work if the file does not exist or is not valid. I'm looking into validation.

Custom sounds can be added with "LatchOpenSound=../mod_name/path_to_sound.ogg" and "LatchCloseSound=../mod_name_path_to_sound.ogg". Ensure that the path always starts with "../" followed by the name of the FOLDER your mod is in, and then the rest of the path to the sound. For some reason "../MOD/" and "../LEVEL/" don't work.

Please ensure that all joints you wish to latch are in the closed position at limit 0, as this is what the script considers the "closed" position. This generally means that the door is closed in the .vox file.
