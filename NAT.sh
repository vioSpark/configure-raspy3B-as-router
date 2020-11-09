#Initial checks
	#Once logged in to your Pi (via Terminal, on another computer), check that everything is setup:
		ifconfig -a
		# If eth0, and wlan0 there, good

#Setup
	sudo apt-get update -y
	sudo apt-get install hostapd isc-dhcp-server -y
	#DHCP server
		# Be wise and always make a backup of the default config
		sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.default
		# Edit the defult config file
		sudo nano /etc/dhcp/dhcpd.conf
			# Comment the following lines...
			#	option domain-name "example.org";
			#	option domain-name-servers ns1.example.org, ns2.example.org;
			# ...and un-comment this line
			#	#"If this DHCP server is the official DHCP server for the local
			#	#network, the authoritative directive should be uncommented." -don't
			#	authoritative; -do
		# ... scroll down at the bottom of the file (CTRL + V) and paste:
			# subnet 192.168.42.0 netmask 255.255.255.0 {
				# range 192.168.42.10 192.168.42.50;
				# option broadcast-address 192.168.42.255;
				# option routers 192.168.42.1;
				# default-lease-time 600;
				# max-lease-time 7200;
				# option domain-name "local";
				# option domain-name-servers 8.8.8.8, 8.8.4.4;
			# }
		#Now, with this configuration we are assigning the subnet 192.168.42.10–50 (40 devices in total) and we are configuring our WiFi local IP address to be 192.168.42.1. While we’re at it, we’re assigning Google’s public DNS: 8.8.8.8, 8.8.4.4.

	#Next, let’s specify on what interface should the DHCP server servce DHCP requests (wlan0 in this case):
		sudo nano /etc/default/isc-dhcp-server
		# Edit this line:
		INTERFACES=""
		# ...to read
		INTERFACES="wlan0"
	#Let’s setup wlan0 for static IP:
		# First, shut it down...
		sudo ifdown wlan0
		# ...keep it safe and make a backup file:
		sudo cp /etc/network/interfaces /etc/network/interfaces.backup
		# ...edit the network interfaces file:
		sudo nano /etc/network/interfaces
		# ... edit accordingly to read:
			# source-directory /etc/network/interfaces.d
			# auto lo
			# iface lo inet loopback
			# iface eth0 inet dhcp
			# allow-hotplug wlan0
			# iface wlan0 inet static
			# address 192.168.42.1
			# netmask 255.255.255.0
			# post-up iw dev $IFACE set power_save off
		# ...close the file and assign a static IP now
		sudo ifconfig wlan0 192.168.42.1		
#Hostapd
	# Create a file and edit it:
	sudo nano /etc/hostapd/hostapd.conf
	#modify ssid with a name of your choice and wpa_passphrase to a WiFi authentication key
		interface=wlan0
		ssid=WiPi
		hw_mode=g
		channel=6
		macaddr_acl=0
		auth_algs=1
		ignore_broadcast_ssid=0
		wpa=2
		wpa_passphrase=xyz
		wpa_key_mgmt=WPA-PSK
		wpa_pairwise=TKIP
		rsn_pairwise=CCMP
		##Some tutorials requires you to set a driver ID. If you need to do that, in order to check what is your current driver ID, run:
		#basename $( readlink /sys/class/net/wlan0/device/driver )
		#…but even though my driver ID reads brcmfmac_sdio, if I put it into the hostapd.conf file I still got an error, but commenting out does the trick.

		
		#preprocessed till here
		
		
#Next, let’s configure the network address translation:
	# backup
	sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup
	sudo nano /etc/sysctl.conf
	# ...un-comment or add to the bottom:
	net.ipv4.ip_forward=1
	# ...and activate it immediately:
	sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
# ...modify the iptables to create a network translation between eth0 and the wifi port wlan0
	sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
	# ...make this happen on reboot by runnig
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo nano /etc/network/interfaces
	# ...appending at then end:
	up iptables-restore < /etc/iptables.ipv4.nat
Let’s test our access point by running:
sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf
 # Your hotspot is up and running: try to connect to it from a computer or a smartphone. When you do so, you should also see some log activity on your terminal. If you're satisfied, stop it with CTRL+D
 # Let's clean everything:
	sudo service hostapd start
	sudo service isc-dhcp-server start
	# ...and make sure that we're up and running:
	sudo service hostapd status
	sudo service isc-dhcp-server status
	# ...let's configure our daemons to start at boot time:
	sudo update-rc.d hostapd enable
	sudo update-rc.d isc-dhcp-server enable
	# ...reboot the pi.
	sudo reboot
#You should now be able to see your pi WiFi, connect to it and access internet to it. As a quick comparison, streaming 4k videos will consume about 10% of the pi CPU so… use it accordingly.
#As a bonus, if you want to check what’s happening on your WiFi hotspot, check the log file:
#tail -f /var/log/syslog