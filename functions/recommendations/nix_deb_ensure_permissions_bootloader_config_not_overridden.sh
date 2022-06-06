#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_permissions_bootloader_config_not_overridden.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       04/14/22    Recommendation "Ensure permissions on bootloader config are not overridden"
#
deb_ensure_permissions_bootloader_config_not_overridden()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	
	permissions_bootloader_config_chk()
	{
		# Check if permissions on bootloader config are overridden
		echo "- Start check - are permissions on bootloader config overridden" | tee -a "$LOG" 2>> "$ELOG"
		output=""
		l_var1="$(grep -E '^\s*chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new' -A 1 -B1 /usr/sbin/grub-mkconfig)"
		if grep -Pq -- '([^#\n\r]+\h+)?\h*chmod\h+([^04][0-9][0-9]|[0-9][1-9][0-9]|[0-9][0-9][1-9])\b.*$' <<< "$l_var1"; then
			output="- chmod set to: \"$(awk '/^\s*chmod\s+[0-9][0-9][0-9]/{print $2}' <<< $l_var1)\" in \"/usr/sbin/grub-mkconfig\""
		fi
		if grep -Pq -- '\&\&\h+\!\h+grep\h+\"\^password\"\h+\$\{grub_cfg\}\.new\h+\>\/dev\/null' <<< "$l_var1"; then
			if [ -z "$output" ]; then
				output="- check that grub password is not being set to before running chmod command exists in \"/usr/sbin/grub-mkconfig\""
			else
				output="$output\n- check that grub password is not being set to before running chmod command exists in \"/usr/sbin/grub-mkconfig\""
			fi
		fi
		if [ -z "$output" ]; then
			# If the regex isn't matched, no output would be generated.  If so, we pass
			echo -e "- PASS:\n- chmod set to: \"$(awk '/^\s*chmod\s+[0-9][0-9][0-9]/{print $2}' <<< $l_var1)\" in \"/usr/sbin/grub-mkconfig\"" | tee -a "$LOG" 2>> "$ELOG"
			echo "- check that grub password is not being set to before running chmod command doesn't exists in \"/usr/sbin/grub-mkconfig\"" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - are permissions on bootloader config overridden" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "- FAIL:\n$output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - are permissions on bootloader config overridden" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	permissions_bootloader_config_fix()
	{
		echo "- Start remediation - permissions on bootloader config overridden" | tee -a "$LOG" 2>> "$ELOG"
		l_var1="$(grep -E '^\s*chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new' -A 1 -B1 /usr/sbin/grub-mkconfig)"
		if grep -Pq -- '([^#\n\r]+\h+)?\h*chmod\h+([^04][0-9][0-9]|[0-9][1-9][0-9]|[0-9][0-9][1-9])\b.*$' <<< "$l_var1"; then
			echo "- Start remediation - set chmod to \"400\" in: \"/usr/sbin/grub-mkconfig\"" | tee -a "$LOG" 2>> "$ELOG"
			sed -ri 's/chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new/chmod 400 ${grub_cfg}.new/' /usr/sbin/grub-mkconfig
			echo "- Finish remediation - set chmod to \"400\" in: \"/usr/sbin/grub-mkconfig\"" | tee -a "$LOG" 2>> "$ELOG"
		fi
		if grep -Pq -- '\&\&\h+\!\h+grep\h+\"\^password\"\h+\$\{grub_cfg\}\.new\h+\>\/dev\/null' <<< "$l_var1"; then
			echo "- Start remediation - remove check on password not being set before running chmod command"
			sed -ri 's/ && ! grep "\^password" \$\{grub_cfg\}.new >\/dev\/null//' /usr/sbin/grub-mkconfig
			echo "- Finish remediation - remove check on password not being set before running chmod command"
		fi
		echo "- End remediation - permissions on bootloader config overridden" | tee -a "$LOG" 2>> "$ELOG"
	}
			
	# Check permissions on bootloader config are not overridden
	permissions_bootloader_config_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		permissions_bootloader_config_fix
		permissions_bootloader_config_chk
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