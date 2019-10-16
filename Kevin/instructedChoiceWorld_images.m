function instructedChoiceWorld_images(t, evts, p, vs, in, out, audio)
%% instructedChoiceWorld
% attempting to implement antibiasing. One each trial, there'll be a
% black/white stimulus on the right/left. Each of those choices should be
% informed by history of recent success

%% Define Inputs -- wheel, keys, images
wheel = in.wheelDeg.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)
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

% Sounds
audioDevice = audio.Devices('default');
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audioDevice.DefaultSampleRate,...
    0.02, audioDevice.NrOutputChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.default = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% Map wheel to stimulus
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
stimulusDisplacement = p.wheelGain*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

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

stim_azimuth = azimuth + p.stimulusAzimuth*iff(stimSide, -1, 1);

%% Define stimulus
stimFlicker = mod(t * p.stimFlickerFrequency, 1) > 0.5;

number = nImgs.at(evts.newTrial).map(@randi);
numberStr = number.map(@num2str);
imgraw = mapn(numberStr, imgDir, @(num, dir)loadVar([dir, '\img' num '.mat'], 'img'));

stimulus = vis.image(t); 
stimulus.sourceImage = imgraw;
stimulus.azimuth = stim_azimuth;
stimulus.dims = ones(1,2)*p.stimulusSize;

stimulus.show = stimulusOn.to(stimulusOff) & stimFlicker;
vs.stimulus = stimulus;


%% Define trial-end timing
trialEndDelay = iff(feedback, ...
    (p.interTrialDelay_correct.map(@timeSampler)), ...
    p.interTrialDelay_incorrect.map(@timeSampler));

%% Set up antibiasing
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
evts.azimuth = azimuth;
evts.stimSide = stimSide;
evts.response = response;
evts.feedback = feedback;
evts.p_left = p_left;
% Accumulate reward signals and append microlitre units
evts.totalRewardVolume = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl'));
evts.p_correct_left = p_correct_left;
evts.p_correct_right = p_correct_right;
evts.p_correct_all = p_correct_all;
% Trial ends when evts.endTrial updates.
evts.endTrial = stimulusOff.delay(trialEndDelay);
evts.imgNumber = number;

%% Parameter defaults
try
    p.antibias_alpha = 0.2;
    p.antibias_beta = 3;
    p.rewardProb = 1;
    p.reward_delay = 0.1; 
    p.onsetToneFrequency = 5000;
    p.interactiveDelay = 0.4;
    p.onsetToneAmplitude = 0.15;
    p.responseWindow = Inf;
    p.stimulusAzimuth = 45;
    p.stimulusSize = 50;
    p.stimFlickerFrequency = 5;
    p.stimBrightness = 100;
    p.noiseBurstAmp = 0.01;
    p.noiseBurstDur = 0.5;
    p.rewardSize = 2.6;
    p.rewardKey = 'r';
    p.interTrialDelay_correct = 0.01;
    p.interTrialDelay_incorrect = 2;
    p.wheelGain = 1;
    p.encoderRes = 1024;
    p.preStimulusDelay = 0.5;
    p.imgDir = '\\zserver.cortexlab.net\data\pregenerated_textures\Kevin\fruits_and_nuts';
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
end