clear; clc; close all;
carrier_freq = 3.5e9;
wavelength = physconst('LightSpeed') / carrier_freq;
sample_rate = 15.36e6;
num_symbols = 1024;
antenna_configs = [4,2; 8,4; 16,8; 4,4; 8,2];
scenarios(1).name = 'Indoor Office';
scenarios(1).type = 'Indoor';
scenarios(1).cdl_profile = 'CDL-A';
scenarios(1).delay_spread_range = [10e-9, 50e-9];
scenarios(1).snr_range = [0, 25];
scenarios(1).k_factor_range = [5, 15];
scenarios(1).probability = 0.25;
scenarios(1).velocity_range = [0, 3];
scenarios(2).name = 'Outdoor Urban LOS';
scenarios(2).type = 'Outdoor_Urban_LOS';
scenarios(2).cdl_profile = 'CDL-B';
scenarios(2).delay_spread_range = [50e-9, 150e-9];
scenarios(2).snr_range = [-5, 20];
scenarios(2).k_factor_range = [3, 10];
scenarios(2).probability = 0.20;
scenarios(2).velocity_range = [1, 10];
scenarios(3).name = 'Outdoor Urban NLOS';
scenarios(3).type = 'Outdoor_Urban_NLOS';
scenarios(3).cdl_profile = 'CDL-C';
scenarios(3).delay_spread_range = [100e-9, 300e-9];
scenarios(3).snr_range = [-10, 15];
scenarios(3).k_factor_range = [0, 3];
scenarios(3).probability = 0.35;
scenarios(3).velocity_range = [5, 20];
scenarios(4).name = 'Outdoor Canyon';
scenarios(4).type = 'Outdoor_Canyon';
scenarios(4).cdl_profile = 'CDL-D';
scenarios(4).delay_spread_range = [200e-9, 400e-9];
scenarios(4).snr_range = [-15, 10];
scenarios(4).k_factor_range = [0, 2];
scenarios(4).probability = 0.20;
scenarios(4).velocity_range = [10, 33.3];
impairment_prob.doppler = 1.00;
impairment_prob.phase_noise = 0.80;
impairment_prob.pa_nonlinear = 0.60;
impairment_prob.iq_imbalance = 0.50;
impairment_prob.colored_noise = 0.40;
impairment_prob.interference = 0.30;
num_samples = 100000;
modulation_schemes = {'QPSK', '16QAM', '64QAM'};
samples_per_scenario = zeros(4,1);
for i = 1:4
    samples_per_scenario(i) = round(num_samples * scenarios(i).probability);
end
samples_per_scenario(end) = num_samples - sum(samples_per_scenario(1:end-1));
num_features = 22;
dataset_features = zeros(num_samples, num_features);
dataset_labels = zeros(num_samples, 1);
snr_true_all = zeros(num_samples, 1);
snr_ls_all = zeros(num_samples, 1);
snr_ml_all = zeros(num_samples, 1);
snr_evm_all = zeros(num_samples, 1);
snr_m2m4_all = zeros(num_samples, 1);
snr_rao_all = zeros(num_samples, 1);
snr_dd_all = zeros(num_samples, 1);
scenario_type_all = cell(num_samples, 1);
cdl_profile_all = cell(num_samples, 1);
mod_scheme_all = cell(num_samples, 1);
imp_doppler_all = zeros(num_samples, 1);
imp_pn_all = zeros(num_samples, 1);
imp_pa_all = zeros(num_samples, 1);
imp_iq_all = zeros(num_samples, 1);
imp_cn_all = zeros(num_samples, 1);
imp_intf_all = zeros(num_samples, 1);
sample_idx = 1;
rng(42);
for scenario_idx = 1:4
    scenario = scenarios(scenario_idx);
    num_samples_this = samples_per_scenario(scenario_idx);
    for s = 1:num_samples_this
        config_idx = randi(size(antenna_configs,1));
        Nt = antenna_configs(config_idx, 1);
        Nr = antenna_configs(config_idx, 2);
        target_snr_db = scenario.snr_range(1) + diff(scenario.snr_range)*rand();
        if target_snr_db < 5
            mod_scheme = 'QPSK';
        elseif target_snr_db < 15
            mod_scheme = modulation_schemes{randi(2)};
        else
            mod_scheme = modulation_schemes{randi(3)};
        end
        switch mod_scheme
            case 'QPSK'
                mod_order = 4;
                data_bits = randi([0 1], num_symbols*2, 1);
                data_int = bi2de(reshape(data_bits,2,[]).','left-msb');
                tx_symbols = pskmod(data_int, mod_order, pi/4);
            case '16QAM'
                mod_order = 16;
                data_bits = randi([0 1], num_symbols*4, 1);
                data_int = bi2de(reshape(data_bits,4,[]).','left-msb');
                tx_symbols = qammod(data_int, mod_order,'UnitAveragePower',true);
            case '64QAM'
                mod_order = 64;
                data_bits = randi([0 1], num_symbols*6, 1);
                data_int = bi2de(reshape(data_bits,6,[]).','left-msb');
                tx_symbols = qammod(data_int, mod_order,'UnitAveragePower',true);
        end
        velocity = scenario.velocity_range(1) + diff(scenario.velocity_range)*rand();
        [cdl, H, path_delays, path_powers, h_eff] = generate_channel(...
            scenario.cdl_profile, scenario.delay_spread_range, ...
            carrier_freq, sample_rate, Nt, Nr, velocity, wavelength);
        rx_waveform = h_eff * tx_symbols;
        [rx_signal, imp_doppler_val, imp_pa_flag, imp_iq_flag, ...
         imp_pn_flag, imp_cn_flag, imp_intf_flag] = ...
            apply_impairments(rx_waveform, tx_symbols, ...
                target_snr_db, impairment_prob, velocity, carrier_freq);
        [snr_est_ls, snr_est_ml, snr_est_evm, snr_est_m2m4, ...
         snr_est_rao, snr_est_dd] = estimate_snr(rx_signal, tx_symbols, mod_scheme);
        features = compute_features(rx_signal, tx_symbols, H, h_eff, path_delays, ...
            path_powers, Nt, Nr, imp_pa_flag, imp_iq_flag, imp_doppler_val, ...
            imp_pn_flag, imp_cn_flag, imp_intf_flag);
        dataset_features(sample_idx, :) = features;
        dataset_labels(sample_idx) = target_snr_db;
        snr_true_all(sample_idx) = target_snr_db;
        snr_ls_all(sample_idx) = snr_est_ls;
        snr_ml_all(sample_idx) = snr_est_ml;
        snr_evm_all(sample_idx) = snr_est_evm;
        snr_m2m4_all(sample_idx) = snr_est_m2m4;
        snr_rao_all(sample_idx) = snr_est_rao;
        snr_dd_all(sample_idx) = snr_est_dd;
        scenario_type_all{sample_idx} = scenario.type;
        cdl_profile_all{sample_idx} = scenario.cdl_profile;
        mod_scheme_all{sample_idx} = mod_scheme;
        imp_doppler_all(sample_idx) = imp_doppler_val;
        imp_pn_all(sample_idx) = double(imp_pn_flag);
        imp_pa_all(sample_idx) = double(imp_pa_flag);
        imp_iq_all(sample_idx) = double(imp_iq_flag);
        imp_cn_all(sample_idx) = double(imp_cn_flag);
        imp_intf_all(sample_idx) = double(imp_intf_flag);
        sample_idx = sample_idx + 1;
    end
end
feature_names = {'Channel_Gain','Channel_Condition_Number','Channel_Rank', ...
    'RMS_Delay_Spread_ns','Coherence_BW_MHz','K_factor_dB', ...
    'Num_Paths','Max_Delay_ns','Rx_Power','Rx_Power_Std', ...
    'Rx_Phase_Mean','Equalized_Signal_Power','Equalized_Signal_Std', ...
    'Kurtosis','Num_Tx_Antennas','Num_Rx_Antennas', ...
    'Flag_PA_Nonlinear','Flag_IQ_Imbalance','Doppler_Hz', ...
    'Flag_PhaseNoise','Flag_ColoredNoise','Flag_Interference'};
data_table = array2table([dataset_features, dataset_labels], ...
    'VariableNames', [feature_names, {'SNR_dB'}]);
writetable(data_table,'Enhanced_5G_Dataset_100K.csv');
save('enhanced_baseline_results.mat', ...
     'snr_true_all','snr_ls_all','snr_ml_all', ...
     'snr_evm_all','snr_m2m4_all','snr_rao_all','snr_dd_all', ...
     'scenario_type_all','cdl_profile_all','mod_scheme_all', ...
     'imp_doppler_all','imp_pn_all','imp_pa_all', ...
     'imp_iq_all','imp_cn_all','imp_intf_all');
