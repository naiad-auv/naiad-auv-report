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

function add_line_numbers()
{
### Takes one parameter as input, that is the PDF that needs
### line numbers.
REPORT=$1
ORIG_PDF=$report/sigproc-sp.pdf
PDF_NAME=$report

mkdir -pv tempFolder123
cp $ORIG_PDF tempFolder123/$PDF_NAME.pdf
cd tempFolder123

### Count number of pages
PAGES=$( pdfinfo $PDF_NAME.pdf | grep 'Pages' - | awk '{print $2}' )

### Generate page number document

cat > ./pagenumbers.tex <<EOF
\documentclass[12pt,a4paper]{article}
\usepackage{multido}
\usepackage[hmargin=.8cm,vmargin=1.5cm,nohead,nofoot]{geometry}
\begin{document}
\multido{}{$PAGES}{\vphantom{x}\newpage}
\end{document}
EOF

pdflatex pagenumbers.tex

pdftk $PDF_NAME.pdf burst output file_%03d.pdf
pdftk pagenumbers.pdf burst output number_%03d.pdf

time for i in $(seq -f %03g 1 $PAGES) ; do \
    pdftk file_$i.pdf background number_$i.pdf output new-$i.pdf ; done

pdftk new-???.pdf output $PDF_NAME.pdf

# No compression for individual reports, too small to begin with.
#gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE \
#    -dQUIET -dBATCH -sOutputFile=$PDF_NAME-compressed.pdf $PDF_NAME.pdf

cd ..

mv tempFolder123/$PDF_NAME.pdf final_reports/
# No compression for individual reports, too small to begin with.
# mv tempFolder123/$PDF_NAME-compressed.pdf final_reports/

### Remove temporary folder
rm -rf tempFolder123

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

# Hardware
### Hull
### actuators
### Sensors
# Mainboard
### Connection between hardware, firmware and software.
# Software
### AVR / Firmware
### beaglebone black
### Gimme 2
### Simulator on shore...very last as well as IDE.

#           hull
#           generic_can
#           power_supply_kill_switch

TECHNICAL=" pneumatics
            thruster_controller
            vision_hardware
            hydrophone
            inertial_navigation_system
            sensor_controller
            at90can_drivers
            bbb_to_can
            vision_software
            motion_control
            sensor_fusion
            missionctrl
            bootloader_and_configuration_manager
            simulator
            space_plug_and_play_avionics
            ip_over_can_bus"


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

### Merge all reports and generate each report with line numbers
rm -rf final_reports
mkdir -pv final_reports
PDF_FILES_TO_MERGE=

for report in $REPORTS
do
    PDF_FILES_TO_MERGE="$PDF_FILES_TO_MERGE $report/sigproc-sp.pdf"
    echo '=============================='
    echo $report
    add_line_numbers $report
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

mv tempFolder123/$REPORT_TYPE.pdf final_reports/
mv tempFolder123/$REPORT_TYPE-compressed.pdf final_reports/

### Remove temporary folder
rm -rf tempFolder123
