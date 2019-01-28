global AGL GL GLU StimWindowInvalid%#ok<NUSED>
Priority(1); % increase thread priority level
% OpenGL
InitializeMatlabOpenGL;


rig = hw.devices;
bgColour = 127*[1 1 1]; % mid gray by default
rig.stimWindow.BackgroundColour = bgColour;
rig.stimWindow.open();


clock = rig.clock;
clockFun = @clock.now;
obj.TextureById = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
obj.LayersByStim = containers.Map;
% obj.Inputs = sig.Registry(clockFun);
% obj.Outputs = sig.Registry(clockFun);
obj.Visual = StructRef;
net = sig.Net;
obj.Net = net;
obj.Time = net.origin('t');
obj.Listeners = [];

obj.StimWindowPtr = rig.stimWindow.PtbHandle;
StimWindowInvalid = false;
obj.AsyncFlip = false;
obj.Occ = vis.init(obj.StimWindowPtr);
if isfield(rig, 'screens')
  obj.Occ.screens = rig.screens;
end

obj.Timers = [timer('ExecutionMode', 'fixedDelay', 'Name', 't', ...
  'Period', 0.2, 'TimerFcn', @(~,~)fun.run(true,@()post(obj.Time, clock.now))),...
  timer('ExecutionMode', 'fixedDelay', 'Name', 'schedule', ...
  'Period', 0.05, 'TimerFcn', @(~,~)fun.run(true,@()obj.Net.runSchedule)),...
  timer('ExecutionMode', 'fixedDelay', 'Name', 'flip', ...
  'Period', 0.1, 'TimerFcn', @(~,~)fun.run(true,@()drawFrame(obj)))];
arrayfun(@start, obj.Timers)
%%%
% stimOn = net.origin('start');
% endSig = net.origin('end');
% 
% endSig.Node.Listeners = [endSig.Node.Listeners, ...
%   into(stimOn.delay(10), endSig), endSig.onValue(@(~,~)cleanup(rig)), ...
%   endSig.onValue(@(~,~)disp('end'))];
% 
% stimulus = vis.grating(obj.Time); % create image
% stimulus.spatialFreq = stimOn/5;
% stimulus.show = stimOn.to(stimOn.delay(6));


t = obj.Time;
% imgDir = t.Node.Net.origin('imageDir');
% N = imgDir.map(@(p)length(dir(fullfile(p,'*.mat')))); % Get number of images
% imgIds = N.map(@randperm);
% % 
% on = t.Node.Net.origin('on');
% off = t.Node.Net.origin('off');
% % 
% idx = merge(at(true, imgDir), on.scan(@plus, 0).at(off));
% number = imgIds(idx);%.map(@num2str);
% numberStr = number.map(@num2str);
% 
% % Test stim left
% stimulus = vis.image(obj.Time); % create image
% srcImg = imgDir.map2(numberStr, ...
%   @(dir,num)loadVar(fullfile(dir, ['img' num '.mat']), 'img'));
% 
% stimulus.sourceImage = loadVar('\\zserver.cortexlab.net\Data\pregenerated_textures\Marius\proc\selection2800\img1.mat','img');
% stimulus.name = numberStr;
% stimulus.rescale = true;
% stimulus.show = on.to(off);
% 
% obj.Visual.cat = stimulus;
% t0 = t.at(on);
% t.Node.Listeners = [t.Node.Listeners, ...
%   on.at(t-t0 > 5).into(off),...
%   off.at(t-t0 > 10).into(on),...
%   on.onValue(@(~,~)disp('on')),...
%   off.onValue(@(~,~)disp('off')),...
%   srcImg.onValue(@(~,~)disp('img update')),...
%   srcImg.onValue(@(~,~)post(on, true))];

% PATCH

stimulus = vis.patch(obj.Time, 'circle');
% stimulus = vis.grating(obj.Time, 'sine');
on = net.origin('on');
off = net.origin('off');

off.Node.Listeners = [off.Node.Listeners, ...
  off.onValue(@(~,~)cleanup(rig)), ...
  off.onValue(@(~,~)disp('end'))]; %into(on.delay(10), off),

stimulus.dims = [50 50];
stimulus.show = on.to(off);
obj.Visual.cat = stimulus;
%%%

% obj.SyncBounds = rig.stimWindow.SyncBounds;
% obj.SyncColourCycle = rig.stimWindow.SyncColourCycle;
% obj.NextSyncIdx = 1;

% load each visual stimulus
% cellfun(@obj.loadVisual, fieldnames(obj.Visual));
stims = fieldnames(obj.Visual);
for name = 1:length(stims)
        layersSig = obj.Visual.(stims{name}).Node.CurrValue.layers;
      obj.Listeners = [obj.Listeners
        layersSig.onValue(fun.partial(@newLayerValues, obj, stims{name}))];
      newLayerValues(obj, stims{name}, layersSig.Node.CurrValue);
end

%refresh the stimulus window
% Screen('Flip', obj.StimWindowPtr);

%%% DRAWFRAME
%%%%

% rig.stimWindow.close();
% Priority(0); %set back to normal priority level
    function newLayerValues(obj, name, val)
    global StimWindowInvalid
%       fprintf('new layer value for %s\n', name);
%       show = [val.show]
      if isKey(obj.LayersByStim, name)
        prev = obj.LayersByStim(name);
        prevshow = any([prev.show]);
      else
        prevshow = false;
      end
      obj.LayersByStim(name) = val;

      if any([val.show]) || prevshow
        StimWindowInvalid = true;
      end
      
    end
    function drawFrame(obj)
    global StimWindowInvalid
      % Called to draw current stimulus window frame
      %
      % drawFrame(obj) does nothing in this class but can be overrriden
      % in a subclass to draw the stimulus frame when it is invalidated
      if ~StimWindowInvalid; return; end
      if obj.AsyncFlip
        Screen('AsyncFlipEnd', obj.StimWindowPtr);
        obj.AsyncFlip = false;
      end
      win = obj.StimWindowPtr;
      layerValues = cell2mat(obj.LayersByStim.values());
      Screen('BeginOpenGL', win);
      vis.draw(win, obj.Occ, layerValues, obj.TextureById);
      Screen('EndOpenGL', win);
      StimWindowInvalid = false;
      disp('Flip')
      Screen('Flip', obj.StimWindowPtr);
%       obj.AsyncFlip = true;
    end
    
    function cleanup(rig)
      rig.stimWindow.close();
      Priority(0); %set back to normal priority level
      delete(timerfind);
    end