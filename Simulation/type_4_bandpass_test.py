import numpy as np
import matplotlib.pyplot as plt
from typing import List
# ----------------------------------------------------
# 1. Filter coefficients (Q1.15 → float)
# ----------------------------------------------------
def iir_bandpass_filter(x: List[float]) -> np.ndarray:
    """
    Implements a 4th-order IIR bandpass filter (direct form I) in Python
    using the coefficients from your VHDL Q1.15 filter.
    """
    # Coefficients (same as VHDL, converted to float)
    b = np.array([19094, 0, -38187, 0, 19094], dtype=float) / 2**15
    a = np.array([1.0, -22507, -26735, 6359, 11377], dtype=float) / 2**15

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


# ----------------------------------------------------
# 2. Read VHDL output file
#    (assuming each line looks like: "Time: XX ns  y_out = YY")
# ----------------------------------------------------
x_values = []
vhdl_outputs = []
with open("type_4_bandpass_test.txt", "r") as f:
    for line in f:
        if "y_out" in line:
            x,y = line.strip().split(";")
            x_values.append(int(x.split("=")[1].strip()))
            vhdl_outputs.append(int(y.split("=")[1].strip()) / 2**15)  # Convert Q1.15 to float

vhdl_outputs = np.array(vhdl_outputs, dtype=float)

# ----------------------------------------------------
# 3. Generate Python reference output (impulse response)
# ----------------------------------------------------
# Create an impulse input of same length as VHDL outputs


# Filter using scipy
py_outputs = iir_bandpass_filter(np.array(x_values, dtype=float))

# ----------------------------------------------------
# 4. Compute MSE
# ----------------------------------------------------
min_len = min(len(vhdl_outputs), len(py_outputs))
mse = np.mean((vhdl_outputs[:min_len] - py_outputs[:min_len])**2)

print(f"Mean Squared Error (MSE) = {mse:.6e}")

print("X Values :", x_values)
print("VHDL Outputs (first 10 samples):", vhdl_outputs)
print("Python Outputs (first 10 samples):", py_outputs)

# ----------------------------------------------------
# 5. Optional: Plot comparison
# ----------------------------------------------------
plt.figure(figsize=(10,5))
plt.plot(vhdl_outputs, 'o-', label="VHDL Output")
plt.plot(py_outputs, 'x-', label="Python Reference")
plt.title("Impulse Response Comparison")
plt.xlabel("Sample index")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)
plt.show()
