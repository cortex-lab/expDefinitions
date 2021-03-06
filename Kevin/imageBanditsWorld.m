function imageBanditsWorld(t, evts, p, vs, in, out, audio)
%% IMAGEWORLD
% Image directory must contain image files as MAT files named imgN where N
% = {1, ..., N total images}.

%% Define Inputs -- wheel, keys, images
wheel = in.wheelMM.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)
rewardKey = p.rewardKey.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyPressed = in.keyboard.strcmp(rewardKey); % true each time the reward key is pressed

%% Define timing -- when should things move
% stimulus should come on after the wheel has been held still for the
% duration of the preStimulusDelay.  The quiescence threshold is a tenth of
% the rotary encoder resolution.
preStimulusDelay = p.preStimulusDelay.map(@timeSampler).at(evts.newTrial); % at(evts.newTrial) fix for rig pre-delay
stimulusOn = sig.quiescenceWatch(preStimulusDelay, t, wheel, floor(p.encoderRes/100));
interactiveDelay = p.interactiveDelay.map(@timeSampler);
interactiveOn = stimulusOn.delay(interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

%% Define outputs -- images and sounds
% Images
imgDir = p.imgDir.skipRepeats();
nImgs = imgDir.map(@(p)length(dir(fullfile(p,'*.mat')))); % Get number of images
imgIds = nImgs.map(@randperm);

% Sounds
audioDevice = audio.Devices('default');
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audioDevice.DefaultSampleRate,...
    0.02, audioDevice.NrOutputChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.default = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% Map the wheel onto the stimulus
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
millimetersFactor = map2(p.wheelGain, 31*2*pi/(p.encoderRes*4), @times); % convert the wheel gain to a value in mm/deg
stimulusDisplacement = millimetersFactor*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

%% define response and response threshold
threshold = interactiveOn.setTrigger(abs(stimulusDisplacement) >= abs(p.stimulusAzimuth));

response = -sign(stimulusDisplacement);
response = response.at(threshold); % only update the response signal when the threshold has been crossed

stimulusOff = threshold.delay(1); % true a second after the threshold is crossed

%% define correct response and feedback
% p_left needs to be an origin signals, so that we can post an
% inital value, but also modify them (using listeners) based on other
% signals
p_left = t.Node.Net.origin('p_left');

% Choose a side and a color whenever newTrial updates, using the current
% value of p_left
stimSide = p_left.at(evts.newTrial).map(@(x) rand < x);

% Pick a reward probability. At the moment, this is constant and based on a
% parameter. In other expDefs, it should be somthing smarter
leftRewardProb = iff(stimSide, p.rewardProb, 0);
rightRewardProb = iff(~stimSide, p.rewardProb, 0);
leftBaited = leftRewardProb.map(@(x) rand < x);
rightBaited = rightRewardProb.map(@(x) rand < x);

% Determine when the mouse gets a reward
feedback = (response == -1 & leftBaited) | ...
    (response == 1 & rightBaited);
feedback = feedback.at(threshold).delay(p.reward_delay);

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(audioDevice.NrOutputChannels, p.noiseBurstDur*audioDevice.DefaultSampleRate, @randn);
audio.default = noiseBurstSamples.at(feedback==0); % When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'

reward = merge(rewardKeyPressed, feedback > 0);% only update when feedback changes to greater than 0, or reward key is pressed
out.reward = p.rewardSize.at(reward); % output this signal to the reward controller

%% stimulus azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% define the visual stimulus
% Later, block will become a signal, and be controlled be some logic. For
% now, there's just one block
block_i = 0;
imgIndR = imgIds(2*block_i + 1);
imgIndN = imgIds(2*block_i + 2);

stimFlicker = mod(t * p.stimFlickerFrequency, 1) > 0.5;

imgIndR_str = imgIndR.map(@num2str);
imgIndN_str = imgIndN.map(@num2str);

% Set up stimulus
imgR = mapn(imgDir, imgIndR_str, @(dir, num)loadVar([dir, '\img' num '.mat'], 'img'));
imgN = mapn(imgDir, imgIndN_str, @(dir, num)loadVar([dir, '\img' num '.mat'], 'img'));

stimulusR = vis.image(t); 
stimulusR.sourceImage = imgR;
stimulusR.azimuth = azimuth + p.stimulusAzimuth*iff(stimSide, -1, 1);
stimulusR.show = stimulusOn.to(stimulusOff) & stimFlicker;
stimulusR.dims = ones(1,2)*p.stimulusSize;

stimulusN = vis.image(t); 
stimulusN.sourceImage = imgN;
stimulusN.azimuth = azimuth + p.stimulusAzimuth*iff(stimSide, 1, -1);
stimulusN.show = stimulusOn.to(stimulusOff) & stimFlicker;
stimulusN.dims = ones(1,2)*p.stimulusSize;

% Send stimuli to the set in vs
vs.stimulusR = stimulusR; 
vs.stimulusN = stimulusN; 

%% Define trial-end timing
trialEndDelay = iff(feedback, ...
    (p.interTrialDelay_correct.map(@timeSampler)), ...
    p.interTrialDelay_incorrect.map(@timeSampler));

%% Set up left/right antibiasing
exp_avg = @(old, new, alpha) alpha*new + (1-alpha)*old;
e = exp(1);
left_perf_ab  = feedback.keepWhen(stimSide==1).scan(exp_avg, 0, 'pars', p.antibias_alpha);
right_perf_ab = feedback.keepWhen(stimSide==0).scan(exp_avg, 0, 'pars', p.antibias_alpha);

antibias_p_left = e^(p.antibias_beta * right_perf_ab) / ...
        (e^(p.antibias_beta * right_perf_ab) + e^(p.antibias_beta * left_perf_ab));


% Send antibias_p_left into p_left
t.Node.Listeners = [t.Node.Listeners, into(antibias_p_left, p_left)];
% But post an initial value for p_left
p_left.post(0.5);

%% Track performance
correct_all = feedback.scan(@plus,0);
correct_left = feedback.keepWhen(stimSide==1).scan(@plus,0);
correct_right = feedback.keepWhen(stimSide==0).scan(@plus,0);

nTrials_left = threshold.keepWhen(stimSide==1).scan(@plus,0);
nTrials_right = threshold.keepWhen(stimSide==0).scan(@plus,0);

p_correct_all = correct_all.at(evts.newTrial) / (evts.trialNum - 1);
p_correct_left = correct_left.at(evts.newTrial) / nTrials_left.at(evts.newTrial);
p_correct_right = correct_right.at(evts.newTrial) / nTrials_right.at(evts.newTrial);

%% End trial and log events

% we want to save these signals so we put them in events with appropriate
% names:
evts.stimulusOn = stimulusOn;
evts.stimSide = stimSide;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.p_left = p_left;
% Accumulate reward signals and append microlitre units
evts.totalRewardVolume = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1f�l'));
evts.p_correct_left = p_correct_left;
evts.p_correct_right = p_correct_right;
evts.p_correct_all = p_correct_all;
% Trial ends when evts.endTrial updates.
evts.endTrial = stimulusOff.delay(trialEndDelay);
evts.imgR = imgIndR;
evts.imgN = imgIndN;

%% Parameter defaults
try
    p.antibias_alpha = 0.2;
    p.antibias_beta = 3;
    p.minBlockLength = 50;
    p.blockFlipProb = 0.5;
    p.rewardProb = 1;
    p.reward_delay = 0.1; 
    p.onsetToneFrequency = 5000;
    p.interactiveDelay = 0.5;
    p.onsetToneAmplitude = 0.15;
    p.responseWindow = Inf;
    p.stimulusAzimuth = 45;
    p.stimulusSize = 40;
    p.stimFlickerFrequency = 5;
    p.noiseBurstAmp = 0.01;
    p.noiseBurstDur = 0.5;
    p.rewardSize = 2.4;
    p.rewardKey = 'r';
    p.interTrialDelay_correct = 0.01;
    p.interTrialDelay_incorrect = 2;
    p.wheelGain = 50;
    p.encoderRes = 1024;
    p.preStimulusDelay = 0.5;
    p.imgDir = '\\zserver.cortexlab.net\Data\pregenerated_textures\Kevin\simple_shapes';
catch % ex
    %    disp(getReport(ex, 'extended', 'hyperlinks', 'on'))
end

%% Helper functions
function duration = timeSampler(time)
% TIMESAMPLER Sample a time from some distribution
%  If time is a single value, duration is that value.  If time = [min max],
%  then duration is sampled uniformally.  If time = [min, max, time const],
%  then duration is sampled from a exponential distribution, giving a flat
%  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
%  from time.
%
% See also exp.TimeSampler
  if nargin == 0; duration = 0; return; end
  switch length(time)
    case 3 % A time sampled with a flat hazard function
      duration = time(1) + exprnd(time(3));
      duration = iff(duration > time(2), time(2), duration);
    case 2 % A time sampled from a uniform distribution
      duration = time(1) + (time(2) - time(1))*rand;
    case 1 % A fixed time
      duration = time(1);
    otherwise % Pick on of the values
      duration = randsample(time, 1);
  end
end
  function preLoad()
    d = '\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800';
    imgs = dir(fullfile(d,'*.mat'));
    loadVar(strcat({imgs.folder},'\',{imgs.name}))
  end
end