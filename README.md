# QUICvsSPDY
Scripts that were used to measure the performance of QUIC and SPDY when met with sub-optimal network environments.

# Scripts

collect*.sh: Performs the tests on the QUIC and SPDY server. SSHs in to alter the network environment (such as latency), starts a recording, then requests the page and then stops the recording. Every recording is saved in a results subdirectory with its corresponding name entailing the test's means.

startresultparser.py: This script finds every PCAP and passes them along to the parseresults.py for in-depth inspection. This script was created so that the RAM does not overflow by all the data the parseresults would collect. Otherwise, manual garbage collection techniques were required.
parseresults.py: Using the scapy library, counts the amount of packets, payloads and similar statistics. These statistics have been parsed in the published paper.

startcapture.sh: This starts a tcpdump on the bridge both the QUIC and SPDY server were routing their traffic to, as well as only capturing the interesting ports.

# Other files

spdyproof.txt: Proof that HTTP/2 was actually used in a request. This indicates that SPDY was actually in play.

csv_results.zip: Raw results file of the CSVs that were generated by the parseresults.py script.

# Notes

These scripts were uploaded to show the intent and detailed methods of the experiment, not to be run. This is why no requirements.txt is present.

The PCAPs could not directly be uploaded due to the 100MB limit by GitHub. If you would like those PCAPs, please contact me through the measures you know.
