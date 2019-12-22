from scapy.all import *
from pathlib import Path
import os
import sys

file = sys.argv[1]
if file != "":
	print("RDPCAP: Reading packet {}...".format(file))
	scapy_cap = rdpcap(file)

	print("Parsing packet...")
	print(repr(scapy_cap))
	packetCount = 0
	payloadCount = 0

	totalPacketSize = 0
	minPacketSize = 99999999
	maxPacketSize = 0

	totalPayloadSize = 0
	minPayloadSize = 99999999
	maxPayloadSize = 0

	tcpCount = 0
	udpCount = 0

	for packet in scapy_cap:
		# TCP
		try:
			if packet[TCP]:
				packetCount += 1
				tcpCount += 1

				totalPacketSize += len(packet[TCP])
				if len(packet[TCP]) < minPacketSize:
					minPacketSize = len(packet[TCP])
				if len(packet[TCP]) > maxPacketSize:
					maxPacketSize = len(packet[TCP])

				if packet[TCP].load:
					totalPayloadSize += len(packet[TCP].load)
					payloadCount += 1
					if len(packet[TCP].load) < minPayloadSize:
						minPayloadSize = len(packet[TCP].load)
					if len(packet[TCP].load) > maxPayloadSize:
						maxPayloadSize = len(packet[TCP].load)
		except:
			pass

		# UDP
		try:
			if packet[UDP]:
				packetCount += 1
				udpCount += 1

				totalPacketSize += len(packet[UDP])
				if len(packet[UDP]) < minPacketSize:
					minPacketSize = len(packet[UDP])
				if len(packet[UDP]) > maxPacketSize:
					maxPacketSize = len(packet[UDP])

				if packet[UDP].len > 0:
					# Remove the size of the UDP header, which is 8 bytes
					totalPayloadSize += (packet[UDP].len - 8)
					payloadCount += 1
					if (packet[UDP].len - 8) < minPayloadSize:
						minPayloadSize = (packet[UDP].len - 8)
					if (packet[UDP].len - 8) > maxPayloadSize:
						maxPayloadSize = (packet[UDP].len - 8)
		except:
			pass


	print("Results:")

	print("\tPacket:")
	print("\t\tPacket count: {}".format(packetCount))
	print("\t\tTotal packet size: {}".format(totalPacketSize))
	print("\t\tAverage size per packet: {}".format(totalPacketSize / packetCount))
	print("\t\tMin size: {}".format(minPacketSize))
	print("\t\tMax size: {}".format(maxPacketSize))

	print("\tPayload:")
	print("\t\tPayload count: {}".format(payloadCount))
	print("\t\tTotal payload size: {}".format(totalPayloadSize))
	print("\t\tAverage size per payload: {}".format(totalPayloadSize / payloadCount))
	print("\t\tMin size: {}".format(minPayloadSize))
	print("\t\tMax size: {}".format(maxPayloadSize))

	print("\tTCP Packets: {}".format(tcpCount))
	print("\tUDP Packets: {}".format(udpCount))

	dir = file.split("/")[1]
	pathInDir = "results"

	protocol = file.split("/")[2].split(".")[0]
	malformation = file.split("/")[2].split(".")[1]

	size = ""
	for subarg in file.split("/")[2].split("."):
		if "mb" in subarg:
			size = subarg
			break

	csvPath = "{}/{}_{}_{}.csv".format(pathInDir, dir, protocol, size)

	my_file = Path(csvPath)

	# Check if file exists. If not, create csv headers
	if not my_file.is_file():
		with open(csvPath, "w") as f:
			print("{} didn't exist yet, creating it...".format(csvPath))
			f.truncate()
			f.write("Malformation,Size,Total Packets,TCP Packets,UDP Packets,Total Payloads,Total Packet Size,Average Packet Size,Min Packet Size,Max Packet Size,Total Payload Size,Average Payload Size,Min Payload Size,Max Payload Size\n")

	print("Writing to {}...".format(csvPath))
	with open(csvPath, "a") as f:
		f.write("{},{},{},{},{},{},{},{},{},{},{},{},{},{}\n".format(malformation, size, packetCount, tcpCount, udpCount, payloadCount, totalPacketSize, (totalPacketSize / packetCount), minPacketSize, maxPacketSize, totalPayloadSize, (totalPayloadSize / payloadCount), minPayloadSize, maxPayloadSize))
