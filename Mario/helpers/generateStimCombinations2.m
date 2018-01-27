function [oris_sel,phase_sel] = generateStimCombinations2(oris_vec,phase_vec)



nc = size(oris_vec,1);
%nt = length(ISI_vec);
np = length(phase_vec);

[A,B] = meshgrid((1:nc),(1:np));
c=cat(2,A',B');
trialId=reshape(c,[],2)';

%trialId = combvec((1:nc),(1:np));

oris_sel = oris_vec(trialId(1,:),:);

%ISI_sel = ISI_vec(trialId(2,:));

phase_sel = zeros(length(trialId),2);
phase_sel(:,2) = phase_vec(trialId(2,:));