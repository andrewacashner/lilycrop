#! /bin/sh

##########################################################################
# LILYCROP
# Produce individual cropped PDF images from a lilypond file 
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
# cropped PDFs for the content on each separate page.
#
# The script checks the input file to see if there is more 
# than one page. If there are multiple pages, it splits
# the PDF into separate PDFs and then crops the individual
# images. If there is only one page, it crops that page.
#
# Usage:  lilycrop file.ly (.ly may be omitted)
# Output: If single page input: file-crop.ly
#         If multiple pages:    file-1-crop.ly, file-2-crop.ly, etc.
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

##########################
# FUNCTION: CROP INPUT PDF

# Convert PDF to EPS, trim EPS bounding box, convert EPS back to PDF
# Modify file name
croplily () {
	file="${1%.pdf}"
	croppedfile="$file-crop.pdf"
	pdftops -eps "$file".pdf
	cat "$file".eps | ps2eps > "$file"_cut.eps
	epstopdf "$file"_cut.eps
	rm "$file".eps "$file"_cut.eps
	mv "$file"_cut.pdf "$croppedfile"
	echo "$terminalalert Cropped PDF '$croppedfile' produced from '$1'"
}
#########################

# Get input file name
lilyinput="${1%.ly}"

# Compile with lilypond
lilypond "$lilyinput"

# Get output PDF file name
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





