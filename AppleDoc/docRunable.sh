#
# Document builder shell script
#

echo "START"

#
#copy the appledoc utility to your /usr/local/bin
#
echo "Copying...... appledoc utility to /usr/local/bin"
sudo cp $SRCROOT/AppleDoc/appledoc /usr/local/bin

#
#create appledoc folder to copy the doc templates in appledoc directory
#
echo "Create...... appledoc folder in the Application Support directory"

sudo mkdir ~/Library/Application\ Support/appledoc

#
#copy all the templates in the created directory
#
echo "Copy document templates to the appledoc....."
sudo cp -r $SRCROOT/AppleDoc/Templates/ ~/Library/Application\ Support/appledoc

#apply the appledoc to create apple documents
/usr/local/bin/appledoc $SRCROOT/$PROJECT_NAME