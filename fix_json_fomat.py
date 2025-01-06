import json

# Define the path to the JSON file
input_file_path = 'C:/Users/Yvette.Yuan/Downloads/fetch2024/fetch-data-modeling/raw_receipts.json'
output_file_path = 'C:/Users/Yvette.Yuan/Downloads/fetch2024/fetch-data-modeling/formatted_receipts.json'

# Read the JSON file
with open(input_file_path, 'r') as f:
	lines = f.readlines()

# Add commas to the end of each JSON object
fixed_lines = []
for line in lines:
	line = line.strip()
	if line and not line.endswith(',') and not line.endswith('[') and not line.endswith(']'):
		line += ','
	fixed_lines.append(line)

# Join the lines and remove the last comma
fixed_json = '\n'.join(fixed_lines)
fixed_json = fixed_json.rstrip(',\n') + '\n'

# Write the fixed JSON to a new file
with open(output_file_path, 'w') as f:
	f.write(fixed_json)

print(f"Fixed JSON file written to {output_file_path}")