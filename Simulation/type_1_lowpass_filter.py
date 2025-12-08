import numpy as np
from scipy.signal import lfilter
import matplotlib.pyplot as plt

def butter_lp_order1(x):
    """
    Apply 1st-order Butterworth lowpass:
      H(z) = (0.0591 + 0.0591 z^-1) / (1 - 0.8816 z^-1)
    x : 1D numpy array (input samples)
    returns y : 1D numpy array (filtered output)
    """
    b0, b1 = 0.0591, 0.0591
    a1 = 0.8816  # from rearranged difference equation y[n] = b0*x[n] + b1*x[n-1] + a1*y[n-1]

    N = len(x)
    y = np.zeros(N, dtype=float)

    for n in range(N):
        # feedforward
        y_n = b0 * x[n]
        
        # Cleaner way to handle edge cases
        if n >= 1:
            y_n += b1 * x[n-1]  # Past input
            y_n += a1 * y[n-1]  # Past output feedback
        
        y[n] = y_n

    return y

def compare_with_vhdl_output(custom_output, file_path=None):
    """
    Compare Python simulation with VHDL simulation output
    """
    if file_path:
        try:
            vhdl_output = []
            with open(file_path, 'r') as f:
                for line in f:
                    parts = line.strip().split(';')
                    if len(parts) >= 2:
                        # Extract y_out value from VHDL output
                        y_str = parts[1].strip().split('=')[1].strip()
                        vhdl_output.append(float(y_str) / 32768.0)  # Convert from Q1.15 to float
                
            return np.array(vhdl_output)
        except Exception as e:
            print(f"Error reading VHDL output: {e}")
            return None
    return None

# ---- impulse test ----
N = 100  # length of impulse response
impulse = np.zeros(N)
impulse[5] = 1.0  # Place impulse at the beginning for easier analysis

y_custom = butter_lp_order1(impulse)

# Compare with scipy
b = [0.0591, 0.0591]
a = [1.0, -0.8816]
y_scipy = lfilter(b, a, impulse)

# Try to load VHDL results if available
vhdl_file = "../src/type_1_lowpass_filter/lowpass_output.txt"
y_vhdl = compare_with_vhdl_output(y_custom, vhdl_file)

# Plot the results for comparison
plt.figure(figsize=(12, 6))
plt.plot(y_custom[:50], 'b-', label='Custom Implementation')
plt.plot(y_scipy[:50], 'r--', label='SciPy Implementation')

if y_vhdl is not None:
    # Plot VHDL results, accounting for possible one-sample delay
    plt.plot(y_vhdl[:50], 'g-.', label='VHDL Implementation')
    
    # Calculate and display maximum error
    max_error = np.max(np.abs(y_custom[:len(y_vhdl)] - y_vhdl[:len(y_custom)]))
    print(f"Maximum error between custom and VHDL: {max_error:.6f}")
    
    # Check if there's a one-sample delay
    shifted_custom = np.zeros_like(y_custom)
    shifted_custom[1:] = y_custom[:-1]  # Shift by one sample
    max_error_shifted = np.max(np.abs(shifted_custom[:len(y_vhdl)] - y_vhdl[:len(shifted_custom)]))
    print(f"Maximum error with one-sample delay: {max_error_shifted:.6f}")

plt.title('First-Order Butterworth Lowpass Filter Response')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.savefig('lowpass_filter_comparison.png')
plt.show()

print("\nFirst 10 samples (custom):", y_custom[:10])
print("First 10 samples (scipy): ", y_scipy[:10])
if y_vhdl is not None:
    print("First 10 samples (VHDL):  ", y_vhdl[:10])
