function testvc3(t, evts, p, vs, inputs, outputs, audio)

samplerFs = 60;
sampler = skipRepeats(floor(t*samplerFs)); % to run a command at a certain sampling rate


checker = vis.checker3(t);
checker.show = true;
checker.pattern = sampler.map(@(~)randi(3,[10 20])-2);
checker.rectSizeFrac = [1 1];
checker.azimuthRange = (0.75 + 0.25*cos(2*pi*t))*[-60 60];
checker.altitudeRange = (0.75 + 0.25*sin(2*pi*t))*[-30 30];
vs.myNoise = checker;


%% misc
evts.endTrial = evts.newTrial.delay(Inf);
evts.sampler = sampler;

end


