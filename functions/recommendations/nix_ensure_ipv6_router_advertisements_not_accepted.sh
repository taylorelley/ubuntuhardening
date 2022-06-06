#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_ipv6_router_advertisements_not_accepted.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/22/20    Recommendation "Ensure IPv6 router advertisements are not accepted"
# Eric Pinnell       04/08/22    Modified to enhance logging
#
ensure_ipv6_router_advertisements_not_accepted()
{

	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	# Set search location
	searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"
	
	ipv6_enabled_chk()
	{
		# Check if IPv6 is enabled on the system
		echo "- Start check - Is IPv6 enabled on the system" | tee -a "$LOG" 2>> "$ELOG"
		passing=""
		grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl -- '^\h*(kernelopts=|linux|kernel)' {} \;)
#		searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"

		if [ -s "$grubfile" ]; then
			! grep -P -- "^\h*(kernelopts=|linux|kernel)" "$grubfile" | grep -vq -- ipv6.disable=1 && passing="true"
			[ "$passing" = true ] && output="IPv6 Disabled in \"$grubfile\""
		fi

		# Check network files
		if grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" $searchloc && \
		   grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$" $searchloc && \
		   sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" && \
		   sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$"; then
			[ -n "$output" ] && output="$output, and in sysctl config" || output="ipv6 disabled in sysctl config"
			passing="true"
		fi

		# If the regex matched, output would be generated.  If so, we pass
		if [ "$passing" = true ] ; then
			echo "- $output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is IPv6 enabled on the system" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo "- IPv6 is enabled on the system" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is IPv6 enabled on the system" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
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
	
	# Check net.ipv6.conf.all.accept_ra
	kpname="net.ipv6.conf.all.accept_ra"
	kpvalue="0"
	l_sysctl_file="/etc/sysctl.d/60-netipv6_sysctl.conf"
	l_flush="net.ipv6.route.flush=1"
	ipv6_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
		echo "- Skipping - IPv6 is disabled - \"$kpname\" not required" | tee -a "$LOG" 2>> "$ELOG"
	else
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
	fi
	
	# Check net.ipv6.conf.default.accept_ra
	kpname="net.ipv6.conf.default.accept_ra"
	kpvalue="0"
	l_sysctl_file="/etc/sysctl.d/60-netipv6_sysctl.conf"
	l_flush="net.ipv6.route.flush=1"
	ipv6_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
		echo "- Skipping - IPv6 is disabled - \"$kpname\" not required" | tee -a "$LOG" 2>> "$ELOG"
	else
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