
function sparseNoiseAsyncOLD(t, evts, p, vs, inputs, outputs, audio)

trialLen = 3; % seconds
stimPersistence = 0.2; % seconds
stimulusRate = 0.5; % Hz, on average
gridCenter = [0 0]; % degrees visual angle
gridSize = [20 20]; % degrees visual angle
gridSpacing = [10 10]; % degrees visual angle
squareSize = [10 10]; % degrees visual angle
squareColor = [0 0 0];



% trialLen = p.trialLen;

lowerLeft = gridCenter - gridSize./2;
nAz = floor(gridSize(1)/gridSpacing(1))+1;
nAl = floor(gridSize(2)/gridSpacing(2))+1;
nextStimDelay = 1/stimulusRate;

% stimuliOnDelay = [];
% stimuliOn = [];
% stimuliOff = [];
% stimuliPresent = false(0,0);
% allTargets = [];

% for q = 1:10
% %     stimuliOnDelay = [stimuliOnDelay p.trialLen*evts.newTrial.map(@(~)rand)];
% 
% %     if q==1
% %         stimuliOnDelay = trialLen*evts.newTrial.map(@(~)rand);
% %         stimuliOn = evts.newTrial.delay(stimuliOnDelay(q));
% %     %     stimuliOff = [stimuliOff stimuliOn(q).delay(p.visStimDuration)];
% %         stimuliOff = stimuliOn(q).delay(0.2);
% %         stimuliPresent = stimuliOn(q).to(stimuliOff(q));
% %     else
% %         stimuliOnDelay = [stimuliOnDelay trialLen*evts.newTrial.map(@(~)rand)];
% %         stimuliOn = [stimuliOn evts.newTrial.delay(stimuliOnDelay(q))];
% %     %     stimuliOff = [stimuliOff stimuliOn(q).delay(p.visStimDuration)];
% %         stimuliOff = [stimuliOff stimuliOn(q).delay(0.2)];
% %         stimuliPresent = [stimuliPresent stimuliOn(q).to(stimuliOff(q))];
% %     end
%     
%     
%     eval(sprintf('stimuliOnDelay%d = trialLen*evts.newTrial.map(@(~)rand);', q));
%     eval(sprintf('stimuliOn%d = evts.newTrial.delay(stimuliOnDelay%d);', q, q));
%     eval(sprintf('stimuliOff%d = stimuliOn%d.delay(0.2);', q, q));
%     eval(sprintf('stimuliPresent%d = stimuliOn%d.to(stimuliOff%d);', q, q, q));
%         
% %     target = vis.grating(t, 'square', 'gaussian');
% %     target.phase = 2*pi*evts.newTrial.map(@(~)rand); % random phase on each trial
% %     % target.altitude = p.targetAltitude;
% %     target.altitude = q*5-25;
% %     % target.sigma = p.targetSigma;
% %     target.sigma = [4 4];
% %     % target.spatialFreq = p.targetSpatialFrequency;
% %     target.spatialFreq = 0.1;
% %     target.azimuth = 180*evts.newTrial.map(@(~)rand)-90;
% %     target.orientation = 180*evts.newTrial.map(@(~)rand);
% %     target.show = stimuliPresent(q);
%     eval(sprintf('target%d = vis.grating(t, ''square'', ''gaussian'');', q));
%     eval(sprintf('target%d.phase = 2*pi*evts.newTrial.map(@(~)rand);', q));
%     eval(sprintf('target%d.altitude = q*5-25;', q));
%     eval(sprintf('target%d.sigma = [4 4];', q));
%     eval(sprintf('target%d.spatialFreq = 0.1;', q));
%     eval(sprintf('target%d.azimuth = 180*evts.newTrial.map(@(~)rand)-90;', q));
%     eval(sprintf('target%d.orientation = 180*evts.newTrial.map(@(~)rand);', q));
%     eval(sprintf('target%d.show = stimuliPresent%d;', q, q));
%     eval(sprintf('vs.target%d = target%d;', q, q)); % put target in visual stimuli set
% %     if q==1
% %         allTargets = target;
% %     else
% %         allTargets = [allTargets target]; % put target in visual stimuli set
% %     end
% end

dt = t.delta();


% stimuliOn = dt.map(@(v)randStart(v,stimulusRate));
% stimuliOff = stimuliOn.delay(stimPersistence);
% stimuliPresent = stimuliOn.to(stimuliOff);

% target = vis.patch(t, 'rectangle');
% target.show = stimuliPresent;
% vs.target = target;

for azGrid = 1:nAz
    for alGrid = 1:nAl
        q = (azGrid-1)*nAl+alGrid;
        eval(sprintf('stimuliOn%d = dt.map(@(v)randStart(v,stimulusRate));', q));
        eval(sprintf('stimuliOff%d = stimuliOn%d.delay(stimPersistence);',q,q));
        eval(sprintf('stimuliPresent%d = stimuliOn%d.to(stimuliOff%d);', q,q,q));
        
        eval(sprintf('target%d = vis.patch(t, ''rectangle'');',q));
        eval(sprintf('target%d.azimuth = (azGrid-1)*gridSpacing(1)+lowerLeft(1);',q));
        eval(sprintf('target%d.altitude = (alGrid-1)*gridSpacing(2)+lowerLeft(2);',q));
        eval(sprintf('target%d.dims = squareSize;',q));
        eval(sprintf('target%d.colour = squareColor;',q));
        eval(sprintf('target%d.show = stimuliPresent%d;',q,q));
        eval(sprintf('vs.target%d = target%d;',q,q));
        
%         stimuliOn = dt.map(@(v)randStart(v,stimulusRate));
%         stimuliOff = stimuliOn.delay(stimPersistence);
%         stimuliPresent = stimuliOn.to(stimuliOff);
%         
%         target = vis.patch(t, 'rectangle');
%         target.azimuth = (azGrid-1)*gridSpacing(1)+lowerLeft(1);
%         target.altitude = (alGrid-1)*gridSpacing(2)+lowerLeft(2);
%         target.dims = squareSize;
%         target.colour = squareColor;
%         target.show = stimuliPresent;
%         vs.target = target;
        
    end
end

% f = figure;
% subplot(3,1,1);
% ax1 = plot(now,0, '.-');
% stimuliOn1.onValue(@(v)plotSig('stimuliOn1', v, ax1));
% subplot(3,1,2);
% ax2 = plot(now,0, '.-');
% stimuliOff1.onValue(@(v)plotSig('stimuliOff1', v, ax2));
% subplot(3,1,3);
% ax3 = plot(now,0, '.-');
% stimuliPresent1.onValue(@(v)plotSig('stimuliPresent1', v, ax3));

% stimuliOn = evts.newTrial.delay(stimuliOnDelay(q));
% stimuliOff = stimuliOn(q).delay(p.visStimDuration);
% stimuliPresent = stimuliOn(q).to(stimuliOff(q));

% target = vis.grating(t, 'square', 'gaussian');
% target.phase = 2*pi*evts.newTrial.map(@(~)rand); % random phase on each trial
% % target.altitude = p.targetAltitude;
% target.altitude = 0;
% % target.sigma = p.targetSigma;
% target.sigma = [4 4];
% % target.spatialFreq = p.targetSpatialFrequency;
% target.spatialFreq = 0.1;
% target.azimuth = 180*evts.newTrial.map(@(~)rand)-90;
% target.orientation = 180*evts.newTrial.map(@(~)rand);
% target.show = stimuliPresent(q);
% vs.target = allTargets; % put target in visual stimuli set

%% misc
% trialEnd = evts.newTrial.delay(p.trialLen+p.interTrialInterval);
trialEnd = evts.newTrial.delay(trialLen);
evts.endTrial = trialEnd; % nextCondition.at(trialEnd); CB: nextCondition doesn't exist


% we want to save these so we put them in events with appropriate names
evts.stimuliOn1 = stimuliOn1; % CB: u commented these out
evts.stimuliPresent1 = stimuliPresent1;


% function plotSig(name, val, ax)
% thisTime = now;
% dispWindowTime = 5; %seconds
% xd = get(ax, 'XData'); yd = get(ax, 'YData');
% inclDat = xd>=thisTime-dispWindowTime;
% newxd = [xd(inclDat) thisTime thisTime]; newyd = [yd(inclDat) yd(end) val];
% set(ax, 'XData', newxd, 'YData', newyd);
% title(name)
% yrange = max(newyd)-min(newyd);
% ylim([min(newyd)-0.1*yrange max(newyd)+0.1*yrange]);
% xlim([thisTime-dispWindowTime/24/3600 thisTime]);


function out = randStart(dtVal, rate)
out = rand()<rate*dtVal;
