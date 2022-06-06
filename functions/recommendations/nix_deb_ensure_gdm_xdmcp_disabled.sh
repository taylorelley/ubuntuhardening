#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_gdm_xdmcp_disabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown        04/15/22    Recommendation "Ensure XDCMP is not enabled"
# 

deb_ensure_gdm_xdmcp_disabled()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	
	nix_package_manager_set()
	{
		echo "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"
		if command -v rpm 2>/dev/null; then
			echo "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM -y remove"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM -y purge"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
			
	gnome_installed_chk()
	{
		echo "- Start check - Is GNOME Display Manager Installed" | tee -a "$LOG" 2>> "$ELOG"
		output=""
		
		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && output="- Unable to determine system's package manager"
		fi
		if [ -z "$output" ]; then
			# Check if GNOME Display Manager is installed
			$G_PQ gdm 2>>/dev/null && output="- $($G_PQ gdm | grep -Po 'Package:\h+\H+')\n- $($G_PQ gdm | grep -P 'Status:\h+')"
			if $G_PQ gdm3 2>>/dev/null; then
				if [ -z "$output" ]; then
					output="- $($G_PQ gdm3 | grep -Po 'Package:\h+\H+')\n- $($G_PQ gdm3 | grep -P 'Status:\h+')"
				else
					output="$output\n- $($G_PQ gdm3 | grep -Po 'Package:\h+\H+')\n- $($G_PQ gdm3 | grep -P 'Status:\h+')"
				fi
			fi
		fi
		# If package doesn't exist, we pass
		if [ -z "$output" ] ; then
			echo "- The GNOME Display Manager package is not installed" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is GNOME Display Manager Installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "$output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is GNOME Display Manager Installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	deb_ensure_gdm_xdmcp_disabled_chk()
	{
		if [ "$test" != "NA" ] ; then
			echo -e "- Start check - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
			if [ -f /etc/gdm3/custom.conf ]; then
				block=$(awk '/^\s*\[xdmcp\]/{f=1;next}/\[/{f=0;}f' /etc/gdm3/custom.conf)
				if [ -z "$block" ]; then
					echo -e "- PASS: - 'Enable=true' was NOT found in /etc/gdm3/custom.conf." | tee -a "$LOG" 2>> "$ELOG"
					echo -e "- End check - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-101}"
				elif grep -E '^\s*Enable\s*=\s*true\b' <<< "$block"; then
					echo -e "- FAIL: - 'Enable=true' was found in /etc/gdm3/custom.conf."  | tee -a "$LOG" 2>> "$ELOG"
					echo -e "- End check - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-102}"
				else
					echo -e "- PASS: - 'Enable=true' was NOT found in /etc/gdm3/custom.conf."  | tee -a "$LOG" 2>> "$ELOG"
					echo -e "- End check - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_FAIL:-101}"
				fi
			else
				echo -e "- FAIL: - '/etc/gdm3/custom.conf' was NOT found."  | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_FAIL:-102}"
			fi
		fi
	}

	deb_ensure_gdm_xdmcp_disabled_fix()
	{
		echo -e "- Start remediation - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
		sed -E -i '/^\s*\[xdmcp\]/,/\[/{/^\s*Enable/d}' /etc/gdm3/custom.conf
		
		block=$(awk '/^\s*\[xdmcp\]/{f=1;next}/\[/{f=0;}f' /etc/gdm3/custom.conf)
		if grep -Eqs '^\s*Enable\s*=\s*true\b'<<< "$block"; then
			test="failed"
		else
			test="remediated"
		fi
		echo -e "- End remediation - Ensure XDCMP is not enabled" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	# Check to see if GDM is installed
	gnome_installed_chk
	if [ "$?" = "101" ]; then
		test="NA"
	else
		# If GDM is installed
		deb_ensure_gdm_xdmcp_disabled_chk
		if [ "$?" = "101" ]; then
			[ -z "$test" ] && test="passed"
		else
			deb_ensure_gdm_xdmcp_disabled_fix
			deb_ensure_gdm_xdmcp_disabled_chk
			if [ "$?" = "101" ] ; then
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