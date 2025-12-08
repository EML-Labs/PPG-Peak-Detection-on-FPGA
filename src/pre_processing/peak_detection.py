import numpy as np
import matplotlib.pyplot as plt
from typing import List
import math

plt.rcParams.update({
        "font.size": 12,
        "font.family": "serif",
        "axes.titlesize": 14,
        "axes.labelsize": 13,
        "legend.fontsize": 11,
        "xtick.labelsize": 11,
        "ytick.labelsize": 11,
        "figure.dpi": 300
    })


# ----------------------------------------------------
# 1. Filter coefficients (Q1.15 → float)
# ----------------------------------------------------
def iir_bandpass_filter(x: List[float]) -> np.ndarray:
    """
    Implements a 4th-order IIR bandpass filter (direct form I) in Python
    using the coefficients from your VHDL Q1.15 filter.
    """
    # Coefficients (same as VHDL, converted to float)
    b = np.array([625451352, 0, -1251168932, 0, 625451352], dtype=float) / 2**30
    a = np.array([1.0, -737915354, -875560496, 208097889, 373198311], dtype=float) / 2**30

    y = np.zeros_like(x, dtype=float)

    # Direct Form I implementation
    for n in range(len(x)):
        # Feedforward part
        for k in range(len(b)):
            if n - k >= 0:
                y[n] += b[k] * x[n - k]
        # Feedback part (skip a[0])
        for k in range(1, len(a)):
            if n - k >= 0:
                y[n] -= a[k] * y[n - k]

    return y

def iir_bandpass_filter_q15(x: List[float]) -> np.ndarray:
    """
    Bit-accurate Python simulation of your VHDL bandpass filter.
    Replicates Q2.30 coefficients, Q1.15 input/output, and rounding/saturation.
    """

    # === Fixed-point constants ===
    Q15_SCALE = 2 ** 15
    Q30_SCALE = 2 ** 30
    MAX_Q15 = 32767
    MIN_Q15 = -32768

    # === Coefficients from VHDL === (Q2.30)
    b = np.array([625451352, 0, -1251168932, 0, 625451352], dtype=int)
    a = np.array([-737915354, -875560496, 208097889, 373198311], dtype=int)

    # === Initialize delay lines ===
    x_reg = np.zeros(5, dtype=int)   # x[0..4], Q1.15
    y_reg = np.zeros(5, dtype=int)   # y[1..4] valid, y[0] unused

    y_out = np.zeros(len(x), dtype=float)

    for n in range(len(x)):
        # Convert input to Q1.15
        x_q15 = int(np.clip(round(x[n] * Q15_SCALE), MIN_Q15, MAX_Q15))

        # 56-bit accumulator (to avoid overflow)
        acc = 0

        # Feedforward part: b0*x_in + b1*x1 + ... + b4*x4
        acc += b[0] * x_q15
        acc += b[1] * x_reg[0]
        acc += b[2] * x_reg[1]
        acc += b[3] * x_reg[2]
        acc += b[4] * x_reg[3]

        # Feedback part: - (a1*y1 + a2*y2 + a3*y3 + a4*y4)
        acc -= a[0] * y_reg[1]
        acc -= a[1] * y_reg[2]
        acc -= a[2] * y_reg[3]
        acc -= a[3] * y_reg[4]

        # Normalize back to Q1.15 (right shift by 30)
        y_q15 = acc >> 30

        # Saturate to Q1.15 range
        y_q15 = max(min(y_q15, MAX_Q15), MIN_Q15)

        # Update delay lines
        x_reg[1:5] = x_reg[0:4]
        x_reg[0] = x_q15

        y_reg[2:5] = y_reg[1:4]
        y_reg[1] = y_q15

        # Convert to float output
        y_out[n] = y_q15 / Q15_SCALE

    return y_out

def absolute_value(x: List[float]) -> np.ndarray:
    return np.abs(x)

def moving_average(x: List[float], window_size: int = 30, use_floor: bool = False):
    n = window_size
    integrated_signal = np.zeros_like(x, dtype=float)
    running_sum = 0.0
    registers = [0.0] * n
    ptr = 0  # points to the oldest element

    for i in range(len(x)):
        oldest = registers[ptr]  # equivalent to shift_reg[n-1] in VHDL
        running_sum = running_sum - oldest + x[i]
        integrated_signal[i] = running_sum
        registers[ptr] = x[i]  # replace oldest sample
        ptr = (ptr + 1) % n  # move pointer to next oldest sample

    # Divide by window size to get the average
    result = integrated_signal / n

    # Optional floor
    if use_floor:
        result = np.array([math.floor(val) for val in result])

    return result


import numpy as np
from typing import List

def iir_lowpass_filter_q15(x: List[float]) -> np.ndarray:
    """
    Bit-accurate Python simulation of your VHDL Type-1 lowpass filter.
    Emulates Q1.15 fixed-point arithmetic and saturation.
    """

    # === Fixed-point constants ===
    Q15_SCALE = 2 ** 15
    MAX_Q15 = 32767
    MIN_Q15 = -32768

    # === Coefficients (Q1.15 integers) ===
    b0 = 1937
    b1 = 1937
    a1 = -28888  # already signed

    # === Initialize delay registers ===
    x_reg = 0   # x[n-1]
    y_reg = 0   # y[n-1]
    
    y_out = np.zeros(len(x), dtype=float)

    for n in range(len(x)):
        # Convert input sample to Q1.15
        x_q15 = int(np.clip(round(x[n] * Q15_SCALE), MIN_Q15, MAX_Q15))

        # 40-bit accumulator (as in VHDL)
        acc = 0

        # y[n] = b0*x[n] + b1*x[n-1] - a1*y[n-1]
        acc += b0 * x_q15
        acc += b1 * x_reg
        acc -= a1 * y_reg  # minus a1*y[n-1] since VHDL subtracts it

        # Normalize back to Q1.15 (right shift by 15)
        y_q15 = acc >> 15

        # Saturate to 16-bit signed range
        if y_q15 > MAX_Q15:
            y_q15 = MAX_Q15
        elif y_q15 < MIN_Q15:
            y_q15 = MIN_Q15

        # Update delay lines
        x_reg = x_q15
        y_reg = y_q15

        # Convert to float output
        y_out[n] = y_q15 / Q15_SCALE

    return y_out

def peak_detection(signal: np.ndarray, min_distance: int = 50) -> np.ndarray:
    """
    Detect peaks in a 1D signal using the same logic as your VHDL peak_detector.

    Args:
        signal: Input 1D array (e.g., output of lowpass filter).
        min_distance: Minimum samples between consecutive peaks (equivalent to counter in VHDL).

    Returns:
        peaks: Binary array of same length as signal. 1 indicates a peak detected.
    """
    peaks = np.zeros_like(signal, dtype=int)
    x_prev2 = 0
    x_prev1 = 0
    counter = min_distance  # initialize to allow first peak detection

    for i in range(len(signal)):
        x_curr = signal[i]

        # detect peak at middle sample
        peak_detected_local = int((x_prev1 > x_prev2) and (x_prev1 > x_curr))

        # time validation (refractory period)
        if peak_detected_local and counter >= min_distance:
            peaks[i - 1] = 1  # middle sample is a peak
            counter = 0
        else:
            peaks[i - 1] = 0
            counter += 1

        # shift samples
        x_prev2 = x_prev1
        x_prev1 = x_curr

    # handle first sample
    peaks[0] = 0
    return peaks


# Initialize lists for each output
ppg_values      = []
bp_outputs      = []
abs_outputs     = []
ma_outputs      = []
lp_outputs      = []
final_outputs   = []
peak_detected   = []

# Read VHDL output file
with open("filter_output.txt", "r") as f:
    for line in f:
        parts = line.strip().split(',')
        if len(parts) >= 7:
            try:
                ppg_values.append(float(parts[0].strip()))
                bp_outputs.append(float(parts[1].strip()) / 32768.0)     # Q1.15 → float
                abs_outputs.append(float(parts[2].strip()) / 32768.0)
                ma_outputs.append(float(parts[3].strip()) / 32768.0)
                lp_outputs.append(float(parts[4].strip()) / 32768.0)
                final_outputs.append(float(parts[5].strip()) / 32768.0)
                peak_detected.append(int(parts[6].strip()))             # 0 or 1
            except ValueError:
                continue  # Skip lines that don't parse correctly

# Convert to numpy arrays
ppg_values      = np.array(ppg_values, dtype=float)
bp_outputs      = np.array(bp_outputs, dtype=float)
abs_outputs     = np.array(abs_outputs, dtype=float)
ma_outputs      = np.array(ma_outputs, dtype=float)
lp_outputs      = np.array(lp_outputs, dtype=float)
final_outputs   = np.array(final_outputs, dtype=float)
peak_detected   = np.array(peak_detected, dtype=int)


bandpass_py_outputs = iir_bandpass_filter_q15(np.array(ppg_values, dtype=float))
bandpass_py_outputs = np.insert(bandpass_py_outputs, 0, 0.0)

abs_py_outputs = absolute_value(np.array(bandpass_py_outputs, dtype=float))

print(abs_py_outputs)

ma_py_outputs = moving_average(abs_py_outputs, window_size=30, use_floor=False)
print(ma_py_outputs)

lowpass_py_outputs = iir_lowpass_filter_q15(np.array(ma_py_outputs, dtype=float))
print(lowpass_py_outputs)

# Detect peaks on the lowpass output
peaks_py = peak_detection(lowpass_py_outputs, min_distance=50)

# Define sample range
start_idx = 50
end_idx = 550

# Slice arrays
ppg_slice      = ppg_values[start_idx:end_idx]
bp_vhdl_slice  = bp_outputs[start_idx:end_idx]
bp_py_slice    = bandpass_py_outputs[start_idx:end_idx]
abs_vhdl_slice = abs_outputs[start_idx:end_idx]
abs_py_slice   = abs_py_outputs[start_idx:end_idx]
ma_vhdl_slice  = ma_outputs[start_idx:end_idx]
ma_py_slice    = ma_py_outputs[start_idx:end_idx]
lp_vhdl_slice  = lp_outputs[start_idx:end_idx]
lp_py_slice    = lowpass_py_outputs[start_idx:end_idx]
peaks_vhdl_slice = peak_detected[start_idx:end_idx]
peaks_py_slice   = peaks_py[start_idx:end_idx]

plt.figure(figsize=(15, 12))

# 1. Original PPG
plt.subplot(5, 1, 1)
plt.plot(ppg_slice, color='gray')
plt.title("Original PPG Signal")
plt.ylabel("Amplitude")
plt.grid(True, linestyle='--', alpha=0.5)

# 2. Bandpass filter output
plt.subplot(5, 1, 2)
plt.plot(bp_vhdl_slice, label="VHDL BP Output", color='red', alpha=0.7)
plt.plot(bp_py_slice, label="Python BP Output", color='blue', alpha=0.7)
plt.title("Bandpass Filter Output")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)

# 3. Absolute value
plt.subplot(5, 1, 3)
plt.plot(abs_vhdl_slice, label="VHDL ABS Output", color='red', alpha=0.7)
plt.plot(abs_py_slice, label="Python ABS Output", color='blue', alpha=0.7)
plt.title("Absolute Value Output")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)

# 4. Moving average
plt.subplot(5, 1, 4)
plt.plot(ma_vhdl_slice, label="VHDL MA Output", color='red', alpha=0.7)
plt.plot(ma_py_slice, label="Python MA Output", color='blue', alpha=0.7)
plt.title("Moving Average Output")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)

# 5. Lowpass + Peak Detection
plt.subplot(5, 1, 5)
plt.plot(lp_vhdl_slice, label="VHDL LP Output", color='red', alpha=0.7)
plt.plot(lp_py_slice, label="Python LP Output", color='blue', alpha=0.7)
# Mark peaks
plt.plot(np.where(peaks_vhdl_slice)[0], lp_vhdl_slice[peaks_vhdl_slice == 1], 'ro', label="VHDL Peaks")
plt.plot(np.where(peaks_py_slice)[0], lp_py_slice[peaks_py_slice == 1], 'kx', label="Python Peaks")
plt.title("Lowpass Output with Detected Peaks (Samples 50–550)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)

plt.tight_layout()
plt.savefig("ppg_processing_pipeline.png", dpi=300, transparent=True)
plt.show()
