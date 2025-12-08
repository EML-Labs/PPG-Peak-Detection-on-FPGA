import numpy as np
from scipy.signal import lfilter
import matplotlib.pyplot as plt
import os

# Function to calculate Mean Squared Error (MSE)
def calculate_mse(actual, predicted):
    """Calculate Mean Squared Error between two signals"""
    if len(actual) != len(predicted):
        raise ValueError("Both signals must have the same length")
    
    mse = np.mean((actual - predicted) ** 2)
    return mse

# Path to the VHDL output file
vhdl_output_file = "../src/type_4_bandpass_filter/filter_output.txt"

# Function to parse VHDL output
def parse_vhdl_output(file_path):
    x_in = []
    y_out = []
    acc = []
    y_out_float = []
    
    with open(file_path, 'r') as f:
        for line in f:
            parts = line.strip().split(';')
            x_in.append(int(parts[0].split('=')[1].strip()))
            y_out.append(int(parts[1].split('=')[1].strip()))
            acc.append(int(parts[2].split('=')[1].strip()))
            y_out_float.append(float(parts[3].split('=')[1].strip()))
    
    return np.array(x_in), np.array(y_out), np.array(acc), np.array(y_out_float)

# Function to normalize VHDL fixed-point values
def normalize_q_format(values, integer_bits, fraction_bits):
    """Convert fixed-point values to floating point"""
    return values / (2**fraction_bits)

# Butterworth bandpass filter implementation from Python
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

# Check if the file exists
if not os.path.exists(vhdl_output_file):
    print(f"Error: File not found - {vhdl_output_file}")
    exit(1)

# Parse VHDL output
vhdl_x, vhdl_y, vhdl_acc, vhdl_y_float = parse_vhdl_output(vhdl_output_file)
print(f"Loaded {len(vhdl_x)} samples from VHDL output file")

# Create the same input for the Python filter
# Normalize VHDL input (assuming Q1.15 format)
vhdl_x_normalized = vhdl_x / 32768.0

# Prepare input for Python filter - align with VHDL
# In VHDL, the impulse is applied at sample 5 (index 5) as seen in your output file
python_input = vhdl_x_normalized.copy()

# Run the Python filter to get the original output
python_y_original = butterworth_bandpass_filter(python_input)

# Shift Python output by one sample to align with VHDL
# This is necessary because VHDL has a one-sample delay in its implementation
# due to how sequential digital filters work in hardware
python_y = np.zeros_like(python_y_original)
python_y[1:] = python_y_original[:-1]  # Shift right by 1 sample

# Print the exact indices of significant events to confirm alignment
print(f"VHDL: First impulse at index {np.nonzero(vhdl_x_normalized > 0.5)[0][0]}")
print(f"VHDL: First significant output at index {np.nonzero(np.abs(vhdl_y_float) > 0.01)[0][0]}")
print(f"Python shifted: First significant output at index {np.nonzero(np.abs(python_y) > 0.01)[0][0]}")
print(f"Alignment confirmation: {'MATCHED' if np.nonzero(np.abs(vhdl_y_float) > 0.01)[0][0] == np.nonzero(np.abs(python_y) > 0.01)[0][0] else 'MISMATCHED'}")

# Generate sample indices for plotting
sample_indices = np.arange(len(vhdl_x))

# Plot the comparison
plt.figure(figsize=(15, 15))

# Plot input signal
plt.subplot(3, 1, 1)
plt.stem(sample_indices, vhdl_x_normalized, 'b', markerfmt='bo', label='Input Signal')
plt.title('Input Signal (Normalized)')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.grid(True)
plt.legend()

# Plot output signal comparison - line plot for full view
plt.subplot(3, 1, 2)
plt.plot(sample_indices, vhdl_y_float, 'r-', label='VHDL Output')
plt.plot(sample_indices, python_y, 'g--', label='Python Output (Shifted)')
plt.title('Filter Output Comparison (Line Plot)')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.grid(True)
plt.legend()

# Plot difference and MSE
plt.subplot(3, 1, 3)
difference = vhdl_y_float - python_y
plt.stem(sample_indices, difference, 'k', markerfmt='ko', label='Difference')
plt.title(f'Difference (VHDL - Python), MSE: {calculate_mse(vhdl_y_float, python_y):.6f}')
plt.xlabel('Sample')
plt.ylabel('Amplitude Difference')
plt.grid(True)
plt.legend()

# Add a horizontal line at the MSE value
plt.axhline(y=np.sqrt(calculate_mse(vhdl_y_float, python_y)), color='r', linestyle='--', 
           label=f'RMSE: {np.sqrt(calculate_mse(vhdl_y_float, python_y)):.6f}')

# Add a separate zoomed-in plot to show the close alignment
plt.figure(figsize=(12, 6))
plt.stem(sample_indices[5:15], vhdl_y_float[5:15], 'r', markerfmt='ro', basefmt=" ", label='VHDL Output')
plt.stem(sample_indices[5:15], python_y[5:15], 'g', markerfmt='g^', linefmt='g--', basefmt=" ", label='Python Output (Aligned)')
plt.title('Zoomed View of First 10 Response Samples (samples 5-15)')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.savefig("filter_zoom.png", dpi=300)

# Add MSE to super title
mse_value = calculate_mse(vhdl_y_float, python_y)
plt.suptitle(f'Fourth Order Butterworth Bandpass Filter Response Comparison\nMSE: {mse_value:.6f}', fontsize=16)
plt.tight_layout(rect=[0, 0, 1, 0.95])

# Create a plot comparing only VHDL vs shifted Python output
plt.figure(figsize=(15, 8))
plt.stem(sample_indices, vhdl_y_float, 'r', markerfmt='ro', basefmt=" ", label='VHDL Output')
plt.stem(sample_indices, python_y, 'g', markerfmt='g^', linefmt='g--', basefmt=" ", label='Python Output (Aligned)')
plt.title('Fourth Order Butterworth Bandpass Filter Response Comparison')
plt.xlabel('Sample')
plt.ylabel('Amplitude')
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.savefig("filter_comparison.png", dpi=300)

# Show metrics for the shifted comparison only
shifted_diff = vhdl_y_float - python_y
max_shifted_diff = np.max(np.abs(shifted_diff))
mean_shifted_diff = np.mean(np.abs(shifted_diff))
rms_diff = np.sqrt(np.mean(np.square(shifted_diff)))
mse = calculate_mse(vhdl_y_float, python_y)
rmse = np.sqrt(mse)

print(f"\nComparison metrics (VHDL vs Shifted Python):")
print(f"Mean Squared Error (MSE): {mse:.10f}")
print(f"Root Mean Squared Error (RMSE): {rmse:.10f}")
print(f"Maximum absolute difference: {max_shifted_diff:.10f}")
print(f"Mean absolute difference: {mean_shifted_diff:.10f}")
print(f"RMS difference: {rms_diff:.10f}")
print(f"Relative max difference: {100*max_shifted_diff/max(np.abs(vhdl_y_float)):.6f}%")

# Print comparison of VHDL and shifted Python
print("\nFirst 15 samples comparison (VHDL vs Python):")
column_width = 15
header = f"{'Sample':>6} {'VHDL':>{column_width}} {'Python':>{column_width}} {'Difference':>{column_width}}"
print(header)
print("-" * (6 + 3*column_width))
for i in range(min(15, len(vhdl_y_float))):
    print(f"{i:6d} {vhdl_y_float[i]:{column_width}.10f} {python_y[i]:{column_width}.10f} {shifted_diff[i]:{column_width}.10f}")

# Save the complete comparison to a file
with open('filter_comparison_data.csv', 'w') as f:
    f.write("Sample,VHDL,Python,Difference,SquaredError\n")
    for i in range(len(vhdl_y_float)):
        squared_error = (vhdl_y_float[i] - python_y[i])**2
        f.write(f"{i},{vhdl_y_float[i]:.10f},{python_y[i]:.10f},{shifted_diff[i]:.10f},{squared_error:.10f}\n")

# Print samples with largest differences
if len(shifted_diff) > 0:
    print("\nTop 5 samples with largest differences:")
    largest_shift_indices = np.argsort(np.abs(shifted_diff))[-5:][::-1]
    print(f"{'Sample':>6} {'VHDL':>15} {'Python':>15} {'Difference':>15}")
    print("-" * 55)
    for i in largest_shift_indices:
        print(f"{i:6d} {vhdl_y_float[i]:15.10f} {python_y[i]:15.10f} {shifted_diff[i]:15.10f}")

# Create a dedicated MSE visualization plot
plt.figure(figsize=(12, 10))

# Plot 1: Squared errors
plt.subplot(2, 1, 1)
squared_errors = (vhdl_y_float - python_y)**2
plt.stem(sample_indices, squared_errors, 'b', markerfmt='bo', label='Squared Error')
plt.axhline(y=mse, color='r', linestyle='--', label=f'MSE: {mse:.8f}')
plt.title('Squared Error per Sample')
plt.xlabel('Sample')
plt.ylabel('Squared Error')
plt.yscale('log')  # Log scale to better visualize small errors
plt.grid(True)
plt.legend()

# Plot 2: Cumulative MSE
plt.subplot(2, 1, 2)
cumulative_mse = np.cumsum(squared_errors) / np.arange(1, len(squared_errors) + 1)
plt.plot(sample_indices, cumulative_mse, 'g-', label='Cumulative MSE')
plt.axhline(y=mse, color='r', linestyle='--', label=f'Final MSE: {mse:.8f}')
plt.title('Cumulative MSE (Running Average of Squared Errors)')
plt.xlabel('Number of Samples')
plt.ylabel('MSE Value')
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.savefig("mse_analysis.png", dpi=300)
plt.suptitle("Mean Squared Error Analysis", fontsize=16)
plt.subplots_adjust(top=0.92)