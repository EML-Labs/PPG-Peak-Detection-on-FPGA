import csv
from scipy import signal
import numpy as np
from typing import List
import matplotlib.pyplot as plt
import time

FILE_PATH:str = "Data/dataset.csv"
SAMPLING_FREQUENCY:int = 125  # Hz
PERIOD:float = 0.3 # second

clk_signal = True

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

def clock():
    global clk_signal
    clk_signal = not clk_signal
    time.sleep(1)  
    return clk_signal
ppg_data = get_ppg_data(FILE_PATH)[:2000]

def get_ppg_sensor_data():
    global ppg_data
    element = ppg_data.pop(0) if ppg_data else 0
    return element


if __name__ == "__main__":
    while True:
        clk = clock()
        print(f"Clock signal: {clk}")
        ppg_value = get_ppg_sensor_data()
        print(f"PPG Sensor Data: {ppg_value}")