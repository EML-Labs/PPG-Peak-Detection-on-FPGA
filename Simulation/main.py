import csv
from scipy import signal
import numpy as np
from typing import List
import matplotlib.pyplot as plt

FILE_PATH:str = "Data/dataset.csv"
SAMPLING_FREQUENCY:int = 125  # Hz
PERIOD:float = 0.3 # second

window_size_for_integration = int(SAMPLING_FREQUENCY * PERIOD)
samples_for_validation = int(SAMPLING_FREQUENCY * 0.5)  # 2 seconds

print(f"Window size for integration: {window_size_for_integration}")
print(f"Samples for validation: {samples_for_validation}")

def get_ppg_data(file_path:str):
    HEADER = ["Time", "PPG", "ECG", "Resp"]
    data = []
    with open(file_path, 'r') as file:
        csv_reader = csv.DictReader(file, fieldnames=HEADER)
        next(csv_reader)  # Skip the header row
        for row in csv_reader:
            data.append(float(row["PPG"]))
    return data

def butterworth_bandpass_filter(x:List[float]):
    b = [0.5825, 0.0, -1.1650, 0.0, 0.5825]
    a = [1.0, -0.6874, -0.8157, 0.1939, 0.3477]

    y = np.zeros_like(x, dtype=float)

    for n in range(len(x)):
        for k in range(len(b)):
            if n - k >= 0:
                y[n] += b[k] * x[n - k]
        for k in range(1, len(a)):
            if n - k >= 0:
                y[n] -= a[k] * y[n - k]
    return y


def absolute_value(x:List[float]):
    return [abs(i) for i in x]


def integration(x:List[float], window_size:int=30):
    integrated_signal = np.zeros_like(x, dtype=float)
    for n in range(len(x)):
        for k in range(window_size):
            if n - k >= 0:
                integrated_signal[n] += x[n - k]
    return integrated_signal / window_size

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
        if n - 1 >= 0:
            y_n += b1 * x[n-1]
        # feedback
        if n - 1 >= 0:
            y_n += a1 * y[n-1]
        y[n] = y_n

    return y

def plot_signal(x:List[float]):
    plt.plot(x)
    plt.xlabel('Sample Index')
    plt.ylabel('Amplitude')
    plt.title('Signal Plot')
    plt.grid(True)
    plt.show()


def detect_peaks(x:List[float]):
    peaks = []
    for i in range(1, len(x)-1):
        if x[i] > x[i-1] and x[i] > x[i+1]:
            peaks.append(i)
    return peaks

def time_validate(x:List[float],peaks:List[int],samples_for_validation:int=62):
    copy_peaks = peaks.copy()
    for i in range(len(peaks)-1):
        if (peaks[i+1] - peaks[i]) < samples_for_validation:
            copy_peaks[i+1] = -1  # Mark for removal
    validated_peaks = [p for p in copy_peaks if p != -1]
    return validated_peaks
        
def calculte_time_between_peaks(peaks:List[int],sampling_frequency:int=125):
    time_between_peaks = []
    for i in range(len(peaks)-1):
        time_diff = (peaks[i+1] - peaks[i]) / sampling_frequency
        time_between_peaks.append(time_diff)
    return time_between_peaks

def calculate_bpm(time_between_peaks:List[float]):
    bpm_values = []
    for time_diff in time_between_peaks:
        if time_diff > 0:
            bpm = int(60 / time_diff)
            bpm_values.append(bpm)
    return bpm_values

if __name__ == "__main__":
    ppg_data = get_ppg_data(FILE_PATH)[:2000]
    filtered_signal_01 = butterworth_bandpass_filter(ppg_data)
    abs_signal = absolute_value(filtered_signal_01)
    integrated_signal = integration(abs_signal, window_size_for_integration)
    filtered_signal_02 = butter_lp_order1(integrated_signal)
    peaks = detect_peaks(filtered_signal_02)
    validated_peaks = time_validate(filtered_signal_02, peaks, samples_for_validation)
    time_between_peaks = calculte_time_between_peaks(validated_peaks, SAMPLING_FREQUENCY)
    bpm_values = calculate_bpm(time_between_peaks)
    print("Detected Peaks at indices:", validated_peaks)
    print("Time between peaks (s):", time_between_peaks)
    print("Calculated BPM values:", bpm_values)
    plt.figure(figsize=(12, 8))
    plt.plot(ppg_data, label='Raw PPG Signal', alpha=0.5)
    plt.plot(filtered_signal_01, label='After Bandpass Filter', alpha=0.7)
    plt.plot(abs_signal, label='After Absolute Value', alpha=0.7)
    plt.plot(integrated_signal, label='After Integration', alpha=0.7)
    plt.plot(filtered_signal_02, label='After Lowpass Filter', alpha=0.9)
    for peak in validated_peaks:
        plt.axvline(x=peak, color='red', linestyle='--', alpha=0.8)
    plt.legend()
    plt.xlabel('Sample Index')
    plt.ylabel('Amplitude')
    plt.title('PPG Signal Processing Stages')
    plt.savefig('PPG Peak Detection Stages.png')
    plt.show()