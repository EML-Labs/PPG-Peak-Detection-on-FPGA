import csv

# Input and output file names
input_csv = "../../Simulation/Data/dataset.csv"
output_txt = "ppg.txt"

# Open CSV file and extract only PPG column
with open(input_csv, 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    with open(output_txt, 'w') as outfile:
        for row in reader:
            ppg_value = row['PPG']  # extract PPG column
            outfile.write(ppg_value + '\n')  # write to txt file
