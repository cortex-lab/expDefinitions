function [seq_ori,seq_phase,pori] = adaptorSequence(nori,nphase,nstim,rada,ori_ada,seedR)
%% example parameters
% nori = 6;
% nphase = 8;
% nstim = 100;
% rada = 0.2; %between 0 and 1
% ori_ada = 60;
% seedR
%%



dori = 180/nori;
oris_vec = linspace(0,180-dori,nori);


dphase = (pi/2)/nphase;
phase_vec = linspace(0,pi/2-dphase,nphase);

puni = 1/nori;
dpada = rada*(1 - puni);
pada = puni + dpada; %probability of the adaptor
pother = puni - dpada/(nori - 1);

ada_id = find(oris_vec == ori_ada);

pori = pother.*ones(1,nori);
pori(ada_id) = pada;

rng(seedR);
seq_ori = datasample(oris_vec,nstim,'Weights',pori);
seq_phase = datasample(phase_vec,nstim);




