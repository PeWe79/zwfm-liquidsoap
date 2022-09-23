# Update OS
sudo apt update -y 
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

# Install FDKAAC and bindings
sudo apt install fdkaac libfdkaac-ocaml libfdkaac-ocaml-dynlink -y

# Get deb package
wget https://github.com/savonet/liquidsoap/releases/download/v2.1.1/liquidsoap_2.1.1-ubuntu-jammy-1_amd64.deb -O /tmp/liq_2.2.1_amd64.deb

# Install deb package 
sudo apt install /tmp/liq_2.2.1_amd64.deb --fix-broken

# Make dir for files
sudo mkdir /etc/liquidsoap
sudo chown -R liquidsoap:liquidsoap /etc/liquidsoap

# Download radio.liq
sudo wget https://raw.githubusercontent.com/oszuidwest/liquidsoap-ubuntu/main/radio.liq -O /etc/liquidsoap/radio.liq

# Install service
sudo wget https://raw.githubusercontent.com/oszuidwest/liquidsoap-ubuntu/main/liquidsoap.service -O /etc/systemd/system/liquidsoap.service
sudo systemctl daemon-reload
sudo systemctl enable liquidsoap.service
