import csv
from datetime import datetime

count = 0

# Function to extract year from a date string
def extract_year(date_str):
    try:
        date_obj = datetime.strptime(date_str, '%b %d, %Y')
        print(date_obj)
        return date_obj.year
    except ValueError:
        return None

# Function to check if release year matches date year
def check_year_mismatch(csv_file_path):
    global count
    
    mismatches = []
    
    with open(csv_file_path, mode='r', newline='') as file:
        reader = csv.DictReader(file)
        
        for row in reader:
            date_str = row.get('Date')
            release_year_str = row.get('Released')
            
            date_year = extract_year(date_str) if date_str else None
            release_year = int(release_year_str) if release_year_str else None
            
            if release_year is None or date_year != release_year:
                mismatches.append(row)
                count += 1
    
    return mismatches

csv_file_path = 'input.csv'
mismatches = check_year_mismatch(csv_file_path)

for mismatch in mismatches:
    print(mismatch)

print(count)