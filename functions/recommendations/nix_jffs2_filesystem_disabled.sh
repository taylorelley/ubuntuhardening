#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_jffs2_filesystem_disabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/17/20    Recommendation "Ensure mounting of jffs2 filesystems is disabled"
# Eric Pinnell       04/19/22    Modified corrected false positive and enhanced logging
#

jffs2_filesystem_disabled()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	
	kernel_module_chk()
	{
		echo "- Start check - Is kernel module \"$XCCDF_VALUE_REGEX\" loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
		tst1="" output="" output2=""
		if modprobe -n -v "$XCCDF_VALUE_REGEX" >/dev/null; then
			output="$(modprobe -n -v "$XCCDF_VALUE_REGEX")"
			grep -Pq -- "^\h*install\h+\/bin\/(true|false)\b" <<< "$output" && tst1="passed"
			output2="$(lsmod | grep "$XCCDF_VALUE_REGEX")"
		else
			tst1="passed"
		fi
		if [ "$tst1" = "passed" ] && [ -z "$output2" ]; then
			echo -e "- PASSED:\n- kernel module \"$XCCDF_VALUE_REGEX\" is not loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is kernel module \"$XCCDF_VALUE_REGEX\" loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo "- FAILED:"
			[ "$tst1" != "passed" ] && echo "- kernel module \"$XCCDF_VALUE_REGEX\" is loadable" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output2" ] && echo "- kernel module \"$XCCDF_VALUE_REGEX\" is loadable" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Is kernel module \"$XCCDF_VALUE_REGEX\" loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	kernel_module_fix()
	{
		echo "- Start remediation - ensure kernel module \"$XCCDF_VALUE_REGEX\" is not loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
		output="" output2=""
		output="$(modprobe -n -v "$XCCDF_VALUE_REGEX")"
		output2="$(lsmod | grep "$XCCDF_VALUE_REGEX")"
		! grep -Pq -- "^\h*install\h+\/bin\/(true|false)\b" <<< "$output" && echo "install $XCCDF_VALUE_REGEX /bin/true" >> /etc/modprobe.d/"$XCCDF_VALUE_REGEX".conf
		[ -n "$output2" ] && rmmod "$XCCDF_VALUE_REGEX"
		echo "- End remediation - ensure kernel module \"$XCCDF_VALUE_REGEX\" is not loaded or loadable" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	XCCDF_VALUE_REGEX="jffs2"
	kernel_module_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		kernel_module_fix
		kernel_module_chk
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