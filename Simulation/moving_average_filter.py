from typing import List
import numpy as np
import matplotlib.pyplot as plt
import math

def integration(x:List[float], window_size:int=30, use_floor:bool=False):
    integrated_signal = np.zeros_like(x, dtype=float)
    for n in range(len(x)):
        for k in range(window_size):
            if n - k >= 0:
                integrated_signal[n] += x[n - k]
    
    # Divide by window size to get the average
    result = integrated_signal / window_size

    # Apply floor if requested
    if use_floor:
        result = np.array([math.floor(val) for val in result])

    return result

# Create a list of integers from 1 to 100
data = list(range(1, 101))

# Calculate moving average with window size = 30 and apply floor
window_size = 30
result_floor = integration(data, window_size, use_floor=True)

# Print the results
print("Moving average with window size =", window_size)
print("Input data (first 10 values):", data[:10], "...")

print("\nFloor of moving average (first 10 values):")
for i, val in enumerate(result_floor):
    print(f"Index {i + 1}: {val}")

# Create a simple plot
plt.figure(figsize=(10, 6))
plt.plot(data, 'b-', label='Original Data')
plt.plot(result_floor, 'r-', label='Floor of Moving Average', linewidth=2)
plt.title(f'Floor of Moving Average of List [1, 2, ..., 100] with Window Size = {window_size}')
plt.xlabel('Index')
plt.ylabel('Value')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig('moving_average_plot.png')  # Save the plot to a file
plt.show()

# Write the moving average results to a text file
with open('moving_average_python_output.txt', 'w') as f:
    for i, val in enumerate(result_floor):
        f.write(f"x_in = {i+1}; y_out = {int(val)}\n")

print(f"\nMoving average results written to 'moving_average_python_output.txt' in the format:")
print("x_in = [index]; y_out = [value]")

# Print full list of floor values
print("\nFull list of floor of moving average values:")
print(result_floor.tolist())

