#!/bin/bash
usage()
{
cat << EOF
usage: $0 -t REPORT_TYPE

Valid options for REPORT_TYPE are:
    all (default)
    technical (only the technical stuff)
    competition (one report for the competitions)

OPTIONS:
    -h      Shows this message
    -t      Report type (default: all)
EOF
}

##########################################
# Entry point for script
##########################################
REPORT_TYPE=

# Gathering input values. Some basics at the follwing page
# http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
while getopts “ht:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         t)
             REPORT_TYPE=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

# Checking if the input values are set
if [[ -z $REPORT_TYPE ]]
then
     usage
     exit 1
fi

# Checking if the input values are set properly
if [[ $REPORT_TYPE != "all" && $REPORT_TYPE != "next_year" && "competition" ]]; then
     usage
     exit 1
fi

# List of different reports where they go
# List your report in only one of these variables.
# There are two different types of reports. One for technical details
# and one for more project management details. Examples of this could be the
# design of the Mission Control System which is technical while
# the report about "infrastructure" (what type of infrastructure we
# used during the project like git, github and a build server) is more about
# project management.

# The target audience for the technical report is for everyone that is
# intrested in the AUV while the "infrastructure" report targets next year
# students.
#
# overview: Only one report of 10 pages that goes through the Naiad AUV on a
# very high-level.
#
# project_management: Lessons learned during the Naiad AUV project and
# suggestions for the upcoming projects in the future.
#
# technical: All the reports that have any technical details about the AUV.
TECHNICAL="space_plug_and_play_avionics
            ip_over_can_bus"

# Leave empty
REPORTS=

if [[ $REPORT_TYPE == "all" ]]; then
    REPORTS=$TECHNICAL
fi

### Generate all reports
for report in $REPORTS
do
    cd $report
    make
    cd ..
done

### Merge all reports
PDF_FILES_TO_MERGE=
for report in $REPORTS
do
    PDF_FILES_TO_MERGE="$PDF_FILES_TO_MERGE $report/sigproc-sp.pdf"
done

pdftk $PDF_FILES_TO_MERGE cat output $REPORT_TYPE.pdf

