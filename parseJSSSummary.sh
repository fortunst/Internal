#!/bin/bash

####################################################################################################
#
# Copyright (c) 2014, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
#	DESCRIPTION
#
#	This script was designed to read full JSS Summaries generated from version 9+.
#	The script will parse through the summary and return back a set of data that
#	should be useful when performing JSS Health Checks.
#
####################################################################################################
# 
#	HISTORY
#
#	Version 1.0 Created by Sam Fortuna on June 13th, 2014
#	Version 1.1 Updated by Sam Fortuna on June 17th, 2014
#		-Fixed issues with parsing some data types
#		-Added comments for readability
#		-Added output about check-in information
#		-Added database size parsing
#
####################################################################################################

#Enter the path to the JSS Summary (cannot includes spaces)
file=""

#Option to read in the path from Terminal
if [[ "$file" == "" ]]; then
	echo "Please enter the path to the JSS Summary file (currently does not support paths with spaces)"
	read file
fi

#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

#Gathers smaller chunks of the whole summary to make parsing easier

#Get the first 75 lines of the Summary
basicInfo=`head -n 75 $file`
#Find the line number that includes clustering information
lineNum=`cat $file | grep -n "Clustering Enabled" | awk -F : '{print $1}'`
#Store 100 lines after clustering information
subInfo=`head -n $(($lineNum + 100)) $file | tail -n 101`
#Find the line number for the push certificate Subject (used to get the expiration)
pushExpiration=`echo "$subInfo" | grep -n "com.apple.mgmt" | awk -F : '{print $1}'`
#Find the line number that includes checkin frequency information
lineNum=`cat $file | grep -n "Check-in Frequency" | awk -F : '{print $1}'`
#Store 30 lines after the Check-in Frequency information begins
checkInInfo=`head -n $(($lineNum + 30)) $file | tail -n 31`
#Store last 300 lines to check database table sizes
dbInfo=`tail -n 300 $file`


#Parse the data and print out the results
echo "JSS Version: \t\t\t\t $(echo "$basicInfo" | awk '/Installed Version/ {print $NF}')"
echo "Managed Computers: \t\t\t $(echo "$basicInfo" | awk '/Managed Computers/ {print $NF}')"
echo "Managed Mobile Devices: \t\t $(echo "$basicInfo" | awk '/Managed Mobile Devices/ {print $NF}')"
echo "Server OS: \t\t\t\t $(echo "$basicInfo" | grep "Operating System" | awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}')"
echo "Java Version: \t\t\t\t $(echo "$basicInfo" | awk '/Java Version/ {print $NF}')"
echo "Database Size: \t\t\t\t $(echo "$basicInfo" | grep "Database Size" | awk 'NR==1 {print $(NF-1),$NF}')"
echo "Maximum Pool Size: \t\t\t $(echo "$basicInfo" | awk '/Maximum Pool Size/ {print $NF}')"
echo "Maximum MySQL Connections: \t\t $(echo "$basicInfo" | awk '/max_connections/ {print $NF}')"
echo "Bin Logging: \t\t\t\t $(echo "$basicInfo" | awk '/log_bin/ {print $NF}')"
echo "Max Allowed Packet Size: \t\t $(($(echo "$basicInfo" | awk '/max_allowed_packet/ {print $NF}')/ 1048576)) MB"
echo "MySQL Version: \t\t\t\t $(echo "$basicInfo" | awk '/version ..................../ {print $NF}')"
echo "Clustering Enabled: \t\t\t $(echo "$subInfo" | awk '/Clustering Enabled/ {print $NF}')"
echo "Change Management Enabled: \t\t $(echo "$subInfo" | awk '/Use Log File/ {print $NF}')"
echo "Log File Location: \t\t\t $(echo "$subInfo" | awk -F . '/Location of Log File/ {print $NF}')"
echo "SSL Certificate Subject: \t      $(echo "$subInfo" | awk '/SSL Cert Subject/ {$1=$2=$3="";print $0}')"
echo "SSL Certificate Expiration: \t\t $(echo "$subInfo" | awk '/SSL Cert Expires/ {print $NF}')"
echo "HTTP Threads: \t\t\t\t $(echo "$subInfo" | awk '/HTTP Connector/ {print $NF}')"
echo "HTTPS Threads: \t\t\t\t $(echo "$subInfo" | awk '/HTTPS Connector/ {print $NF}')"
echo "JSS URL: \t\t\t\t $(echo "$subInfo" | awk '/HTTPS URL/ {print $NF}')"
echo "APNS Expiration: \t\t\t $(echo "$subInfo" | grep "Expires" | awk 'NR==3 {print $NF}')"
echo "External CA Enabled: \t\t\t $(echo "$subInfo" | awk '/External CA enabled/ {print $NF}')"
echo "Log Flushing Time: \t\t\t $(echo "$subInfo" | grep "Each Day" | awk '{for (i=7; i<NF; i++) printf $i " "; print $NF}')"
echo "Number of logs set to NOT flush:  $(echo "$subInfo" | awk '/Do not flush/ {print $0}' | wc -l)"
echo "Check in Frequency: \t\t\t $(echo "$checkInInfo" | awk '/Check-in Frequency/ {print $NF}')"
echo "Login/Logout Hooks enabled: \t\t $(echo "$checkInInfo" | awk '/Logout Hooks/ {print $NF}')"
echo "Startup Script enabled: \t\t $(echo "$checkInInfo" | awk '/Startup Script/ {print $NF}')"
echo "Flush history on re-enroll: \t\t $(echo "$checkInInfo" | awk '/Flush history on re-enroll/ {print $NF}')"
echo "Flush location info on re-enroll: \t $(echo "$checkInInfo" | awk '/Flush location information on re-enroll/ {print $NF}')"
echo "Push Notifications enabled: \t\t $(echo "$checkInInfo" | awk '/Push Notifications Enabled/ {print $NF}')"


#Check for database tables over 1 GB in size
echo "Tables over 1 GB in size:"
echo "$(echo "$dbInfo" | awk '/GB/ {print $1, "\t", "\t", $(NF-1), $NF}')"

#Find problematic policies that are ongoing, enabled, update inventory and have a scope defined
list=`cat $file| grep -n "Ongoing" | awk -F : '{print $1}'`

echo "The following policies are Ongoing, Enabled and update inventory:"

for i in $list 
do

	#Check if policy is enabled
	test=`head -n $i $file | tail -n 13`
	enabled=`echo "$test" | awk /'Enabled/ {print $NF}'`
	
	#Check if policy has an active trigger
	if [[ "$enabled" == "true" ]]; then
		trigger=`echo "$test" | grep Triggered | awk '/true/ {print $NF}'`
	fi
		
	#Check if the policy updates inventory
	if [[ "$enabled" == "true" ]]; then
		line=$(($i + 35))
		inventory=`head -n $line $file | tail -n 5 | awk '/Update Inventory/ {print $NF}'`
	fi
	
	#Get the scope
	scope=`head -n $(($i + 5)) $file |tail -n 5 | awk '/Scope/ {$1=""; print $0}'`
		
		#Get the name of the policy
		if [[ "$trigger" == "true" && "$inventory" == "true" ]]; then
			name=`echo "$test" | awk -F . '/Name/ {print $NF}'`
			echo "Name: $name" 
			echo "Scope: $scope"
		fi
done

exit 0