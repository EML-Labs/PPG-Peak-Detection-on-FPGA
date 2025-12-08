import numpy as np
import matplotlib.pyplot as plt
from typing import List
import math

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


# Read VHDL output file
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


bandpass_py_outputs = iir_bandpass_filter_q15(np.array(x_values, dtype=float))
bandpass_py_outputs = np.insert(bandpass_py_outputs, 0, 0.0)

abs_py_outputs = absolute_value(np.array(bandpass_py_outputs, dtype=float))

print(abs_py_outputs)

ma_py_outputs = moving_average(abs_py_outputs, window_size=30, use_floor=False)
print(ma_py_outputs)

lowpass_py_outputs = iir_lowpass_filter_q15(np.array(ma_py_outputs, dtype=float))
print(lowpass_py_outputs)

plt.figure(figsize=(12, 6))

plt.plot(x_values, label="Input (x_values)", color='gray', alpha=0.7)
plt.plot(vhdl_outputs, label="VHDL Output", color='red')
plt.plot(lowpass_py_outputs, label="Python Output", color='blue')


plt.title("Comparison of Input, VHDL Output, and MA(Python Output)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
plt.savefig('preprocessing_pipeline_comparison_100000.png', dpi=300)
plt.show()