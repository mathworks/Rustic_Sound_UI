# rusticSoundUI_Ws -- A rustic sound effect processor with HTML user interface implemented in MATLAB

## Overview
Run the script 'rusticSoundWrap.m' in MATLAB and it will bring up an html page as the user interface. User can start playing an audio file, changing and tuning the sound effects while listening to it.  The goal is to add sound effects so as to make it sounds like coming from an old radio.  The effects includes: 1, adding noise; 2, adding dust pop noise; 3, appling high pass filter; 4, appling low pass filter; 5, adding reverberation. 

## How to get started
Type the below line in Matlab:
>>rusticSoundWrap

## File List
=========  
rusticSoundWrap.m	-- a script to load in the audio file, start the HTML interface and send the audio data frame by 				frame to an instance of rusticSoundPlg.
rusticSoundPlg.m	-- this is the main implementation of the sound effects. It is implemented as an audio plugin class 
handleValueChangedFromUI.m -- this is the callback code that is run when a UI button is changed.
dft_voice_8kHz.wav	-- this is an example audio wav file used as the input data
my_webaudio-meter.js	-- this javascript creates the components needed for the html interface, this file is modified from 				g200kg (from see license.txt).
rusticSound_6.html	-- implementation of the user interface, this file is modified from g200kg (from see license.txt).
rusticSound.png		-- picture modified from g200kg (from see license.txt).
LittlePhatty.png	-- picture from g200kg (from see license.txt).
switch_toggle.png	-- picture from g200kg (from see license.txt).
vernier.png		-- picture from g200kg (from see license.txt).
Vintage_VUMeter_2.png	-- picture from g200kg (from see license.txt).
vsliderbody.png		-- picture from g200kg (from see license.txt).
vsliderknob.png		-- picture from g200kg (from see license.txt).

## Relevant Industries

audio components design, audio equipments design, audio systems design, audio plugin, audio plugin development, sound effects development

## Relevant Products
 *  MathWorks®
 *  DSP System Toolbox™ 
 *  Audio Toolbox™
 *  Statistics and Machine Learning Toolbox™


Copyright 2024 The MathWorks, Inc.
