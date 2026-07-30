function [cdl, H, path_delays, path_powers, h_eff] = generate_channel(...
    profile, delay_range, fc, fs, Nt, Nr, velocity, lambda)
    cdl = nrCDLChannel;
    cdl.DelayProfile = profile;
    cdl.DelaySpread = delay_range(1) + diff(delay_range)*rand();
    cdl.CarrierFrequency = fc;
    cdl.TransmitAntennaArray.Size = [Nt 1 1 1 1];
    cdl.ReceiveAntennaArray.Size = [Nr 1 1 1 1];
    cdl.SampleRate = fs;
    cdl.NormalizePathGains = true;
    cdl.NormalizeChannelOutputs = false;
    cdl.TransmitArrayOrientation = [0;0;0];
    cdl.ReceiveArrayOrientation = [0;0;0];
    info_cdl = info(cdl);
    path_delays = info_cdl.PathDelays;
    path_powers = info_cdl.AveragePathGains;
    tx_waveform = complex(randn(1024,Nt), randn(1024,Nt)) / sqrt(2);
    [~, pathGains, ~] = cdl(tx_waveform);
    H = reshape(mean(mean(pathGains,1),2), Nr, Nt);
    antenna_spacing = (0.4 + 0.2*rand()) * lambda;
    tx_angle = -60 + 120*rand();
    rx_angle = -60 + 120*rand();
    w_tx = exp(-1j*2*pi*antenna_spacing/lambda*(0:Nt-1)'*sind(tx_angle)) / sqrt(Nt);
    w_rx = exp(-1j*2*pi*antenna_spacing/lambda*(0:Nr-1)'*sind(rx_angle)) / sqrt(Nr);
    h_eff = w_rx' * H * w_tx;
end
