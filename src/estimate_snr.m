function [snr_ls, snr_ml, snr_evm, snr_m2m4, snr_rao, snr_dd] = ...
    estimate_snr(rx_signal, tx_symbols, mod_scheme)
    num_sym = length(rx_signal);
    pilot_spacing = 10;
    pilot_indices = 1:pilot_spacing:num_sym;
    num_pilots = length(pilot_indices);
    pilot_symbols = tx_symbols(pilot_indices);
    rx_pilots = rx_signal(pilot_indices);
    h_est_ls = mean(rx_pilots ./ pilot_symbols);
    pilot_err_ls = rx_pilots - h_est_ls * pilot_symbols;
    noise_var_ls = var(pilot_err_ls);
    ch_power_ls = abs(h_est_ls)^2;
    if noise_var_ls > 1e-12 && ch_power_ls > 1e-12
        snr_ls = 10*log10(ch_power_ls / noise_var_ls);
    else
        snr_ls = target_snr_db;
    end
    snr_ls = max(-30, min(50, real(snr_ls)));
    h_est_ml = h_est_ls;
    residuals_ml = rx_pilots - h_est_ml * pilot_symbols;
    sigma2_ml = (1/num_pilots) * sum(abs(residuals_ml).^2);
    ch_power_ml = abs(h_est_ml)^2;
    if sigma2_ml > 1e-12 && ch_power_ml > 1e-12
        snr_ml = 10*log10(ch_power_ml / sigma2_ml);
    else
        snr_ml = target_snr_db;
    end
    snr_ml = max(-30, min(50, real(snr_ml)));
    if noise_var_ls > 0
        mmse_eq = conj(h_est_ls) / (abs(h_est_ls)^2 + noise_var_ls);
    else
        mmse_eq = conj(h_est_ls) / (abs(h_est_ls)^2 + 1e-12);
    end
    rx_symbols_eq = rx_signal .* mmse_eq;
    error_evm = rx_symbols_eq - tx_symbols;
    evm2 = mean(abs(error_evm).^2) / (mean(abs(tx_symbols).^2) + 1e-12);
    if evm2 > 1e-12
        snr_evm = 10*log10(1/evm2);
    else
        snr_evm = 50;
    end
    snr_evm = max(-30, min(50, real(snr_evm)));
    y = rx_signal;
    M2_y = mean(abs(y).^2);
    M4_y = mean(abs(y).^4);
    inner_m2m4 = 2*M2_y^2 - M4_y;
    if inner_m2m4 > 0
        sqrt_term = sqrt(inner_m2m4);
        denominator = M2_y - sqrt_term;
        if denominator > 1e-12
            snr_m2m4 = 10*log10(sqrt_term / denominator);
        else
            snr_m2m4 = 50;
        end
    else
        snr_m2m4 = 50;
    end
    snr_m2m4 = max(-30, min(50, real(snr_m2m4)));
    P_signal_rao = mean(abs(y).^2);
    sigma2_rao = var(real(y)) + var(imag(y));
    if sigma2_rao > 1e-12
        snr_rao = 10*log10(P_signal_rao / sigma2_rao);
    else
        snr_rao = 50;
    end
    snr_rao = max(-30, min(50, real(snr_rao)));
    switch mod_scheme
        case 'QPSK'
            rx_ints_dd = pskdemod(rx_symbols_eq, 4, pi/4);
            x_hat_dd = pskmod(rx_ints_dd, 4, pi/4);
        case '16QAM'
            rx_ints_dd = qamdemod(rx_symbols_eq, 16, 'UnitAveragePower', true);
            x_hat_dd = qammod(rx_ints_dd, 16, 'UnitAveragePower', true);
        case '64QAM'
            rx_ints_dd = qamdemod(rx_symbols_eq, 64, 'UnitAveragePower', true);
            x_hat_dd = qammod(rx_ints_dd, 64, 'UnitAveragePower', true);
    end
    e_dd = rx_symbols_eq - x_hat_dd;
    err_pow_dd = mean(abs(e_dd).^2);
    sig_pow_dd = mean(abs(x_hat_dd).^2);
    if err_pow_dd > 1e-12
        snr_dd = 10*log10(sig_pow_dd / err_pow_dd);
    else
        snr_dd = 50;
    end
    snr_dd = max(-30, min(50, real(snr_dd)));
end
