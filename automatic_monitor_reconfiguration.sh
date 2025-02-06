#!/bin/bash

[ -z $BASH ] || shopt -s expand_aliases
alias BEGIN_OF_COMMENT="if [ ]; then" # this line is for activation of comment blocks
alias END_OF_COMMENT="fi"

if [[ -n $1 ]]; then
    # debug
    set -x
fi

#set +x;
#alias echo="{ set +x; } 2> /dev/null; builtin echo"

LOGGING_ENABLED_FLAG=false;
if [[ $LOGGING_ENABLED_FLAG == true ]]; then
	log_file=/home/user/Desktop/automatic_utilities/monitor_reconfiguration_log_file.txt;
else
	alias echo=":"
	alias cat=":"
	alias tee=":"
	log_file=/dev/null;
fi


#Adapt this script to your needs.
DEVICES=(/sys/class/drm/*/status)
DEVICES+=(/tmp/JACK)
DEVICES+=(/proc/acpi/button/lid/*/state)
DEVICES+=(/sys/class/power_supply/AC/online)

# below are small hassles with 2 environment variables which have impact on correct working of xrandr and nvidia-settings functions
# These variables can be different depending which display manager is used gdm, sddm, lightdm is used, etc.
# For gdm this X authority is used /run/user/125/gdm/Xauthority and this display is used :0.0. Although they don"t work
# so this section can be commented out and correct DISPLAY and XAUTHORITY environment variables can be hardcoded because only these environment variables are working correctly /run/user/1000/gdm/Xauthority for x authority and this :1.0 for display
#export DISPLAY=":1.0"; # when using Gnome with GDM
#export XAUTHORITY="/run/user/1000/gdm/Xauthority"; # when using Gnome with GDM
#export DISPLAY=":0.0"; # when using KDE with sddm
#export XAUTHORITY="/var/run/sddm/{efb5330-00289-1f4a-8b4e-8c8ad7657bfc}"; # when using KDE with sddm. Big caution is advised. It seems that in KDE in sddm this XAuthority file gets changed probably after every restart of Linux or restart of X server. So this variable should probably be detected on the fly like below
export XAUTHORITY="$(ps -C Xorg -f --no-header | sed -n "s/.*-auth //; s/ -[^ ].*//; p")";
export DISPLAY=":${display_ids[1]}.0";

BEGIN_OF_COMMENT
# 2 very important environment variables to make this whole script work correctly
export DISPLAY=":$(find /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##).0";
export XAUTHORITY="$(ps -C Xorg -f --no-header | sed -n "s/.*-auth //; s/ -[^ ].*//; p")";
declare -a display_ids=($(find /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##));
declare -a x_authorities=($XAUTHORITY);
echo "$(date +"%T:%3N"): Display id environment variable: $DISPLAY" | tee -a $log_file;
echo "$(date +"%T:%3N"): X authority environment variable: $XAUTHORITY" | tee -a $log_file;
echo "$(date +"%T:%3N"): number of displays ids: ${#display_ids[@]}" | tee -a $log_file;
echo "$(date +"%T:%3N"): displays ids: ${display_ids[@]}" | tee -a $log_file;
echo "$(date +"%T:%3N"): number of x authorities: ${#x_authorities[@]}" | tee -a $log_file;
echo "$(date +"%T:%3N"): X authorities: ${x_authorities[@]}" | tee -a $log_file;

export DISPLAY=":${display_ids[1]}.0";
export XAUTHORITY="${x_authorities[1]}";

END_OF_COMMENT


#edid_code_of_Sony=$(cat /home/user/Desktop/automatic_utilities/edid_of_Sony_monitor)
#edid_code_of_Samsung=$(cat /home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor)
#edid_code_of_Sony1=$(</home/user/Desktop/automatic_utilities/edid_of_Sony_monitor)
#edid_code_of_Samsung1=$(</home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor)
#IFS= read -r -d "" edid_code_of_Sony2 </home/user/Desktop/automatic_utilities/edid_of_Sony_monitor || [[ $edid_code_of_Sony2 ]]
#IFS= read -r -d "" edid_code_of_Samsung2 </home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor || [[ $edid_code_of_Samsung2 ]]
edid_code_of_Sony=$(tr -d "\0" </home/user/Desktop/automatic_utilities/edid_of_Sony_monitor)
edid_code_of_Samsung=$(tr -d "\0" </home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor)


declare -a monitors_ids=([0]="$edid_code_of_Sony" [1]="$edid_code_of_Samsung" );
card_0_path_prefix="/sys/class/drm/card0-" # can check some other time if card ID can change over time to card0 or card2 for instance and update this script accordingly to reflect card ID changes too
# it seems that it can change after gnome update from 1 to 0
card_1_path_prefix="/sys/class/drm/card1-" # can check some other time if card ID can change over time to card0 or

function display_by_name() { xrandr | grep -o -P "(?i)($1.+?[0-9])"; }

function get_output_video_interfaces() { 
	echo "$(date +"%T:%3N"): get_output_video_interfaces" | tee -a $log_file;
	# array passed as a reference parameter into this function which can 
	# be edited in this function and returned this way to the calling place
	local -n local_output_video_interfaces=$1 

	for video_interface_link in $(find /sys/class/drm/ -mindepth 1 -maxdepth 1 -type l); do
    echo "$(date +"%T:%3N"): $video_interface_link" | tee -a $log_file;
    local_output_video_interfaces+=("$video_interface_link");
	done

  #echo "$(date +"%T:%3N"): Resultant array of video interface symbolic links: ${local_output_video_interfaces[@]}" | tee -a $log_file;
  #echo "$(date +"%T:%3N"): Found number of video interface symbolic links: ${#local_output_video_interfaces[@]}" | tee -a $log_file;
}

function process_output_video_interfaces() { 
	echo "$(date +"%T:%3N"): process_output_video_interfaces" | tee -a $log_file;
	# array passed as a reference parameter into this function which can 
	# be edited in this function and returned this way to the calling place
	local -n local_output_video_interfaces=$1;
	
	#echo "$(date +"%T:%3N"): number of video output interfaces: ${#local_output_video_interfaces[@]}" | tee -a $log_file;
  #echo "$(date +"%T:%3N"): array of video interfaces: ${local_output_video_interfaces[@]}" | tee -a $log_file;
  
	for output_video_interface in "${local_output_video_interfaces[@]}"; do
		#echo $output_video_interface | tee -a $log_file;
		process_output_video_interface output_video_interface;
	done
}

function process_output_video_interface() { 
	local -n local_output_video_interface=$1; # output video interface passed as a string into this function
	
	echo "$(date +"%T:%3N"): process_output_video_interface: $local_output_video_interface" | tee -a $log_file;
	
	if [ -d "$local_output_video_interface" ]; then # if video interface directory exists
  	#print_video_interface_info local_output_video_interface
		if [ -f ${local_output_video_interface}/status ]; then # if status file exists
			connection_status=$(tr -d "\0" <${local_output_video_interface}/status)
			if [[ ${connection_status} == "connected" ]]; then
				print_video_interface_info local_output_video_interface;
				set_monitor_configuration local_output_video_interface
			fi
		fi
	else
  	echo "$(date +"%T:%3N"): $local_output_video_interface folder does not exist" | tee -a $log_file;
	fi	
}

function set_monitor_configuration() {
	echo "$(date +"%T:%3N"): set_monitor_configuration" | tee -a $log_file;
	local -n output_video_monitor=$1;
	
	path_to_monitor_edid="${output_video_monitor}/edid";
	monitor_edid_code=$(tr -d "\0" <$path_to_monitor_edid);
	
	echo -e "$(date +"%T:%3N"): monitor edid code:\n$monitor_edid_code" | tee -a $log_file;
	echo "$(date +"%T:%3N"): size of monitors array";
	echo ${#monitors_ids[@]} | tee -a $log_file;
	for monitor in "${monitors_ids[@]}"; do
		echo $monitor | tee -a $log_file;
	done
	
	#sleep 1;
	echo "$(date +"%T:%3N"): xrandr: $(xrandr)" | tee -a $log_file;
	
	current_screen_resolution=$(xrandr | grep -oP "(?i)((current) ([0-9]+ x [0-9]+))" | grep -oP "([0-9]+ x [0-9]+)"); 
	echo -e "$(date +"%T:%3N"): current screen resolution:\n$current_screen_resolution" | tee -a $log_file;
	if [[ ${monitor_edid_code} == ${edid_code_of_Samsung} ]]; then
		echo "$(date +"%T:%3N"): Samsung monitor connected" | tee -a $log_file;
		#if [[ ${current_screen_resolution} != "1920 x 1080" ]]; then 
			xrandr --output HDMI-0 --mode 1920x1080; # this resolution seems to be fine for Samsung monitor
			#xrandr --output HDMI-0 --mode 1280x1024; # this resolution seems to be fine for Samsung monitor
			#nvidia-settings --assign "CurrentMetaMode=HDMI-0: 1920x1080";
			#nvidia-settings --assign "CurrentMetaMode=HDMI-0: 1280x1024";
		#fi
		echo "$(date +"%T:%3N"): Screen resolution updated" | tee -a $log_file;
		current_screen_resolution1=$(xrandr | grep -oP "(?i)((current) ([0-9]+ x [0-9]+))" | grep -oP "([0-9]+ x [0-9]+)"); 
		echo -e "$(date +"%T:%3N"): current screen resolution1:\n$current_screen_resolution1" | tee -a $log_file;
	elif [[ ${monitor_edid_code} == ${edid_code_of_Sony} ]]; then
		echo "$(date +"%T:%3N"): Sony monitor connected" | tee -a $log_file;
		#if [[ ${current_screen_resolution} != "1600 x 1200" ]]; then 
			xrandr --output HDMI-0 --mode 1280x960; # in KDE this resolution seems to be fine
			#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1600x1200 +0+0 {ViewPortIn=1600x1200, ViewPortOut=2200x1650+0+0}"; # in Gnome this resolution seems to be fine
			#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1920x1080 +0+0 {ViewPortIn=1920x1080, ViewPortOut=2200x1650+0+0}";
		#fi
		echo "$(date +"%T:%3N"): Screen resolution updated" | tee -a $log_file;
		current_screen_resolution1=$(xrandr | grep -oP "(?i)((current) ([0-9]+ x [0-9]+))" | grep -oP "([0-9]+ x [0-9]+)"); 
		echo -e "$(date +"%T:%3N"): current screen resolution1:\n$current_screen_resolution1" | tee -a $log_file;
	else
		echo "$(date +"%T:%3N"): monitor with different, unknown EDID connected" | tee -a $log_file;
	fi
	
	# gamma reset
	#current_gamma=$(xgamma 2>&1 >/dev/null | grep -oP "(Green\s+\d+\.\d+)" | grep -oP "(\d+\.\d+)");
	#if [[ ${current_gamma} != "1.500" ]]; then
	#	xgamma -gamma 1.5
	#fi
	#xgamma -gamma 1.5 2>&1 2>/dev/null;
	
	#nvidia-settings --assign RedGamma=1,5;
	#nvidia-settings --assign GreenGamma=1,5;
	#nvidia-settings --assign BlueGamma=1,5;
}

function print_video_interface_info() { 
	local -n output_video_interface_path=$1;
	
	if [ -f ${output_video_interface_path}/status ]; then # if file exists
		echo "$(date +"%T:%3N"): status: $(cat ${output_video_interface_path}/status)" | tee -a $log_file;
	fi

	if [ -f ${output_video_interface_path}/uevent ]; then # if file exists
		echo "$(date +"%T:%3N"): uevent: $(cat ${output_video_interface_path}/uevent)" | tee -a $log_file;
	fi

	if [ -f ${output_video_interface_path}/modes ]; then # if file exists
		echo -e "$(date +"%T:%3N"): modes:\n$(cat ${output_video_interface_path}/modes)" | tee -a $log_file;
	fi
	
	if [ -f ${output_video_interface_path}/enabled ]; then # if file exists
		echo "$(date +"%T:%3N"): enabled/disabled: $(cat ${output_video_interface_path}/enabled)" | tee -a $log_file;
	fi

	if [ -f ${output_video_interface_path}/dpms ]; then # if file exists
		echo "$(date +"%T:%3N"): dpms: $(cat ${output_video_interface_path}/dpms)" | tee -a $log_file;
	fi

	if [ -f ${output_video_interface_path}/connector_id ]; then # if file exists
		echo "$(date +"%T:%3N"): connector_id: $(cat ${output_video_interface_path}/connector_id)" | tee -a $log_file;
	fi

	if [ -f ${output_video_interface_path}/edid ]; then # if file exists
		echo -e "$(date +"%T:%3N"): edid:\n$(cat ${output_video_interface_path}/edid)" | tee -a $log_file;
	fi
}

function print_edid_codes() { 
	echo "$(date +"%T:%3N"): Sony variable edid: $edid_code_of_Sony" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Sony variable edid1: $edid_code_of_Sony1" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Sony variable edid2: $edid_code_of_Sony2" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Sony variable edid3: $edid_code_of_Sony3" | tee -a $log_file;
	echo "$(date +"%T:%3N"): Sony cat edid:" | tee -a $log_file;
	cat /home/user/Desktop/automatic_utilities/edid_of_Sony_monitor | tee -a $log_file;

	echo "$(date +"%T:%3N"): Samsung variable edid: $edid_code_of_Samsung" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Samsung variable edid1: $edid_code_of_Samsung1" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Samsung variable edid2: $edid_code_of_Samsung2" | tee -a $log_file;
	#echo "$(date +"%T:%3N"): Samsung variable edid3: $edid_code_of_Samsung3" | tee -a $log_file;
	echo "$(date +"%T:%3N"): Samsung cat edid:" | tee -a $log_file;
	cat /home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor | tee -a $log_file;
}

function set_file_attributes_if_root_user {
if [[ $USER == "root" ]]; then
	chgrp -R user $log_file;
	chown -R user $log_file;
	chmod 777 $log_file;
fi
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#main section of the script

declare -a output_connectors=(DVI-I-1 DVI-D-1 LVDS-1 VGA-0 VGA-1 HDMI-0 HDMI-1 HDMI-A-1 DP-0 DP-1 DP-2 DP-3 DP-4 DP-5);
declare -a output_video_interfaces;

if [[ $LOGGING_ENABLED_FLAG == true ]]; then # if logging is enabled
	if [ -f $log_file ]; then # if log file exists
		if [[ $(stat -L -c "%a %G %U" $log_file) != "777 user user" ]]; then # if log file has wrong permissions and owner
			if [[ $USER != "root" ]]; then
				echo "$(date +"%T:%3N"): Caution: log file is owned by root. Recommended deletion of this file or changing its ownership" | tee -a $log_file; 
				exit;
			else
				set_file_attributes_if_root_user;	
			fi
		fi
	else # if log file doesn't exist
		touch $log_file;
		set_file_attributes_if_root_user;
	fi
fi

echo -e "$(date +"%T:%3N"): start of monitor reconfiguration script\n" | tee -a $log_file;
#echo "$(date +"%T:%3N"): udev event related to drm graphics card invoked (Direct Rendering Manager)" | tee -a $log_file;

echo "$(date +"%T:%3N"): Display id environment variable: $DISPLAY" | tee -a $log_file;
echo "$(date +"%T:%3N"): X authority environment variable: $XAUTHORITY" | tee -a $log_file;

#get_output_connectors output_connectors; # modifying array passed as an argument
#process_output_connectors output_connectors;

# new approach of this script just iterates over the content of this folder /sys/class/drm/ instead of inspecting these output connectors

get_output_video_interfaces output_video_interfaces; # modifying array passed as an argument
process_output_video_interfaces output_video_interfaces;

echo -e "$(date +"%T:%3N"): end of monitor reconfiguration script\n" | tee -a $log_file;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# old unused functions

function get_output_connectors() { 
	local -n output_connectors_array=$1

	pushd /sys/class/drm > /dev/null

	array_of_folder_elements=($(ls))
	number_of_elements_in_folder=${#array_of_folder_elements[@]}
	echo ${array_of_folder_elements[@]} | tee -a $log_file;
	echo "$(date +"%T:%3N"): number of elements in folder $number_of_elements_in_folder" | tee -a $log_file; 

	#for i in {1..${number_of_elements_in_folder}}
	for (( i = 0; i < $number_of_elements_in_folder; i++ ))
	do  
		echo "$(date +"%T:%3N"): Loop number:" $i
		echo ${array_of_folder_elements[i]};
		echo "$(date +"%T:%3N"): number of characters in element"
		echo ${#array_of_folder_elements[i]};
		
		card_prefix=${array_of_folder_elements[i]:0:4}
		#echo $card_prefix;
		if [ ${card_prefix} != "card" ] || [ ${#array_of_folder_elements[i]} -le 6 ] ; then
			unset array_of_folder_elements[i];
		else
			array_of_folder_elements[i]=${array_of_folder_elements[i]:6}
			if [[ ! " ${output_connectors_array[*]} " =~ " ${array_of_folder_elements[i]} " ]]; then
				output_connectors_array+=(${array_of_folder_elements[i]});
			fi
		fi
	done

	echo "$(date +"%T:%3N"): Transformed list of elements in folder"
	echo ${array_of_folder_elements[@]}
	echo ${output_connectors_array[@]}

	#echo "$(date +"%T:%3N"): transformed number of elements in folder"
	#number_of_elements_in_folder=${#array_of_folder_elements[@]}
	#echo $number_of_elements_in_folder;
	echo "$(date +"%T:%3N"): Transformed number of elements in outputs array: ${#output_connectors_array[@]}";

	popd > /dev/null

	#output_connectors_array+=( "${array_of_folder_elements[@]}" )
	
	#for (( i = 0; i < ${#array_of_folder_elements[@]}; i++ ))
	#do  
	#	echo ${array_of_folder_elements[i]};
	#	if [[ " ${output_connectors_array[*]} " =~ " ${array_of_folder_elements[i]} " ]]; then
	#			echo ${array_of_folder_elements[i]};
	#	else
	#			echo "$(date +"%T:%3N"): lol$i"
	#	fi
	#done
}

function process_output_connectors() { 
	echo "$(date +"%T:%3N"): process_output_connectors";
	local -n output_connectors_array=$1;
	
	echo "$(date +"%T:%3N"): number of output connectors"
	echo ${#output_connectors[@]}

	for output_connector in "${output_connectors[@]}"; do
		echo $output_connector;
		process_output_connector output_connector;
	done
}

function process_output_connector() { 
	echo "$(date +"%T:%3N"): process_output_connector";
	local -n local_output_connector=$1;
	echo $local_output_connector
	local_output_connector_path="${card_1_path_prefix}${local_output_connector}";
	echo $local_output_connector_path;
	
	if [ -d "$local_output_connector_path" ]; then
  	echo "$(date +"%T:%3N"): $local_output_connector_path folder exists"
  	#print_video_interface_info local_output_connector_path
  	#connection_status=$(cat ${local_output_connector_path}/status);
  	connection_status=$(tr -d "\0" <${local_output_connector_path}/status)
		#if [[ $(cat ${local_output_connector_path}/status) == "connected" ]]; then
		if [[ ${connection_status} == "connected" ]]; then
			print_video_interface_info local_output_connector_path;
			set_monitor_configuration local_output_connector
		fi
	else
  	echo "$(date +"%T:%3N"): $local_output_connector_path folder does not exist"
	fi	
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# comment section of the script

BEGIN_OF_COMMENT
if [[ $log_file != "/dev/null" ]]; then # if log file different than /dev/null
	if [ -f $log_file ]; then # if log file exists
		if [[ $(stat -L -c "%a %G %U" $log_file) != "777 user user" ]]; then # if log file has wrong permissions and owner
			if [[ $USER == "root" ]]; then
				chgrp -R user $log_file;
				chown -R user $log_file;
				chmod 777 $log_file;
			else
				echo "$(date +"%T:%3N"): Caution: log file is owned by root. Recommended deletion of this file or changing the ownership" | tee -a $log_file; 
				exit;
			fi
		fi
	fi
fi
END_OF_COMMENT

#connection_status=$(cat /sys/class/drm/card1-HDMI-A-1/status);

#xrandr_result=($(xrandr --listactivemonitors))

BEGIN_OF_COMMENT
echo "$(date +"%T:%3N"): status:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/status >> $log_file

echo "$(date +"%T:%3N"): uevent:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/uevent >> $log_file

echo "$(date +"%T:%3N"): modes:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/modes >> $log_file

echo "$(date +"%T:%3N"): enabled:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/enabled >> $log_file

echo "$(date +"%T:%3N"): edid:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/edid >> $log_file

echo "$(date +"%T:%3N"): dpms:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/dpms >> $log_file

echo "$(date +"%T:%3N"): connector_id:" >> $log_file
cat /sys/class/drm/card1-HDMI-A-1/connector_id >> $log_file
END_OF_COMMENT

BEGIN_OF_COMMENT
echo "$(date +"%T:%3N"): status:";
cat /sys/class/drm/card1-HDMI-A-1/status;

echo "$(date +"%T:%3N"): uevent:";
cat /sys/class/drm/card1-HDMI-A-1/uevent;

echo "$(date +"%T:%3N"): modes:";
cat /sys/class/drm/card1-HDMI-A-1/modes;

echo "$(date +"%T:%3N"): enabled:";
cat /sys/class/drm/card1-HDMI-A-1/enabled;

echo "$(date +"%T:%3N"): dpms:";
cat /sys/class/drm/card1-HDMI-A-1/dpms;

echo "$(date +"%T:%3N"): connector_id:";
cat /sys/class/drm/card1-HDMI-A-1/connector_id;

echo "$(date +"%T:%3N"): edid:";
cat /sys/class/drm/card1-HDMI-A-1/edid;

#current_edid_code=$(cat /sys/class/drm/card1-HDMI-A-1/edid)
current_edid_code=$(tr -d "\0" </sys/class/drm/card1-HDMI-A-1/edid)
END_OF_COMMENT

BEGIN_OF_COMMENT
DEVICES=(/sys/class/drm/*/status)
DEVICES+=(/tmp/JACK)
DEVICES+=(/proc/acpi/button/lid/*/state)
DEVICES+=(/sys/class/power_supply/AC/online)


for device in "${DEVICES[@]}"; do
	echo ${device};
done

for monitor in "${monitors_ids[@]}"; do
	echo $monitor;
done

for output_connector in DVI-I-1 LVDS-1 VGA-1 HDMI-0 HDMI-1; do
        echo $output >> /root/hotplug.log
        cat /sys/class/drm/card1-$output/status >> /root/hotplug.log
done
END_OF_COMMENT


BEGIN_OF_COMMENT
if [[ ${connection_status} == "connected" ]]; then
#if [[ ${xrandr_result[1]} > 0 ]]; then
	#echo "$(date +"%T:%3N"): monitor is currently connected" >> $log_file
	#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1600x1200 +0+0 {ViewPortIn=1600x1200, ViewPortOut=2200x1650+0+0}"
	#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1920x1080 +0+0 {ViewPortIn=1920x1080, ViewPortOut=2200x1650+0+0}"
	#echo $(xrandr) >> $log_file
	#xrandr -s 8;
	
	#current_edid_code=$(cat /sys/class/drm/card1-HDMI-A-1/edid)

	#edid_code_of_Sony=$(cat /home/user/Desktop/automatic_utilities/edid_of_Sony_monitor)
	#edid_code_of_Samsung=$(cat /home/user/Desktop/automatic_utilities/edid_of_Samsung_monitor)

	#echo "$(date +"%T:%3N"): current monitor:" >> $log_file;
	if [[ ${current_edid_code} == ${edid_code_of_Samsung} ]]; then
		#echo "$(date +"%T:%3N"): Samsung" >> $log_file;
		nvidia-settings --assign "CurrentMetaMode=HDMI-0: 1920x1080";
		#nvidia-settings --assign "CurrentMetaMode=HDMI-0: 1680x1050";
	#else
		#echo "$(date +"%T:%3N"): Sony" >> $log_file;
		#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1600x1200 +0+0 {ViewPortIn=1600x1200, ViewPortOut=2200x1650+0+0}";
		#nvidia-settings --assign "CurrentMetaMode=HDMI-0: nvidia-auto-select @1920x1080 +0+0 {ViewPortIn=1920x1080, ViewPortOut=2200x1650+0+0}";
	fi
#else
	#echo "$(date +"%T:%3N"): monitor is currently disconnected" >> $log_file
	#xrandr -s 12;
fi
END_OF_COMMENT



