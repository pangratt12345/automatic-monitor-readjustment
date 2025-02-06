# automatic-monitor-readjustment  
bash script to automatically readjust monitor configuration after every reboot and for monitor cable unplug/replug using udev events  

`automatic_monitor_reconfiguration.desktop` file should be placed in a location like this `~/.config/autostart` depending on Linux distribution  
`automatic_monitor_reconfiguration.sh` file can be placed in any location. In this example in `/home/user/Desktop/automatic_utilities/`  
`100-monitor-hotplug.rules` file should be placed in this location `/etc/udev/rules.d/`  
Then udev events handler service should be restart to use this custom rule for monitor cable unplug/replug events  
`sudo udevadm control --reload-rules`  
`sudo service udev restart`  

`chmod +x /home/user/Desktop/automatic_utilities/automatic_monitor_reconfiguration.sh`  

when using udev monitor cable unplug/replug events then these 2 environment variables are important to be set in automatic script `DISPLAY`, `XAUTHORITY`  
`export DISPLAY=":$(find /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##).0";`  
`export XAUTHORITY="$(ps -C Xorg -f --no-header | sed -n "s/.*-auth //; s/ -[^ ].*//; p")";`  

useful command  
`sudo udevadm monitor --property`  
