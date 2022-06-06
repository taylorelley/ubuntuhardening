#!/usr/bin/env bash
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_system_administrator_command_executions_are_collected.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       04/18/22    Recommendation "Ensure system administrator command executions (sudo) are collected"
# 

ensure_system_administrator_command_executions_are_collected()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	test=""

	auditd_rule_chk()
	{
		echo -e "- Start check - checking for auditd rule with regex\n- \"$XCCDF_VALUE_REGEX\"" | tee -a "$LOG" 2>> "$ELOG"
		output="" output2="" foutput="" foutput2="" location="" REGEXCHK="" archvar=""
		archvar=$(grep -Po -- 'arch=b(32|64)' <<< "$XCCDF_VALUE_REGEX")
		if arch | grep -vq "x86_64" && [ "$archvar" = "arch=b64" ]; then
			output="- 64 bit rule:\n- $XCCDF_VALUE_REGEX\nnot applicable on a 32 bit system" | tee -a "$LOG" 2>> "$ELOG"
		else
			REGEXCHK="$(sed -r "s/auid(>=|>|=>)([0-9]+)/auid>=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)/g" <<< "$XCCDF_VALUE_REGEX")"
			REGEXCHK="$(sed -r 's/\\[sh]\+auid!=(4294967295|-1|\(4294967295\|-1\)|\(-1\|4294967295\))\\[sh]\+/\\h+(?:auid!=(?:unset|-1|4294967295)|(?:unset|-1|4294967295)!=auid)\\h+/g' <<< "$REGEXCHK")"
			REGEXCHK="$(sed -r 's/( |\\[sh]\+)(-k\\s\+|(-F( |\\s\+|\\h\+)key=)).*$/\\h+(?:-k\\h+\\H+\\b|-F\\h*key=\\H+\\b)\\h*(?:#[^\\n\\r]+)?$/g' <<< "$REGEXCHK")"
			# check auditd rules files
			if grep -Psq -- "$REGEXCHK" /etc/audit/rules.d/*.rules; then
				output="$(grep -Ps -- "$REGEXCHK" /etc/audit/rules.d/*.rules | cut -d: -f2)"
				location="$(grep -Pls -- "$REGEXCHK" /etc/audit/rules.d/*.rules)"
			else
				foutput="No auditd rules were found in any /etc/audit/rules.d/*.rules file matching the regular expression:\n\"$REGEXCHK\"\n"
			fi
			# Check auditd running config
			if auditctl -l | grep -Pq -- "$REGEXCHK"; then
				output2="$(auditctl -l | grep -P -- "$REGEXCHK")"
			else
				foutput2="- No auditd rules were found in the running config matching the regular expression:\n- \"$REGEXCHK\"\n"
			fi
		fi
		# If the regex matched, failed output wouldn't be generated.  If so, we pass
		if [ -z "$foutput" ] && [ -z "$foutput2" ]; then
			echo "- PASSED" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output" ] && echo -e "- audit rule: \"$output\"\n- exists in: \"$location\"" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$output2" ] && echo -e "\n- audit rule: \"$output2\"\n- exists in the running auditd config" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - auditd rule with regex\n- \"$XCCDF_VALUE_REGEX\"" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo "FAILED"
			[ -n "$foutput" ] && echo -e "$foutput" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$foutput2" ] && echo -e "$foutput2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - auditd rule with regex\n- \"$XCCDF_VALUE_REGEX\"" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	auditd_rule_fix()
	{
		echo -e "- Start remediation - add auditd rule:\n- \"$l_auditd_rule\"" | tee -a "$LOG" 2>> "$ELOG"
		echo "$l_auditd_rule" >> "$l_auditd_rule_file"
		if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
			echo "- Reboot required to load auditd rule" | tee -a "$LOG" 2>> "$ELOG"
			G_REBOOT_REQUIRED="yes"
		else
			augenrules --load
		fi
		echo -e "- End remediation - add auditd rule:\n- \"$l_auditd_rule\"" | tee -a "$LOG" 2>> "$ELOG"
	}
	
	# Set variables
	l_auditd_rule_file="/etc/audit/rules.d/50-actions.rules"
	l_uid_min="$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"
	
	# check rules
	l_auditd_rule="-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -F auid>=$l_uid_min -F auid!=-1 -F key=actions"
	XCCDF_VALUE_REGEX="^\s*-a\s+(?:exit,always|always,exit)\s+-F\s+arch=b32\s+(?!(?:\2|\3|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\3|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\2|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\2|\3))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?:-k\s+\S+|-F\s+key=\S+)\s*.*$"
	auditd_rule_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		auditd_rule_fix
		if [ "$G_REBOOT_REQUIRED" = "yes" ]; then
			test="manual"
		else
			auditd_rule_chk
			if [ "$?" = "101" ]; then
				[ "$test" != "manual" ] && [ "$test" != "failed" ] && test="remediated"
			else
				test="failed"
			fi
		fi
	fi
	
	l_auditd_rule="-a always,exit -F arch=b32 -C euid!=uid -F euid=0 -Fauid>=$l_uid_min -F auid!=4294967295 -S execve -k actions"
	XCCDF_VALUE_REGEX="^\s*-a\s+(?:exit,always|always,exit)\s+-F\s+arch=b64\s+(?!(?:\2|\3|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\3|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\2|\4))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?!(?:\1|\2|\3))(-S\s+execve|(?:-C\s+(?:uid!=euid|euid!=uid)\s+-F\s+euid=0|-F\s+euid=0\s+-C\s+(?:uid!=euid|euid!=uid))|-F\s*auid>=1000|-F\s+auid!=(?:-1|4294967295))\s+(?:-k\s+\S+|-F\s+key=\S+)\s*.*$"
	auditd_rule_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		auditd_rule_fix
		if [ "$G_REBOOT_REQUIRED" = "yes" ]; then
			test="manual"
		else
			auditd_rule_chk
			if [ "$?" = "101" ]; then
				[ "$test" != "manual" ] && [ "$test" != "failed" ] && test="remediated"
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