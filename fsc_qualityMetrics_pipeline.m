%% ~~ FSC bombcell pipeline ~~ (adapted from EAJ repo)
% Adjust the paths in the 'set paths' section and the parameters in bc_qualityParamValues
% This pipeline will run bombcell on your data and save the output

addpath(genpath("C:\Users\walnut\Documents\GitHub\bombcell"))
addpath(genpath("C:\Users\walnut\Documents\GitHub\npy-matlab"))
addpath(genpath("C:\Users\walnut\Documents\GitHub\prettify_matlab"))

%% set paths
clearvars
%sessions = readtable('Z:\fcho2\2024_Fall\Preprocessed_Data\Provenance\allsess_f24_eachgate.csv');

single_session ='Z:\fcho2\2024_Fall\Preprocessed_Data\Spikes\GatesRun\Durmast\Ecephys\20240919_Durmast_TD08\catgt_20240919_Durmast_TD08_g0\20240919_Durmast_TD08_g0_imec1\imec1_ks';
ephysKilosortPath = single_session;
ephysRawFile = "NaN"; % path to your raw .bin or .dat data
ephysMetaDir = dir([single_session '*ap*.*meta']); % path to your .meta or .oebin meta file
savePath = [single_session 'qMetrics']; % where you want to save the quality metrics 



%for s = 1:height(sessions)
for s = 1:2
    task = string(sessions{s,'Task'});
    rec_error = string(sessions{s,'Recording_Error'});
    for probe = 0:1
        % generate the path to the directory containing the ap.bin file
        base_dir = string(sessions{s,'Base_Directory'});
        base_dir = strrep(base_dir, '/', '\');
        ecephys_path = strcat(base_dir, '\Preprocessed_Data\Spikes');

        rec_file_stem = split(string(sessions{s,'File'}),'/');
        rec_file_stem = convertStringsToChars(rec_file_stem(2));
        rec_file_path = sprintf('%s\\%s\\Ecephys\\%s\\catgt_%s\\%s_imec%d',...
            ecephys_path, string(sessions{s,'Animal'}),...
            rec_file_stem(1:end-3), rec_file_stem,...
            rec_file_stem, probe);

        % set variables for BombCell
        mainDir = rec_file_path;
        ephysKilosortPath = sprintf('%s/imec%d_ks',rec_file_path,probe);
        rec_file_base = sprintf('%s/%s_tcat.imec%d.ap',rec_file_path,rec_file_stem, probe);
        rawFile = [rec_file_base,'.bin'];
        ephysMetaFile = [rec_file_base,'.meta'];

        saveLocation = mainDir;
        savePath = fullfile(saveLocation, 'qMetrics');



        % new: set variables for BombCell (from tutorial.mlx)
        kilosortVersion = 3; % if using kilosort4, you need to have this value kilosertVersion=4. Otherwise it does not matter. 
        gain_to_uV = NaN; % use this if you are not using spikeGLX or openEphys to record your data. this value, when mulitplied by your raw data should convert it to  microvolts. 




        % load data
        [spikeTimes_samples, spikeClusters, templateWaveforms, templateAmplitudes, pcFeatures, ...
            pcFeatureIdx, channelPositions] = bc.load.loadEphysData(ephysKilosortPath, savePath);

        % which quality metric parameters to extract and thresholds
        % param_fsc = bc.qm.fsc_qualityParamValues(ephysMetaDir, ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);
        param = bc.qm.qualityParamValues(ephysMetaDir, ephysRawFile, ephysKilosortPath, gain_to_uV, kilosortVersion);
        % param = bc_qualityParamValuesForUnitMatch(ephysMetaDir, rawFile) % Run this if you want to use UnitMatch after


        %% compute quality metrics
        %[qMetric, unitType] = bc_runAllQualityMetrics(param, spikeTimes_samples, spikeTemplates, ...
        %    templateWaveforms, templateAmplitudes,pcFeatures,pcFeatureIdx,channelPositions, savePath);

        % swap out param for param_fsc
        [qMetric, unitType] = bc.qm.runAllQualityMetrics(param, spikeTimes_samples, spikeClusters, ...
        templateWaveforms, templateAmplitudes, pcFeatures, pcFeatureIdx, channelPositions, savePath);



        %% save to cluster_group.tsv
        % overwrite ecephys cluster labels if any units were found to be noise
        cluster_group_file = [ephysKilosortPath filesep 'cluster_group.tsv'];
        cluster_group = readtable(cluster_group_file, 'FileType', 'text', 'Delimiter', '\t');
        cluster_group(unitType==0,'group') = {'noise'};
        writetable(cluster_group, cluster_group_file, 'FileType', 'text', 'Delimiter', '\t');

    end
end
