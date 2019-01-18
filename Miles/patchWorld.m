function patchWorld(t, evts, p, vs, in, out, audio)
%% Very simple exp for patch
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
stimOn = evts.newTrial;
stimOff = stimOn.delay(p.stimDelay);

% stim2 = vis.grating(t, 'sin', 'none');
% stim2.show = stimOn.to(stimOff);
% vs.stim2 = stim2;

% Stim
stim = vis.patch(t, 'rectangle'); % create a full field grating
% stim.orientation = 0;
% stim.azimuth = 0;
% stim.altitude = 0;
% stim.dims = [50 50];
stim.show = stimOn.to(stimOff);
vs.stim = stim;


evts.endTrial = stimOff.delay(5);

try
  p.stimDelay = 0.5;
catch
end

end