#!/bin/bash

# QUIC
#./out/Default/quic_client --host=145.100.105.165 --port=6121 https://www.example.org/1mb

# SPDY
#curl https://145.100.105.164/10mb.html --cacert cacert.pem --output /dev/null

# Bash arrays
# https://www.linuxjournal.com/content/bash-arrays

QUIC_IP="145.100.105.165"
SPDY_IP="145.100.105.164"

sampleSize=25
fileSizes=(1mb)
latencies=(0ms 50ms 250ms 500ms)
jitters=(0ms 50ms 150ms 250ms 500ms)
packetLosses=(0.0% 1.0% 5.0% 10.0% 15.0%)

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
	for latency in ${latencies[*]}
	do
		Log "Testing latency of $latency"

		# Set QUIC environment
		Log "Setting QUIC latency environment..."
ssh -oStrictHostKeyChecking=no root@$QUIC_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay $latency 0ms
	tc qdisc add dev eth0 root netem delay $latency 0ms
EOF

		# Set SPDY environment
		Log "Setting SPDY latency environment..."
ssh -oStrictHostKeyChecking=no root@$SPDY_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay $latency 0ms
	tc qdisc add dev eth0 root netem delay $latency 0ms
EOF

		# Test QUIC
		Log "Testing QUIC..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - QUIC - Latency: $latency - $c/$sampleSize..."
			/home/f13rce/chromium/src/out/Default/quic_client --host=$QUIC_IP --port=6121 https://www.example.org/$size;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/latencies/quic.$latency.$size.pcap

		# Test SPDY
		Log "Testing SPDY..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - SPDY - Latency: $latency - $c/$sampleSize..."
			curl https://$SPDY_IP/$size.html --cacert /home/f13rce/cacert.pem --output -;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/latencies/spdy.$latency.$size.pcap

		# QUIC
		#./out/Default/quic_client --host=145.100.105.165 --port=6121 https://www.example.org/1mb

		# SPDY
		#curl https://145.100.105.164/10mb.html --cacert cacert.pem --output /dev/null

		# Reset QUIC environment
		Log "Setting QUIC latency environment..."
ssh -oStrictHostKeyChecking=no root@$QUIC_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay $latency 0ms
EOF

		# Reset SPDY environment
		Log "Setting SPDY latency environment..."
ssh -oStrictHostKeyChecking=no root@$SPDY_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay $latency 0ms
EOF

	done

	# Test jitter
	for jitter in ${jitters[*]}
	do
		Log "Testing jitter of $jitter"

		# Set QUIC environment
		Log "Setting QUIC environment..."
ssh -oStrictHostKeyChecking=no root@$QUIC_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc add dev eth0 root netem delay 0ms $jitter
EOF

		# Set SPDY environment
		Log "Setting SPDY environment..."
ssh -oStrictHostKeyChecking=no root@$SPDY_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc add dev eth0 root netem delay 0ms $jitter
EOF

		# Test QUIC
		Log "Testing QUIC..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - QUIC - Jitter: $jitter - $c/$sampleSize..."
			/home/f13rce/chromium/src/out/Default/quic_client --host=$QUIC_IP --port=6121 https://www.example.org/$size;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/jitters/quic.$jitter.ms.$size.pcap

		# Test SPDY
		Log "Testing SPDY..."
		screen -S $screenName -d -m ./startcapture.sh
		sleep 2s
		for (( c=1; c<=$sampleSize; c++ ))
		do
			LogSmall "Test - SPDY - Jitter: $jitter - $c/$sampleSize..."
			curl https://$SPDY_IP/$size.html --cacert /home/f13rce/cacert.pem --output -;
		done
		screen -X -S $screenName quit
		sleep 2s
		mv /home/f13rce/net.pcap results/jitters/spdy.$jitter.ms.$size.pcap

		# QUIC
		#./out/Default/quic_client --host=145.100.105.165 --port=6121 https://www.example.org/1mb

		# SPDY
		#curl https://145.100.105.164/10mb.html --cacert cacert.pem --output /dev/null

		# Reset QUIC environment
		Log "Setting QUIC environment..."
ssh -oStrictHostKeyChecking=no root@$QUIC_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay 0ms $jitter
EOF

		# Reset SPDY environment
		Log "Setting SPDY environment..."
ssh -oStrictHostKeyChecking=no root@$SPDY_IP << EOF
	export DEBIAN_FRONTEND=noninteractive
	tc qdisc del dev eth0 root netem delay 0ms $jitter
EOF

	done

done

./collectpacketlosses.sh
