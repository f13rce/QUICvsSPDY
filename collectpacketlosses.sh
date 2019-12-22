#!/bin/bash

# QUIC
#./out/Default/quic_client --host=145.100.105.165 --port=6121 https://www.example.org/1mb

# SPDY
#curl https://145.100.105.164/10mb.html --cacert cacert.pem --output /dev/null

# Bash arrays
# https://www.linuxjournal.com/content/bash-arrays

QUIC_IP="145.100.105.165"
SPDY_IP="145.100.105.164"

sampleSize=50
fileSizes=(1mb 10mb 100mb)
packetLosses=(0.1% 1.0% 5.0% 10.0% 15.0%)

screenName="packet.capture"

mkdir results
mkdir results/latencies
mkdir results/jitters
mkdir results/packetlosses

Log ()
{
	echo "========================================================"
	echo "= LOG: " $1 " ="
	echo "========================================================"
}

LogSmall ()
{
	echo "----> LOG: " $1
}

for size in ${fileSizes[*]}
do
	# Test latency
	for loss in ${packetLosses[*]}
	do
		Log "Testing loss of $loss"

		# Set QUIC environment
		Log "Setting QUIC loss environment..."
ssh -oStrictHostKeyChecking=no root@$QUIC_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc change dev eth0 root netem delay 0ms 0ms
	tc qdisc change dev eth0 root netem loss $loss
EOF

		# Set SPDY environment
		Log "Setting SPDY loss environment..."
ssh -oStrictHostKeyChecking=no root@$SPDY_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc change dev eth0 root netem delay 0ms 0ms
	tc qdisc change dev eth0 root netem loss $loss
EOF

		# Test QUIC
		Log "Testing QUIC..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - QUIC - Packet loss: $loss - $c/$sampleSize..."
			/home/f13rce/chromium/src/out/Default/quic_client --host=$QUIC_IP --port=6121 https://www.example.org/$size;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/packetlosses/quic.$loss.$size.pcap

		# Test SPDY
		Log "Testing SPDY..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - SPDY - Packet loss: $loss - $c/$sampleSize..."
			curl https://$SPDY_IP/$size.html --cacert /home/f13rce/cacert.pem --output -;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/packetlosses/spdy.$loss.$size.pcap

		# QUIC
		#./out/Default/quic_client --host=145.100.105.165 --port=6121 https://www.example.org/1mb

		# SPDY
		#curl https://145.100.105.164/10mb.html --cacert cacert.pem --output /dev/null
	done
done
