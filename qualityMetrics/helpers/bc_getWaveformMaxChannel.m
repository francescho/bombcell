function maxChannels = bc_getWaveformMaxChannel(templateWaveforms)
% JF, Get the max channel for all templates (channel with largest amplitude)
% ------
% Inputs
% ------
% templateWaveforms: nTemplates × nTimePoints × nChannels single matrix of
%   template waveforms for each template and channel
% ------
% Outputs
% ------
% maxChannels: nTemplates * 1 vector of max channels for each template
% 
    [~, maxChannels] = max(max(abs(templateWaveforms), [], 2), [], 3);
end