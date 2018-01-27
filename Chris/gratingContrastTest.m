function gratingContrastTest(t, evts, p, vs, inputs, outputs, audio)

gratingOn = evts.newTrial.delay(1);
grating = vis.grating(t);
grating.contrast = p.contrast;
grating.show = gratingOn.map(true);
vs.grating = grating;

evts.endTrial = gratingOn.delay(1);

end