% rusticSoundWrap -- this script demonstrates how to use a user
% interface from HTML to control in real-time a streaming audio player.
% The audio is read from a file and then added in a few sound effects: 
%  adding Noise, dust pop, high pass filter, low pass filter,
%  reverberation.
%
% Copyright © 2023-2024 The MathWorks, Inc.  
% Francis Tiong (ftiong@mathworks.com)


% input sound file
newName = 'dft_voice_8kHz.wav';
frameSize = 1024;       % number of samples to be processed in a frame

% Setting up audio reader and player

fileReader = dsp.AudioFileReader(newName,'PlayCount',inf,...
    'SamplesPerFrame',frameSize);  % this is the file reader object
sampleRate = fileReader.SampleRate;

deviceWriter = audioDeviceWriter('SampleRate',fileReader.SampleRate);  % this is the sound card device object

% all the effects are processed inside the rusticSoundPlg class 
instRusticSound = rusticSoundPlg(sampleRate);

% setting up a time scope to see the before and after waveform
scope = timescope('SampleRate',sampleRate, ...
    'TimeSpanSource','property', ...
    'TimeSpanOverrunAction','scroll', ...
    'TimeSpan',5, ...
    'BufferLength',5*2*sampleRate, ...
    'YLimits',[-1 1]);


% settng up a window space for the UI
fig = uifigure;
fig.Position = [100 200 1140 345]; 
%  100 pixels right 200 above bottom left corner 1140 wide and 345 tall
fig.Color = [0 0 0];

h = uihtml(fig); % creating a subwindows inside that has the html picture
h.Position = [10 10 1120 320];
h.HTMLSource = fullfile(pwd,'rusticSound_6.html'); 

h.HTMLEventReceivedFcn = @(src,event) handleValueChangedFromUI(src,event, instRusticSound);  % setting up a callback function to process the buttons

%%
outt = zeros(frameSize,2);

% Stream processing loop
nUnderruns = 0;
instRusticSound.LP_static_count = 9999;
in = zeros(frameSize,1); out = zeros(frameSize,1);
durationOfDuctPop = 100;   % number of samples for each dust pop  
while(1)         

    % ButtonA is the play switch
    if instRusticSound.buttonA == 1
        [in, eof] = fileReader();
            
        % process one data frame 
        out = instRusticSound.process(in);
                
        % this block creates the dust pop sound
        if instRusticSound.LP_static_count==0
            dustIdx = floor(rand*frameSize+1);
            dustIdxEnd = min(dustIdx + durationOfDuctPop, frameSize);
            out(dustIdx:dustIdxEnd) = 0.5; % a fixed level is used for the pop sound
        end

        % ButtonB is the effects bypass switch
        if instRusticSound.buttonB == 1
            out = in;
        end

        outt = [out out];  % making it stereo data 
        
        nUnderruns = nUnderruns + deviceWriter(outt); % send to audio DAC
    
        % if nUnderruns > 1000
        %     disp('underrun');
        % end
    else
        in = zeros(frameSize,1); out = zeros(frameSize,1); % stop play, no sound
    end    

    scope(in, out); % sending the input and output signal to the scope

    % this section calculates the number of frames until the next dust pop
    if instRusticSound.LP_lambda > 2.8
       instRusticSound.LP_static_count = 9999;
    end
    instRusticSound.LP_static_count = instRusticSound.LP_static_count - 1;
    if instRusticSound.LP_static_count<=0
        instRusticSound.LP_static_count = poissrnd(instRusticSound.LP_lambda);
    end

    % sending level data to the display meters
    val = floor(abs(outt(1,1))*1000);
    sendEventToHTMLSource(h,"vumeter1",val);
    val = floor(abs(outt(1,2))*1000);
    sendEventToHTMLSource(h,"vumeter2",val);

    % the below line makes the callback functions responsive to changes 
    drawnow limitrate  

end

