# 5G NR SNR Estimation under Cross-Scenario Domain Generalization

This repository contains the MATLAB implementation used to generate a synthetic dataset for robust Signal-to-Noise Ratio (SNR) estimation in 5G New Radio (NR) systems. The framework combines standardized 3GPP channel models, realistic RF impairments, pilot-based equalization, feature engineering, and cross-domain evaluation.

---

## Overview

Reliable SNR estimation is fundamental for adaptive modulation, coding, beamforming, and link adaptation in modern wireless communication systems. This project investigates **cross-scenario domain generalization**, where models are trained on multiple propagation environments and evaluated on an unseen channel scenario.

The complete pipeline includes:

- 5G NR waveform generation
- 3GPP TR 38.901 CDL channel simulation
- Random MIMO beamforming
- Realistic RF impairment injection
- Pilot-based LS/MMSE equalization
- Feature extraction
- Cross-domain SNR estimation

---

## Dataset Generation

The dataset is generated entirely using MATLAB simulation.

### System Configuration

| Parameter | Value |
|-----------|-------|
| Carrier Frequency | 3.5 GHz |
| Sampling Rate | 15.36 MHz |
| Modulation | QPSK, 16-QAM, 64-QAM |
| Channel Standard | 3GPP TR 38.901 |
| Channel Profiles | CDL-A, CDL-B, CDL-C, CDL-D |

The channel response is modeled as

\[
H[k]=\sum_{n=1}^{N_{\text{paths}}}\alpha_n e^{-j2\pi k\Delta f\tau_n}.
\]

Random MIMO beamforming is applied using randomized antenna spacing and steering directions to increase channel diversity.

---

## RF Impairment Modeling

Each generated sample includes additive white Gaussian noise (AWGN), impulsive noise, and realistic RF hardware impairments.

### Noise

- Additive White Gaussian Noise (AWGN)
- Impulsive Noise
  - Injection probability: **10%**
  - Approximately **2%** of symbols affected when present

### RF Impairments

| Impairment | Probability |
|------------|------------:|
| Doppler Shift | 100% |
| Power Amplifier Nonlinearity | 60% |
| IQ Imbalance | 50% |
| Oscillator Phase Noise | 80% |
| Colored Noise | 40% |
| Co-channel Interference | 30% |

---

## Receiver Processing

The receiver performs

- Pilot insertion (every 10 symbols)
- Least Squares (LS) channel estimation
- MMSE equalization
- Feature extraction

The MMSE equalizer is

\[
g_{\text{MMSE}}
=
\frac{\hat h_{\text{LS}}^{*}}
{|\hat h_{\text{LS}}|^2+\hat\sigma_n^2}.
\]

---

## Feature Extraction

Each sample is represented by a **16-dimensional feature vector**.

### Channel Features

- Channel gain
- Channel rank
- Condition number
- Delay spread
- Coherence bandwidth
- Rician K-factor
- Number of propagation paths
- Maximum delay

### Signal Features

- Received power
- Received power standard deviation
- Mean received phase
- Equalized power
- Equalized power standard deviation
- Kurtosis

### Configuration Features

- Number of transmit antennas
- Number of receive antennas

All features are standardized using statistics computed from the training set.

---

## Dataset Statistics

| Profile | Delay Spread | SNR Range | Samples |
|----------|-------------:|----------:|---------:|
| CDL-A | 10–50 ns | 0 to 25 dB | 25,000 |
| CDL-B | 50–150 ns | -5 to 20 dB | 20,000 |
| CDL-C | 100–300 ns | -10 to 15 dB | 35,000 |
| CDL-D | 200–400 ns | -15 to 10 dB | 20,000 |

**Total Samples:** **100,000**

---

## Evaluation Protocol

A strict **Leave-One-CDL-Profile-Out (LOCO)** protocol is adopted.

For each experiment:

- Train on three CDL profiles.
- Reserve the remaining CDL profile as the unseen target domain.
- Repeat until every CDL profile has served as the target domain.

---

## Repository Structure

```text
.
├── data_generation/
│   ├── generate_dataset.m
│   ├── cdl_channel.m
│   ├── apply_impairments.m
│   ├── feature_extraction.m
│   └── utils/
│
├── models/
├── dataset/
├── figures/
├── results/
└── README.md
```

---

## Requirements

- MATLAB R2023a or newer
- 5G Toolbox
- Communications Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

---

## Citation

If you use this repository in your research, please cite the associated paper.

```bibtex
@article{YourPaper2026,
  title={Domain-Generalized SNR Estimation for 5G NR Using Transfer Learning and Explainable AI},
  author={Author Names},
  journal={IEEE Wireless Communications Letters},
  year={2026}
}
```

---

## License

This repository is released for academic and research purposes. If you use this code or dataset in your work, please cite the associated publication.
