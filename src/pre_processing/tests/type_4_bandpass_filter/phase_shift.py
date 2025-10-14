import numpy as np
from scipy.signal import csd
import matplotlib.pyplot as plt

# Load signals (make sure they are the same length and aligned sample-by-sample)
float_out = np.loadtxt("python_bandpass_output.txt")
fs = 125.0

x_values = []
vhdl_outputs = []
with open("filter_output.txt", "r") as f:
    for line in f:
        parts = line.strip().split(',')
        if len(parts) >= 2:
            x_str = parts[0].strip()
            y_str = parts[1].strip()
            try:
                x_val = float(x_str)
                y_val = float(y_str) / 32768.0  # Convert from Q1.15 to float
                x_values.append(x_val)
                vhdl_outputs.append(y_val)
            except ValueError:
                continue  # Skip lines that don't parse correctly
x_values = np.array(x_values, dtype=float)
vhdl_outputs = np.array(vhdl_outputs, dtype=float)

# Normalize for fair comparison
float_out = float_out / np.max(np.abs(float_out))
fixed_out = vhdl_outputs / np.max(np.abs(vhdl_outputs))

corr = np.correlate(fixed_out, float_out, mode='full')
lag = np.argmax(corr) - (len(float_out) - 1)
print(f"Integer lag: {lag} samples")

# Cross spectral density
f, Pxy = csd(float_out, fixed_out, fs=1000, nperseg=1024)

# Phase difference (in radians)
phase_diff = np.angle(Pxy)

# Convert to time delay (fractional)
valid = (f > 0) & np.isfinite(phase_diff)
delay = np.zeros_like(phase_diff)
delay[valid] = -phase_diff[valid] / (2 * np.pi * f[valid])

# Average over valid frequencies (excluding DC)
mean_delay = np.mean(delay[valid & (f > 0)])
print(f"Estimated fractional delay: {mean_delay:.6f} seconds (or {mean_delay * fs:.3f} samples)")


plt.figure()
plt.plot(float_out, label="Python (float)")
plt.plot(fixed_out, label="VHDL (fixed)")
plt.legend()
plt.title("Time-domain comparison")
plt.show()


