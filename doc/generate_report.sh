#!/bin/bash
usage()
{
cat << EOF
usage: $0 -t REPORT_TYPE

Valid options for REPORT_TYPE are:
    all (default)
    technical (only the technical stuff)
    lessons_learned (only leassons learned stuff)
    competition (one overview report for the competitions)

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
if [[ $REPORT_TYPE != "all"
        && $REPORT_TYPE != "technical"
        && $REPORT_TYPE != "competition"
        && $REPORT_TYPE != "lessons_learned" ]]; then
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

TECHNICAL="bbb_to_can
            at90can_drivers
            bootloader_and_configuration_manager
            space_plug_and_play_avionics
            ip_over_can_bus
            hydrophone
            inertial_navigation_system
            simulator
            pneumatics
            thruster_controller
            sensor_controller
            vision_hardware
            vision_software"

#            motion_control

LL="project_management
    hardware_managers_lessons_learned
    sponsorship
    development_and_operations"

COMPETITION="naiad_overview"

# Leave empty
REPORTS=

if [[ $REPORT_TYPE == "all" ]]; then
    REPORTS="$COMPETITION $TECHNICAL $LL"
elif [[ $REPORT_TYPE == "lessons_learned" ]]; then
    REPORTS="$LL"
elif [[ $REPORT_TYPE == "technical" ]]; then
    REPORTS="$TECHNICAL"
elif [[ $REPORT_TYPE == "competition" ]]; then
    REPORTS="$COMPETITION"
fi

### Generate all reports
for report in $REPORTS
do
    cd $report
    echo '""""""""'
    echo $report
    echo '""""""""'
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

### Count number of pages
PAGES=$( pdfinfo $REPORT_TYPE.pdf | grep 'Pages' - | awk '{print $2}' )

mkdir -pv tempFolder123
mv $REPORT_TYPE.pdf tempFolder123/$REPORT_TYPE.pdf

### Generate page number document
cd tempFolder123

cat > ./pagenumbers.tex <<EOF
\documentclass[12pt,a4paper]{article}
\usepackage{multido}
\usepackage[hmargin=.8cm,vmargin=1.5cm,nohead,nofoot]{geometry}
\begin{document}
\multido{}{$PAGES}{\vphantom{x}\newpage}
\end{document}
EOF

pdflatex pagenumbers.tex

pdftk $REPORT_TYPE.pdf burst output file_%03d.pdf
pdftk pagenumbers.pdf burst output number_%03d.pdf

time for i in $(seq -f %03g 1 $PAGES) ; do \
    pdftk file_$i.pdf background number_$i.pdf output new-$i.pdf ; done

pdftk new-???.pdf output $REPORT_TYPE.pdf

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE \
    -dQUIET -dBATCH -sOutputFile=$REPORT_TYPE-compressed.pdf $REPORT_TYPE.pdf

cd ..

mv tempFolder123/$REPORT_TYPE.pdf .
mv tempFolder123/$REPORT_TYPE-compressed.pdf .

### Remove temporary folder
rm -rf tempFolder123
