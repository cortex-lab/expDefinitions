function gratingContrastTest(t, evts, p, vs, inputs, outputs, audio)

gratingOn = evts.newTrial.delay(1);
grating = vis.grating(t);
% grating2 = grating.at(gratingOn);
grating2 = vis.grating(t);
% gratingSurr = grating.at(gratingOn);
grating.contrast = p.contrast;
grating2.contrast = p.contrast;
grating.show = gratingOn.map(true);
grating2.show = gratingOn.map(true);
grating.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
grating2.phase = 2*pi*evts.newTrial.map(@(v)rand); % random phase on each trial
grating.altitude = 0;
grating2.altitude = 0;
grating.sigma = [9,9];
% gratingSurr.sigma = grating.sigma*1.2;
grating2.sigma = [9,9];
% surround.sigma = grating.sigma*1.2;
% grating.spatialFrequency = p.targetSpatialFrequency;
% targetAzimuth = p.targetAzimuth + cond(...
%   stimulusOn.to(interactiveOn), 0,... % no offset during fixed period
%   interactiveOn.to(response),   targetDisplacement,...%offset by wheel
%   response.to(stimulusOff),    -response*abs(p.targetAzimuth));%final response
grating.azimuth = 30;
grating2.azimuth = -30;
%
vs.grating = grating;
vs.grating2 = grating2;
% vs.gratingSurr = gratingSurr;

evts.endTrial = gratingOn.delay(1);

end