import numpy as np
import matplotlib.pyplot as plt
import re
import os

def read_output_file(file_path, max_lines=None):
    x_values = []
    y_values = []
    
    with open(file_path, 'r') as f:
        for i, line in enumerate(f):
            # Stop after reading max_lines if specified
            if max_lines and i >= max_lines:
                break
                
            # Extract x_in and y_out values using regex
            match = re.search(r'x_in = (\d+); y_out = (-?\d+)', line)
            if match:
                x = int(match.group(1))
                y = int(match.group(2))
                x_values.append(x)
                y_values.append(y)
    
    return np.array(x_values), np.array(y_values)

# Calculate Mean Squared Error
def calculate_mse(y_true, y_pred):
    return np.mean((y_true - y_pred) ** 2)

# Calculate Mean Absolute Error
def calculate_mae(y_true, y_pred):
    return np.mean(np.abs(y_true - y_pred))

# Read data from both files
vhdl_file_path = '../src/integration_filter/moving_average_output.txt'
python_file_path = './moving_average_python_output.txt'

# Read only the first 100 lines from the VHDL output
vhdl_x, vhdl_y = read_output_file(vhdl_file_path, max_lines=100)
python_x, python_y = read_output_file(python_file_path)

# Ensure we're comparing the same range
min_len = min(len(vhdl_x), len(python_x))
vhdl_x_trimmed = vhdl_x[:min_len]
vhdl_y_trimmed = vhdl_y[:min_len]
python_x_trimmed = python_x[:min_len]
python_y_trimmed = python_y[:min_len]

# Calculate MSE and MAE
mse = calculate_mse(python_y_trimmed, vhdl_y_trimmed)
mae = calculate_mae(python_y_trimmed, vhdl_y_trimmed)

# Calculate running MSE (window-based)
window_size = 10
running_mse = []

for i in range(min_len - window_size + 1):
    window_mse = calculate_mse(python_y_trimmed[i:i+window_size], vhdl_y_trimmed[i:i+window_size])
    running_mse.append(window_mse)

# Create a plot comparing both implementations
plt.figure(figsize=(12, 10))

# Plot 1: Original inputs and outputs
plt.subplot(3, 1, 1)
plt.plot(vhdl_x_trimmed, vhdl_x_trimmed, 'g-', label='Original Input', alpha=0.5)
plt.plot(vhdl_x_trimmed, vhdl_y_trimmed, 'b-', label='VHDL Moving Average', linewidth=2)
plt.plot(python_x_trimmed, python_y_trimmed, 'r--', label='Python Moving Average', linewidth=2)
plt.title('Comparison of VHDL and Python Moving Average Implementations (First 100 Values)', fontsize=14)
plt.xlabel('Input Value', fontsize=12)
plt.ylabel('Moving Average Output', fontsize=12)
plt.grid(True, alpha=0.3)
plt.legend(fontsize=10)

# Plot 2: Differences
plt.subplot(3, 1, 2)
differences = vhdl_y_trimmed - python_y_trimmed
plt.stem(vhdl_x_trimmed, differences, 'k-', label='VHDL - Python', linewidth=1, markerfmt='ko')
plt.title('Differences Between VHDL and Python Implementations', fontsize=14)
plt.xlabel('Input Value', fontsize=12)
plt.ylabel('Difference', fontsize=12)
plt.grid(True, alpha=0.3)
plt.legend(fontsize=10)

# Plot 3: Running MSE
plt.subplot(3, 1, 3)
plt.plot(vhdl_x_trimmed[window_size-1:min_len], running_mse, 'r-', linewidth=2)
plt.axhline(y=mse, color='b', linestyle='--', label=f'Overall MSE: {mse:.6f}')
plt.title('Running Mean Squared Error (Window Size: 10)', fontsize=14)
plt.xlabel('Input Value', fontsize=12)
plt.ylabel('MSE', fontsize=12)
plt.grid(True, alpha=0.3)
plt.legend(fontsize=10)

# Add overall statistics text box
stats_text = f"Overall Statistics:\n" \
             f"MSE: {mse:.6f}\n" \
             f"MAE: {mae:.6f}\n" \
             f"Max Diff: {max(abs(differences))}"
             
plt.figtext(0.02, 0.02, stats_text, fontsize=12, 
            bbox=dict(facecolor='white', alpha=0.8, boxstyle='round,pad=0.5'))

# Layout and save
plt.tight_layout()
plt.subplots_adjust(bottom=0.1)  # Make room for the text box
plt.savefig('moving_average_mse_comparison.png', dpi=300)
plt.show()

# Print statistics
print(f"Total data points compared: {min_len}")
print(f"Mean Squared Error (MSE): {mse:.6f}")
print(f"Mean Absolute Error (MAE): {mae:.6f}")
print(f"Maximum difference: {max(abs(differences))}")

# Print points with differences
print(f"\nIndices with differences:")
for i, diff in enumerate(differences):
    if diff != 0:
        print(f"  At input {vhdl_x_trimmed[i]}: VHDL = {vhdl_y_trimmed[i]}, Python = {python_y_trimmed[i]}, Diff = {diff}")