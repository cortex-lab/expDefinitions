function sqWorld(t, evts, p, vs, in, out, audio)
%% Very simple exp to test inferParams
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
stimOn = evts.newTrial;
stimOff = stimOn.delay(p.stimDelay);

% stim2 = vis.grating(t, 'sin', 'none');
% stim2.show = stimOn.to(stimOff);
% vs.stim2 = stim2;

% Stim
% stim = vis.patch(t, 'rectangle', 'gaussian'); % create a full field grating
% stim = vis.bang(t);
stim = vis.patch(t);
% stim.orientation = 0;
% stim.azimuth = 0;
% stim.sigma = [50 50];
% stim.dims = [50 50];
stim.show = stimOn.to(stimOff);
vs.stim = stim;


evts.endTrial = stimOff.delay(5);

end