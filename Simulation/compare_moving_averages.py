import numpy as np
import matplotlib.pyplot as plt
import re

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
    
    return x_values, y_values

# Read data from both files
vhdl_file_path = '../src/integration_filter/moving_average_output.txt'
python_file_path = './moving_average_python_output.txt'

# Read only the first 100 lines from the VHDL output
vhdl_x, vhdl_y = read_output_file(vhdl_file_path, max_lines=100)
python_x, python_y = read_output_file(python_file_path)

# Create a plot comparing both implementations
plt.figure(figsize=(12, 8))

# Plot original input data for reference
plt.plot(vhdl_x, vhdl_x, 'g-', label='Original Input', alpha=0.5)

# Plot the VHDL and Python moving averages
plt.plot(vhdl_x, vhdl_y, 'b-', label='VHDL Moving Average', linewidth=2)
plt.plot(python_x, python_y, 'r--', label='Python Moving Average', linewidth=2)

# Plot the differences between VHDL and Python implementations
# First, ensure we're comparing the same range
min_len = min(len(vhdl_x), len(python_x))
vhdl_x_trimmed = vhdl_x[:min_len]
vhdl_y_trimmed = vhdl_y[:min_len]
python_x_trimmed = python_x[:min_len]
python_y_trimmed = python_y[:min_len]

# Calculate differences where both implementations have values
differences = []
for i in range(min_len):
    if vhdl_x_trimmed[i] == python_x_trimmed[i]:  # Ensure matching x-values
        differences.append(vhdl_y_trimmed[i] - python_y_trimmed[i])

plt.plot(vhdl_x_trimmed[:len(differences)], differences, 'k:', label='VHDL - Python', linewidth=1)

# Add title and labels
plt.title('Moving Average', fontsize=16)
plt.xlabel('Input Value', fontsize=14)
plt.ylabel('Moving Average Output', fontsize=14)

# Add grid and legend
plt.grid(True, alpha=0.3)
plt.legend(fontsize=12)

# Show statistics
plt.figtext(0.02, 0.02, f"Max difference: {max(abs(diff) for diff in differences)}", fontsize=10)

# Save and display the plot
plt.tight_layout()
plt.savefig('moving_average_comparison.png', dpi=300)
plt.show()

# Print statistics
print(f"Total data points compared: {len(differences)}")
print(f"Maximum difference: {max(abs(diff) for diff in differences)}")
print(f"Indices with differences:")

for i, diff in enumerate(differences):
    if diff != 0:
        print(f"  At input {vhdl_x_trimmed[i]}: VHDL = {vhdl_y_trimmed[i]}, Python = {python_y_trimmed[i]}, Diff = {diff}")