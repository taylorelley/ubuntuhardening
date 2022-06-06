#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_bootloader_password_set.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/18/20    Recommendation "Ensure bootloader password is set"
# Eric Pinnell       04/14/22    Modified to account for UEFI boot, work with all Linux distros, and enhance logging
#
ensure_bootloader_password_set()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	bootloader_password_chk()
	{
		echo "- Start check - bootloader password set" | tee -a "$LOG" 2>> "$ELOG"
		tst1="" tst2="" output="" grubdir=""

		# Determine directory containg grub files
		grubdir=$(dirname "$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -El -- '^\s*(kernelopts=|linux|kernel)' {} \;)")

		# Check user.cfg first
		if [ -f "$grubdir/user.cfg" ]; then
			grep -Piq -- '^\h*GRUB2_PASSWORD\h*=\h*.+$' "$grubdir/user.cfg" && output="bootloader password set in \"$grubdir/user.cfg\""
		fi

		# If password isn't configured in user.cfg, check grub.cfg
		if [ -z "$output" ] && [ -f "$grubdir/grub.cfg" ]; then
			grep -Piq -- '^\h*set\h+superusers\h*=\h*"?[^"\n\r]+"?(\h+.*)?$' "$grubdir/grub.cfg" && tst1=pass
			grep -Piq -- '^\h*password(_pbkdf2)?\h+\H+\h+.+$' "$grubdir/grub.cfg" && tst2=pass
			[ "$tst1" = pass ] && [ "$tst2" = pass ] && output="bootloader password set in \"$grubdir/grub.cfg\""
		fi

		# IF password isn't configured in either user.cfg or grub.cfg, check grub.conf
		if [ -z "$output" ] && [ -f "$grubdir/grub.conf" ]; then
			grep -Piq -- '^\h*password\h+\H+\h+.+$' "$grubdir/grub.conf" && output="bootloader password set in \"$grubdir/grub.conf\""
		fi

		# If the output variable is set, we pass
		if [ -n "$output" ] ; then
			echo -e "- PASS:\n- $output" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - bootloader password set" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo "- FAIL:"
			[ -f "$grubdir/user.cfg" ] && echo "- bootloader password is not set in \"$grubdir/user.cfg\"" | tee -a "$LOG" 2>> "$ELOG"
			[ -f "$grubdir/grub.cfg" ] && echo "- bootloader password is not set in \"$grubdir/grub.cfg\"" | tee -a "$LOG" 2>> "$ELOG"
			[ -f "$grubdir/grub.conf" ] && echo "- bootloader password is not set in \"$grubdir/grub.conf\"" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - bootloader password set" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	bootloader_password_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		test="manual"
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