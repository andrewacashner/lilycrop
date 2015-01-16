#! /bin/sh

##########################################################################
# LILYCROP
# Produce individual cropped EPS or PDF images from a lilypond file 
#
# Andrew A. Cashner, andrewacashner@gmail.com, 2015
# https://github.com/andrewacashner/lilypond/lilycrop.sh
#
# The basic cropping technique comes from Andrea, jayaratna@gmail.com, 
# on the lilypond-user mailing list.
#
##################################################################### 
#
# Many lilypond users need to produce small cropped images for
# use in other documents, such as in musicological articles.
# But lilypond does not correctly determine the bounding boxes for 
# images when using the EPS backend.
# This script compiles a lilypond file and then creates separate
# cropped EPS or PDF files for the content on each separate page.
# When producing PDF output, this process greatly reduces the file size.
#
# The script checks the input file to see if there is more 
# than one page. If there are multiple pages, it splits
# the PDF into separate PDFs and then crops the individual
# images. If there is only one page, it crops that page.
#
# Usage:  lilycrop [-e] file.ly  (.ly MUST be included)
#           option -e : Produce EPS output
#           default   : Produce PDF output
# 
# Output: If single page input: file-crop.eps or file_crop.pdf
#         If multiple pages:    file-1-crop.eps, file-2-crop.eps (or PDF)
#       
# To INSTALL: 
#    - Copy lilycrop.sh to somewhere in the file search path,
#      e.g., $HOME/bin/ 
#    - Make file executable: chmod +x lilycrop.sh
#    - You may wish to remove the .sh from the filename
# 
#####################################################################
# You are free to reuse, modify, or distribute this code
# for any purpose.
# There is no warrantee: use with caution.
# Please send feedback for improvement.
#
# This is written for a BASH shell on Debian GNU/Linux.
# In addition to the standard *nix core utilities, 
# you will need to have the following programs installed:
#   - lilypond, pdftk, pdftops, ps2eps
##########################################################################

# Enable automatic BASH error checking
set -e

# Starting marker for messages in terminal
terminalalert="--> LILYCROP:"

################################
# Check command-line arguments
# Set output mode and filename

NO_ARGS="0"
EXIT_ERROR="85"
PDF_MODE="0"
EPS_MODE="1"

# Function to display help information and exit
help_exit () {
	echo "Usage: lilycrop [-e] file.ly"
	echo "          Option -e : Produce EPS output"
	echo "          Default   : Produce PDF output"
	exit "$EXIT_ERROR"
}

# Check for command-line arguments
#   If none, explain proper usage and exit with error
if [ "$#" -eq "$NO_ARGS" ] # Script invoked with no command-line arguments?
then	
	help_exit
fi

# Set default output mode
mode="$PDF_MODE"

# Check for option argument to change output mode
while getopts "e" option
do
	case "$option" in
		e )	mode="$EPS_MODE"
			# Move to next argument (filename)
			shift $(($OPTIND - 1))
			;;
		* )	# Automatic error message for invalid option
			;; 
	esac
done

# Check for valid filename
if [ ! -f "$1" ]
then
	echo "ERROR: Invalid filename "$1""
	help_exit
fi

##########################
# FUNCTION: CROP INPUT PDF

# Convert PDF to EPS, trim bounding box
# If PDF mode, convert EPS back to PDF

croplily () {
	file="${1%.pdf}"
	croppedfile="$file-crop"

	# Convert PDF to EPS, trim EPS bounding box
	pdftops -eps "$file".pdf
	cat "$file".eps | ps2eps > "$croppedfile".eps

	if [ "$mode" -eq "$PDF_MODE" ]
	then
		# PDF_MODE: Convert EPS to PDF
		fileextension="pdf"
		epstopdf "$croppedfile".eps
		rm "$file".eps "$croppedfile".eps
	else	
		# EPS_MODE: No further action
		fileextension="eps"
	fi
	
	# Report outcome
	echo "$terminalalert Cropped file '$croppedfile.$fileextension' produced from '$1'"
}
#########################

# Get input file name
lilyinput="${1%.ly}"

# Compile with lilypond
lilypond "$lilyinput"

# Get filename of lilypond output PDF 
inputpdf="$lilyinput.pdf"

# Check number of pages in output PDF
pages=$(pdftk "$inputpdf" dump_data output | grep -oP "(?<=NumberOfPages: )[0-9]+")

# If more than 1 page, then burst into separate PDFs, then crop each burst PDF 
# If only one page, then crop the input PDF
if [ "$pages" -gt "1" ]
then 
	echo "$terminalalert $pages pages found; splitting images before cropping"
	pdftk "$inputpdf" burst

	# Loop through each burst PDF image, 
	# change the file name to match the base file,
	# add image number (taken from loop counter "imagecount")
	imagecount=0
	for burstpdf in pg_*.pdf 
	do 
		imagecount=$((imagecount + 1)) 
		newfilename="${inputpdf%.pdf}-$imagecount.pdf"
		mv "$burstpdf" "$newfilename"
		croplily "$newfilename" # TO FUNCTION above
		rm "$newfilename" # remove original burst PDF
	done
	rm doc_data.txt	# remove auxiliary data file produced by pdftk
else 
	croplily "$inputpdf"  # TO FUNCTION above
fi

exit 0




