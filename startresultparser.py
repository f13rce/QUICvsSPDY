from pathlib import Path
import os
import sys

# Find pcaps to parse
files = []
result = list(Path("results/").rglob("*.[pP][cC][aA][pP]"))
for file in result:
	print("Found pcap: {}".format(str(file)))
	files.append(str(file))

print("Found {} files to parse.".format(len(files)))

i = 0
for file in files:
	i += 1
	print("Parsing result of {} ({}/{})...".format(file, i, len(files)))
	os.system("python3 parseresults.py {}".format(file))
