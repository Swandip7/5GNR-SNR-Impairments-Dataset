function [rx_out, doppler_hz, flag_pa, flag_iq, flag_pn, flag_cn, flag_intf] = ...
    apply_impairments(rx_clean, tx, target_snr_db, imp_prob, velocity, fc)
    num_sym = length(rx_clean);
    signal_power = mean(abs(rx_clean).^2);
    noise_power = signal_power / (10^(target_snr_db/10));
    flag_pa = rand() < imp_prob.pa_nonlinear;
    if flag_pa
        alpha_pa = 0.05 + 0.15*rand();
        tx = tx ./ (1 + alpha_pa * abs(tx).^2);
        tx = tx / sqrt(mean(abs(tx).^2) + 1e-12);
    end
    flag_iq = rand() < imp_prob.iq_imbalance;
    if flag_iq
        gain_imb_dB = 0.3 + 1.2*rand();
        phase_imb_deg = 1 + 4*rand();
        g = 10^(gain_imb_dB/20);
        ph = phase_imb_deg * pi/180;
        alpha_iq = (1 + g*exp(1j*ph)) / 2;
        beta_iq = (1 - g*exp(1j*ph)) / 2;
        tx = alpha_iq * tx + beta_iq * conj(tx);
    end
    rx_signal = h_eff * tx;
    f_doppler = velocity * fc / physconst('LightSpeed');
    t_vec = (0:num_sym-1)' / sample_rate;
    doppler_phase = exp(1j * 2*pi * f_doppler * t_vec);
    rx_signal = rx_signal .* doppler_phase;
    doppler_hz = f_doppler;
    flag_cn = rand() < imp_prob.colored_noise;
    if flag_cn
        rho_ar = 0.3 + 0.5*rand();
        n_white = sqrt(noise_power/2) * (randn(num_sym,1)+1j*randn(num_sym,1));
        noise = zeros(num_sym,1);
        noise(1) = n_white(1);
        for k = 2:num_sym
            noise(k) = rho_ar*noise(k-1) + sqrt(1-rho_ar^2)*n_white(k);
        end
        noise = noise * sqrt(noise_power / (mean(abs(noise).^2)+1e-12));
    else
        noise = sqrt(noise_power/2) * (randn(num_sym,1)+1j*randn(num_sym,1));
    end
    if rand() < 0.10
        imp_idx = randperm(num_sym, ceil(num_sym*0.02));
        imp_pwr = noise_power * (5+10*rand());
        noise(imp_idx) = noise(imp_idx) + ...
            sqrt(imp_pwr/2)*(randn(length(imp_idx),1)+1j*randn(length(imp_idx),1));
    end
    flag_intf = rand() < imp_prob.interference;
    if flag_intf
        SIR_dB = 5 + 15*rand();
        SIR_lin = 10^(SIR_dB/10);
        intf_power = signal_power / SIR_lin;
        interferer = sqrt(intf_power) * (2*randi([0 1],num_sym,1)-1);
        rx_signal = rx_signal + noise + interferer;
    else
        rx_signal = rx_signal + noise;
    end
    flag_pn = rand() < imp_prob.phase_noise;
    if flag_pn
        sigma_pn = sqrt(10^(-80/10));
        delta_phi = sigma_pn * randn(num_sym,1);
        phi_pn = cumsum(delta_phi);
        rx_signal = rx_signal .* exp(1j*phi_pn);
    end
    rx_out = rx_signal;
end
