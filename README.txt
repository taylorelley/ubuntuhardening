The CIS Linux Build Kit (CIS-LBK) is a GZIP Compressed Tar Archive file containing the file structure and files to run the Build Kit for a specific CIS Linux Benchmark.

Exclusion List:
	The CIS-LBK include a file called "exclusion_list.txt".  This file allows for recommendations to be excluded from the LBK's remediation.  To use this file, add the number of the recommendation you would like excluded.  Each recommendation's number should be added to its own line in this file

Remediation Function Return Codes:
	101 - Passed - No remediation required
	102 - Failed - Manual Remediation may be required
	103 - Remediated - Build Kit successfully remediated the recommendation
	104 - Not Applicable - Recommendation has been determined to be non applicable
	105 - Skipped - Recommendation is not part of the selected profile or has been added to the excluded list
	106 - Manual - Recommendation needs to be remediated manually
