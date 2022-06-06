#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendation/nix_ensure_bogus_icmp_responses_ignored.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/21/20    Recommendation "Ensure bogus ICMP responses are ignored"
# Eric Pinnell       11/12/20    Modified "Modified to use sub-functions"
# Eric Pinnell       04/08/22    Modified to enhance logging
#
nix_ensure_bogus_icmp_responses_ignored()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	# Set search location
	searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"
		
	kernel_parameter_chk()
	{
		# Checks for correctly set kernel parameters
		echo "- Start check - \"$kpname\" set to \"$kpvalue\"" | tee -a "$LOG" 2>> "$ELOG"
		# commenting out variables that are set in script bellow
		krp="" pafile="" fafile=""
#		kpname=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $1}' | xargs)
#		kpvalue=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $2}' | xargs)
#		searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"
		krp="$(sysctl "$kpname" | awk -F= '{print $2}' | xargs)"
		pafile="$(grep -Psl -- "^\h*$kpname\h*=\h*$kpvalue\b\h*(#.*)?$" $searchloc)"
		# fafile="$(grep -Psl -- "^\h*$kpname\h*=\h*((?!\b$kpvalue\b).)*$" $searchloc)"
		fafile="$(grep -s -- "^\s*$kpname" $searchloc | grep -Pv -- "\h*=\h*$kpvalue\b\h*" | awk -F: '{print $1}')"

		# If tests pass, we pass
		if [ "$krp" = "$kpvalue" ] && [ -n "$pafile" ] && [ -z "$fafile" ]; then
		   echo -e "- PASS:\n- \"$kpname\" is set to \"$kpvalue\" in the running configuration and in \"$pafile\""  | tee -a "$LOG" 2>> "$ELOG"
		   echo "- End check - \"$kpname\" set to \"$kpvalue\"" | tee -a "$LOG" 2>> "$ELOG"
		   return "${XCCDF_RESULT_PASS:-101}"
		else
		   # print the reason why we are failing
		   echo "- FAILED:"  | tee -a "$LOG" 2>> "$ELOG"
		   [ "$krp" != "$kpvalue" ] && echo "- \"$kpname\" is set to \"$krp\" in the running config" | tee -a "$LOG" 2>> "$ELOG"
		   [ -n "$fafile" ] && echo -e "- \"$kpname\" is set incorrectly in:\n  \"$fafile\"" | tee -a "$LOG" 2>> "$ELOG"
		   [ -z "$pafile" ] && echo "- \"$kpname = $kpvalue\" is not set in a kernel parameter configuration file" | tee -a "$LOG" 2>> "$ELOG"
		   echo "- End check - \"$kpname\" set to \"$kpvalue\"" | tee -a "$LOG" 2>> "$ELOG"
		   return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	kernel_parameter_fix()
	{
		echo "- Start remediation - set: \"$kpname\" to: \"$kpvalue\"" | tee -a "$LOG" 2>> "$ELOG"
		# commenting out variables that are set in script bellow
		krp="" pafile="" fafile=""
#		kpname=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $1}' | xargs)
#		kpvalue=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $2}' | xargs)
#		searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"
		krp="$(sysctl "$kpname" | awk -F= '{print $2}' | xargs)"
		pafile="$(grep -Psl -- "^\h*$kpname\h*=\h*$kpvalue\b\h*(#.*)?$" $searchloc)"
		fafile="$(grep -s -- "^\s*$kpname" $searchloc | grep -Pv -- "\h*=\h*$kpvalue\b\h*" | awk -F: '{print $1}')"		
		if grep -s -- "^\s*$kpname" $searchloc | grep -Pv -- "\h*=\h*$kpvalue\b\h*"; then
			echo "- Remediating \"$kpname\" set incorrectly in \"$fafile\"" | tee -a "$LOG" 2>> "$ELOG"
			grep -s -- "^\s*$kpname" $searchloc | grep -Pv -- "\h*=\h*$kpvalue\b\h*" | awk -F: '{print $1}' | while read -r l_filename; do
				sed -ri 's/^\s*(#\s*)?('"$kpname"'\s*=\s*)(\S+)(.*)?$/\2'"$kpvalue"'/' "$l_filename"
			done
		fi
		if ! grep -Pslq -- "^\h*$kpname\h*=\h*$kpvalue\b\h*(#.*)?$" $searchloc; then
			echo "- Remediating \"$kpname\" not set in a kernel parameter configuration file" | tee -a "$LOG" 2>> "$ELOG"
			(echo ""
			echo "$kpname = $kpvalue") >> "$l_sysctl_file"
		fi
		if [ "$krp" != "$kpvalue" ]; then
			echo "- Remediating \"$kpname\" set incorrectly in the running configuration"
			sysctl -w "$kpname"="$kpvalue"
			sysctl -w "$l_flush"
		fi
		echo "- End remediation - set: \"$kpname\" to: \"$kpvalue\"" | tee -a "$LOG" 2>> "$ELOG"
	}
			
	# Check sysctl net.ipv4.icmp_ignore_bogus_error_responses
	kpname="net.ipv4.icmp_ignore_bogus_error_responses"
	kpvalue="1"
	l_sysctl_file="/etc/sysctl.d/60-netipv4_sysctl.conf"
	l_flush="net.ipv4.route.flush=1"
	kernel_parameter_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		kernel_parameter_fix
		kernel_parameter_chk
		if [ "$?" = "101" ]; then
			[ "$test" != "failed" ] && test="remediated"
		else
			test="failed"
		fi
	fi
	
	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
		passed)
			echo -e "- Result - No remediation required\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo -e "- Result - successfully remediated\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo -e "- Result - requires manual remediation\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo -e "- Result - Recommendation is non applicable\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo -e "- Result - remediation failed\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}