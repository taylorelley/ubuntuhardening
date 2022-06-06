#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_permissions_bootloader_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/15/20    Recommendation "Ensure permissions on bootloader config are configured"
# Eric Pinnell       04/19/22    Modified to correct possible errors and enhance logging
#

ensure_permissions_bootloader_configured()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	
	bootloader_perm_chk()
	{
		echo "- Start check - bootloader permissions" | tee -a "$LOG" 2>> "$ELOG"
		
		tst1="" tst2="" tst3="" tst4="" output="" output2="" output3="" output4=""

		# Variables being set in the main script
#		grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl '^\h*(kernelopts=|linux|kernel)' {} \;)
#		grubdir=$(dirname "$grubfile")

		stat -c "%a" "$l_grubfile" | grep -Pq '^\h*[0-7]00$' && tst1=pass
		output="Permissions on \"$l_grubfile\" are \"$(stat -c "%a" "$l_grubfile")\""

		stat -c "%u:%g" "$l_grubfile" | grep -Pq '^\h*0:0$' && tst2=pass
		output2="\"$l_grubfile\" is owned by \"$(stat -c "%U" "$l_grubfile")\" and belongs to group \"$(stat -c "%G" "$l_grubfile")\""

		if [ -f "$l_grubdir/user.cfg" ]; then
			stat -c "%a" "$l_grubdir/user.cfg" | grep -Pq '^\h*[0-7]00$' && tst3=pass
			output3="Permissions on \"$l_grubdir/user.cfg\" are \"$(stat -c "%a" "$l_grubdir/user.cfg")\""

			stat -c "%u:%g" "$l_grubdir/user.cfg" | grep -Pq '^\h*0:0$' && tst4=pass
			output4="\"$l_grubdir/user.cfg\" is owned by \"$(stat -c "%U" "$l_grubdir/user.cfg")\" and belongs to group \"$(stat -c "%G" "$l_grubdir/user.cfg")\""
		else
			tst3=pass
			tst4=pass
		fi

		if [ "$tst1" = "pass" ] && [ "$tst2" = "pass" ] && [ "$tst3" = "pass" ] && [ "$tst4" = "pass" ]; then
			passing=true
		fi

		# If passing is true we pass
		if [ "$passing" = true ] ; then
			echo "- PASSED" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output" ] && echo "- $output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output2" ] && echo "- $output2" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output3" ] && echo "- $output3" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output4" ] && echo "- $output4" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - bootloader permissions" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo "- FAILED"  | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output" ] && echo "- $output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output2" ] && echo "- $output2" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output3" ] && echo "- $output3" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output4" ] && echo "- $output4" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - bootloader permissions" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	bootloader_perm_fix()
	{
		echo "- Start remediation - update grub file(s) permissions" | tee -a "$LOG" 2>> "$ELOG"
		if [ -f "$l_grubdir"/user.cfg ]; then
			chown root:root "$l_grubdir"/user.cfg
			chmod og-rwx "$l_grubdir"/user.cfg
		fi
		if [ -f "$l_grubdir"/grubenv ]; then
			chown root:root "$l_grubdir"/grubenv
			chmod og-rwx "$l_grubdir"/grubenv
		fi
		if [ -f "$l_grubdir"/grub.cfg ]; then
			chown root:root "$l_grubdir"/grub.cfg
			chmod og-rwx "$l_grubdir"/grub.cfg
		fi
		if [ -f "$l_grubdir"/grub.conf ]; then
			chown root:root "$l_grubdir"/grub.conf
			chmod og-rwx "$l_grubdir"/grub.conf
		fi
		echo "- End remediation - update grub file(s) permissions" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	l_grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl '^\h*(kernelopts=|linux|kernel)' {} \;)
	l_grubdir=$(dirname "$l_grubfile")
	
	bootloader_perm_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		if grep -Pq -- "^\h*\/boot\/efi\/" <<< "$l_grubdir"; then
			test="manual"
		else
			bootloader_perm_fix
			bootloader_perm_chk
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