import matplotlib.pyplot as plt
import numpy as np
from typing import List
import math

red_values = []
ir_values = []

def read_and_separate_values():

    with open('reading.txt', 'r') as file:
        l = file.readlines()
        for line in l:
            line = line.strip()
            if "Red:" in line and "IR:" in line:
                parts = line.split()
                red_value = int(parts[1])
                red_values.append(red_value)
                ir_value = int(parts[3])
                ir_values.append(ir_value)
                print(f"Red: {red_value}, IR: {ir_value}")

    with open('red_values.txt', 'w') as red_file, open('ir_values.txt', 'w') as ir_file:
        for red in red_values:
            red_file.write(f"{red}\n")
        for ir in ir_values:
            ir_file.write(f"{ir}\n")

def iir_bandpass_filter(x: List[float]) -> np.ndarray:
    b = np.array([625451352, 0, -1251168932, 0, 625451352], dtype=float) / 2**30
    a = np.array([1.0, -737915354, -875560496, 208097889, 373198311], dtype=float) / 2**30

    y = np.zeros_like(x, dtype=float)
    for n in range(len(x)):
        for k in range(len(b)):
            if n - k >= 0:
                y[n] += b[k] * x[n - k]
        for k in range(1, len(a)):
            if n - k >= 0:
                y[n] -= a[k] * y[n - k]
    return y

def absolute_value(x: List[float]) -> np.ndarray:
    return np.abs(x)

def moving_average(x, window_size=30) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    kernel = np.ones(window_size)
    return np.convolve(x, kernel, mode='same')

def iir_lowpass_filter_q15(x: List[float]) -> np.ndarray:

    # === Coefficients (Q1.15 integers) ===
    b0 = 1937 / 2**15
    b1 = 1937 / 2**15
    a1 = -28888 / 2**15  # already signed
    
    y_out = np.zeros(len(x), dtype=float)

    for n in range(len(x)):
        y_out[n] = b0 * x[n] + b1 * x[n - 1] if n - 1 >= 0 else 0
        y_out[n] -= a1 * y_out[n - 1] if n - 1 >= 0 else 0
    return y_out

def peak_detection(signal: np.ndarray, min_distance: int = 50) -> np.ndarray:
    peaks = np.zeros_like(signal, dtype=int)
    x_prev2 = 0
    x_prev1 = 0
    counter = min_distance 

    for i in range(len(signal)):
        x_curr = signal[i]

        peak_detected_local = int((x_prev1 > x_prev2) and (x_prev1 > x_curr))

        if peak_detected_local and counter >= min_distance:
            peaks[i - 1] = 1 
            counter = 0
        else:
            peaks[i - 1] = 0
            counter += 1

        x_prev2 = x_prev1
        x_prev1 = x_curr

    peaks[0] = 0
    return peaks

def visulaize_data():
    # Two separate plots for Red and IR values
    plt.figure(figsize=(15, 12))
    plt.subplot(5, 2, 1)
    plt.plot(red_values[500:1000], color='red')
    plt.title('Red Values Over Time')
    plt.xlabel('Sample Index')
    plt.ylabel('Red Value')
    plt.subplot(5, 2, 2)
    plt.plot(ir_values[500:1000], color='blue')
    plt.title('IR Values Over Time')
    plt.xlabel('Sample Index')
    plt.ylabel('IR Value')
    plt.subplot(5, 2, 3)
    plt.plot(red_filtered[500:1000], color='red')
    plt.title('Filtered Red Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Filtered Red Value')
    plt.subplot(5, 2, 4)
    plt.plot(ir_filtered[500:1000], color='blue')
    plt.title('Filtered IR Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Filtered IR Value')
    plt.subplot(5, 2, 5)
    plt.plot(red_filtered_abs[500:1000], color='red')
    plt.title('Absolute Filtered Red Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Absolute Filtered Red Value')
    plt.subplot(5, 2, 6)
    plt.plot(ir_filtered_abs[500:1000], color='blue')
    plt.title('Absolute Filtered IR Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Absolute Filtered IR Value')
    plt.subplot(5, 2, 7)
    plt.plot(red_filtered_abs_ma[500:1000], color='red')
    plt.title('Moving Average of Absolute Filtered Red Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Moving Average Value')
    plt.subplot(5, 2, 8)
    plt.plot(ir_filtered_abs_ma[500:1000], color='blue')
    plt.title('Moving Average of Absolute Filtered IR Values')
    plt.xlabel('Sample Index')
    plt.ylabel('Moving Average Value')
    plt.subplot(5, 2, 9)
    plt.plot(red_filtered_abs_ma_iir[500:1000], color='red')
    plt.title('IIR Lowpass Filtered Moving Average Red Values')
    plt.xlabel('Sample Index')
    plt.ylabel('IIR Lowpass Value')
    plt.plot(red_peaks_between_500_1000, red_filtered_abs_ma_iir[500 + red_peaks_between_500_1000], 'rx', markersize=8, label='Peaks')
    plt.legend()
    plt.subplot(5, 2, 10)
    plt.plot(ir_filtered_abs_ma_iir[500:1000], color='blue')
    plt.title('IIR Lowpass Filtered Moving Average IR Values')
    plt.xlabel('Sample Index')
    plt.ylabel('IIR Lowpass Value')
    plt.plot(ir_peaks_between_500_1000, ir_filtered_abs_ma_iir[500 + ir_peaks_between_500_1000], 'bx', markersize=8, label='Peaks')
    plt.legend()
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    read_and_separate_values()
    red_filtered = iir_bandpass_filter(red_values)
    red_filtered_abs = absolute_value(red_filtered)
    red_filtered_abs_ma = moving_average(red_filtered_abs)
    red_filtered_abs_ma_iir = iir_lowpass_filter_q15(red_filtered_abs_ma)
    red_peaks = peak_detection(red_filtered_abs_ma_iir, min_distance=50)
    red_peaks_between_500_1000 = red_peaks[500:1000].nonzero()[0]
    print("Red Peaks between 500 and 1000:", red_peaks_between_500_1000)
    ir_filtered = iir_bandpass_filter(ir_values)
    ir_filtered_abs = absolute_value(ir_filtered)
    ir_filtered_abs_ma = moving_average(ir_filtered_abs)
    ir_filtered_abs_ma_iir = iir_lowpass_filter_q15(ir_filtered_abs_ma)
    ir_peaks = peak_detection(ir_filtered_abs_ma_iir, min_distance=50)
    ir_peaks_between_500_1000 = ir_peaks[500:1000].nonzero()[0]
    print("IR Peaks between 500 and 1000:", ir_peaks_between_500_1000)
    visulaize_data()