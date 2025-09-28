import numpy as np
from scipy.signal import lfilter
import matplotlib.pyplot as plt

# your filter function (from before)
def butterworth_bandpass_filter(x):
    b = [0.5825, 0.0, -1.1650, 0.0, 0.5825]
    a = [1.0, -0.6874, -0.8157, 0.1939, 0.3477]

    x = np.asarray(x, dtype=float)
    y = np.zeros_like(x)

    for n in range(len(x)):
        for k in range(len(b)):
            if n - k >= 0:
                y[n] += b[k] * x[n - k]
        for k in range(1, len(a)):
            if n - k >= 0:
                y[n] -= a[k] * y[n - k]
    return y

# ---- impulse test ----
N = 50  # length of impulse response
impulse = np.zeros(N)
impulse[4] = 1.0

y_custom = butterworth_bandpass_filter(impulse)

# Compare with scipy
b = [0.5825, 0.0, -1.1650, 0.0, 0.5825]
a = [1.0, -0.6874, -0.8157, 0.1939, 0.3477]
y_scipy = lfilter(b, a, impulse)

print("First 10 samples (custom):", y_custom)
print("First 10 samples (scipy): ", y_scipy)

# Check difference
print("Max abs diff:", np.max(np.abs(y_custom - y_scipy)))

# Plotting
