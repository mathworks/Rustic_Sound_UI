function handleValueChangedFromUI(src,event,h)
name = event.HTMLEventName;
disp(name)
if strcmp(name,'ButtonAClicked')
    number = event.HTMLEventData;
    h.buttonA = number; 
    disp(number);
end
if strcmp(name,'ButtonBClicked')
    number = event.HTMLEventData;
    h.buttonB = number;    
    disp(number);
end
if strcmp(name,'slied1')
    number = event.HTMLEventData;
    disp(['predelay ' num2str(h.rvb_PreDelay) ' ' num2str(number)]);
    h.rvb_PreDelay = number;    
end
if strcmp(name,'slied2')
    number = event.HTMLEventData;
    disp(['wetDryMix ' num2str(h.rvb_WetDryMix) ' ' num2str(number)]);
    h.rvb_WetDryMix = number;    
end
if strcmp(name,'knob1')
    number = event.HTMLEventData;
    h.pnGain = number/50;
    disp(['pnGain ' num2str(h.pnGain)]);    
    disp(number);
end
if strcmp(name,'knob2')
    number = event.HTMLEventData;
    h.LP_lambda = number;
    if number> 2.8
       h.LP_static_count = 9999;
    else
       h.LP_static_count = poissrnd(number);
    end    
    disp(['lambda ' num2str(number)]);
end
if strcmp(name,'knob3')
    number = event.HTMLEventData;
    h.volume = number/20.0;
    disp(['volume ' num2str(h.volume)]);
end
if strcmp(name,'knob4')
    number = event.HTMLEventData;
    h.HPF_Cutoff = number/3*5000;
    h.calculateHPFCoefficients
    disp(number);
end
if strcmp(name,'knob5')
    number = event.HTMLEventData;
    h.LPF_Cutoff = number/3*5000;
%    h.calculateLPFCoefficients
    disp(number);
end
end
