#!/usr/bin/env sh
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/fct/nix_audit_suid.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Patrick Araya      09/23/20    Recommendation "Audit SUID executables"
# David Neilson	     04/02/22	 Nothing to check or fix.  All manual.
audit_suid()
{
	echo "Recommendation \"$RNA\" Manual remediation required" | tee -a "$LOG" 2>> "$ELOG"

	if [ -n "$XCCDF_RESULT_PASS" ]; then
		echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
		return "${XCCDF_RESULT_FAIL:-102}"
	else 
		echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
		return "${XCCDF_RESULT_PASS:-106}"
	fi
}
