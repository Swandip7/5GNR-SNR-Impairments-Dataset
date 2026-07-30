function features = compute_features(rx_signal, tx, H, h_eff, path_delays, ...
    path_powers, Nt, Nr, flag_pa, flag_iq, doppler_hz, flag_pn, flag_cn, flag_intf)
    path_powers_linear = 10.^(path_powers/10);
    mean_delay = sum(path_delays .* path_powers_linear) / sum(path_powers_linear);
    rms_ds = sqrt(sum(((path_delays-mean_delay).^2).*path_powers_linear) / ...
                  sum(path_powers_linear));
    if rms_ds > 0
        coherence_bw = 1/(2*pi*rms_ds);
    else
        coherence_bw = 1e9;
    end
    sorted_pwr = sort(path_powers_linear,'descend');
    if length(sorted_pwr) > 1
        k_factor_est = 10*log10(sorted_pwr(1)/sum(sorted_pwr(2:end)));
    else
        k_factor_est = 30;
    end
    k_factor_est = max(-10, min(30, k_factor_est));
    M2 = mean(abs(rx_signal).^2);
    M4 = mean(abs(rx_signal).^4);
    kurtosis_stat = M4 / (M2^2 + 1e-30);
    if noise_var_ls > 0
        mmse_eq = conj(h_est_ls) / (abs(h_est_ls)^2 + noise_var_ls);
    else
        mmse_eq = conj(h_est_ls) / (abs(h_est_ls)^2 + 1e-12);
    end
    rx_symbols_eq = rx_signal .* mmse_eq;
    features = [
        abs(h_eff)^2;
        cond(H);
        rank(H);
        rms_ds*1e9;
        coherence_bw/1e6;
        k_factor_est;
        length(path_delays);
        max(path_delays)*1e9;
        mean(abs(rx_signal).^2);
        std(abs(rx_signal).^2);
        mean(angle(rx_signal));
        mean(abs(rx_symbols_eq).^2);
        std(abs(rx_symbols_eq));
        kurtosis_stat;
        Nt;
        Nr;
        double(flag_pa);
        double(flag_iq);
        doppler_hz;
        double(flag_pn);
        double(flag_cn);
        double(flag_intf)
    ];
end
