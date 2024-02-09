% audioplugin class rusticSoundPlg
% This code applies the following effects to the input audio:
%    LPF, HPF, pink Noise, reverb, volume
%
% Input: in -- one frame of audio data at the process function, one or two
%              channels but using only channel 1 for now
%        fs -- sampling frequency could be passed in and be considered as a fixed value. 
% output: out -- one frame of data at the process function 
%
% Copyright © 2023-2024 The MathWorks, Inc.  
% Francis Tiong (ftiong@mathworks.com)
%
classdef rusticSoundPlg < audioPlugin
  
  % public interface -- these variables are exposed to the outside  
  % Note that if the audio plugin graphics rendering is not needed then the
  %  initial setting of the external graphics (eg. html) need to match these values
  properties (Access = public)

    % High Pass Filter 
    HPF_Cutoff = 1000           % high pass cutoff freq
    HPF_Q = sqrt(2)/2           % Q value of the high pass filter

    % Low Pass Filter
    LPF_Cutoff = 3000           % low pass cutoff freq
    LPF_Q = sqrt(2)/2           % Q value of the low pass filter
      
    % volument and pink noise level
    volume = 1.5;               % volume level adjustment 
    pnGain = 1;                 % pink noise level adjustment

    % Reverb
    reverb                      % holding the reverb obj
    rvb_PreDelay = 0            % reverb delay
    rvb_WetDryMix = 30          % reverb wet and dry mix, echo level 

    % sampling frequency
    fixedFs = 0                 % flag indicate whether fs is passed in and fixed
    fs = 8000

    % external UI state
    buttonA = 0                 % the state of button A, used outside of this code
    buttonB = 0                 % the state of button B, used outside of this code
    LP_lambda = 6               % lambda value of a poisson distribution, used in noise pop, outside of this code
    LP_static_count = 9999;     % number of frames to the next noise pop, used outside of this code
    
  end

  properties (Constant)
    % the audioPLuginInterface is used only when the audioplugin graphics UI rendering needed
    PluginInterface = audioPluginInterface( ...
      'PluginName','Rustic Sound',...
      audioPluginParameter('LPF_Cutoff', 'DisplayName',  'LPF fc', 'Label',  'Hz', 'Mapping', { 'log', 20, 10000},'Layout',[1,1]), ...
      audioPluginParameter('LPF_Q', 'DisplayName',  'LPF Q', 'Mapping', { 'log', 0.1, 200}, 'Style','rotary','Layout',[1,2]), ...
            audioPluginGridLayout          );    
  end 

  properties (Access = private)

    % internal state for LPF and HPF
    hpf_z = zeros(2,1)
    hpf_b = [1, zeros(1,2)]
    hpf_a = [1, zeros(1,2)]

    lpf_z = zeros(2,1)
    lpf_b = [1, zeros(1,2)]
    lpf_a = [1, zeros(1,2)]
    
  end
  
  methods
      
      function out = process(obj, in)

        out = in;
        inn = in(:,1);
        [u, v] = size(in);
        if v>1
          inn = in(:,1);        % using only one channel for now
        end

        ll = length(inn);
        pn = pinknoise(ll);
        inn = inn + pn*obj.pnGain;  % adding pink noise

        [outt,obj.hpf_z] = filter(obj.hpf_b, obj.hpf_a, inn, obj.hpf_z);  % HPF
        [outt,obj.lpf_z] = filter(obj.lpf_b, obj.lpf_a, outt, obj.lpf_z); % LPF

        outt2 = obj.reverb(outt);   % adding reverb        
        outt = outt2(:,1);

        outt = outt*obj.volume;     % adjusting volume

        if v>1                      % generate two channels
            out(:,1) = outt;
            out(:,2) = outt;
        else
            out = outt;
        end

    end
    
    % constructor 
    function obj = rusticSoundPlg(fsIn)

        % if the sampling frequency is not passed in then it is not fixed
        if ~exist('fsIn')
            fsIn = getSampleRate(obj);
            obj.fixedFs = 0;
        else
            obj.fixedFs = 1;
        end       
       obj.fs = fsIn;
       disp(['fs ' num2str(obj.fs)])

       % prepare reverb object
       predelay = obj.rvb_PreDelay/100; % 0-1 sec
       wetDryMix = obj.rvb_WetDryMix/100; % 0 - 1
       obj.reverb = reverberator('SampleRate',obj.fs, 'PreDelay', predelay, 'WetDryMix', wetDryMix);
      
      % initialize internal state of LPF and HPF
      obj.hpf_z = zeros(2,1);
      calculateHPFCoefficients(obj);
      obj.lpf_z = zeros(2,1);
      calculateLPFCoefficients(obj);
    end

    % the reset function is called played through plugin engine, at that
    % time the sampling frequency might change
    function reset(obj)
       calculateHPFCoefficients(obj);
       calculateLPFCoefficients(obj);
       obj.reverb.SampleRate = obj.fs;
    end
    
    % change in reverb delay
    function set.rvb_PreDelay(obj, preDelay)
       obj.rvb_PreDelay = preDelay;
       updateReverb(obj);
    end
    % change in reverb wet and dry mix
    function set.rvb_WetDryMix(obj, wdMix)
       obj.rvb_WetDryMix = wdMix;
       updateReverb(obj);
    end
    % update reverb obj
    function updateReverb(obj)
       % Function to compute reverb obj
       %fs = getSampleRate(obj);
       predelay = obj.rvb_PreDelay/100; % 0-1 sec
       wetDryMix = obj.rvb_WetDryMix/100; % 0 - 1

       obj.reverb.PreDelay = predelay; 
       obj.reverb.WetDryMix = wetDryMix;
       disp('update reverb')
    end

    % change in HPF cutoff
    function set.HPF_Cutoff(obj, Cutoff)
      obj.HPF_Cutoff = Cutoff;
      calculateHPFCoefficients(obj);      
    end
    % change in HPF Q
    function set.HPF_Q(obj, Q)
      obj.HPF_Q = Q;
      calculateHPFCoefficients(obj);
    end
    % change in LPF cutoff
    function set.LPF_Cutoff(obj, Cutoff)
      obj.LPF_Cutoff = Cutoff;
      calculateLPFCoefficients(obj);
    end
    % change in LPF Q
    function set.LPF_Q(obj, Q)
      obj.LPF_Q = Q;
      calculateLPFCoefficients(obj);
    end
    % update HPF coefficients
    function calculateHPFCoefficients(obj)
 
        % check if the sampling freq has changed
        if(~obj.fixedFs)
            obj.fs = getSampleRate(obj);
        end
        theta = obj.HPF_Cutoff/obj.fs;
        if theta > 0.4
            theta = 0.4;
        end
        w0 = 2*pi*theta;
        alpha = sin(w0)/(2*obj.HPF_Q);
        cosw0 = cos(w0);
        norm = 1/(1+alpha);
        obj.hpf_b = (1 + cosw0)*norm * [.5 -1 .5];
        obj.hpf_a = [1 -2*cosw0*norm (1 - alpha)*norm];
        disp(['HPF cutoff= ' num2str(obj.HPF_Cutoff) ' fs= ' num2str(obj.fs)])
    end
    % update LPF coefficients
    function calculateLPFCoefficients(obj)

        % check if the sampling freq has changed
        if(~obj.fixedFs)
            obj.fs = getSampleRate(obj);
        end        
        theta = obj.LPF_Cutoff/obj.fs;
        if theta > 0.4
            theta = 0.4;
        end        
        w0 = 2*pi*theta;
        K = tan(w0/2);
        W = K*K;
        alpha = 1 + K/obj.LPF_Q + W;
        walpha = W/alpha;
        obj.lpf_b = [walpha 2*W/alpha walpha];
        obj.lpf_a = [1 2*(W-1)/alpha (1-K/obj.LPF_Q+W)/alpha];        
        disp(['LPF cutoff= ' num2str(obj.LPF_Cutoff) ' fs= ' num2str(obj.fs)])
        
     end    
  end
  
end
