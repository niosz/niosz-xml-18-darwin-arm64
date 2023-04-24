#!/usr/bin/env •run

####################################################################################################################################################################################
function main() { ##################################################################################################################################################################
####################################################################################################################################################################################

# ----------------------------------------------------------------------------------------------------------------------------------------------------- setting correct node version
echo "🌐0️⃣ configure correct node version";
NODEVERSION=`cat package.json | grep description | •trim | awk -F'"' '{print $4}' | •trim`;
CURRVERSION=`•nodeinfo`;
echo "NODE VERSION REQUIRED : $NODEVERSION";
echo "NODE CURRENT VERSION  : $CURRVERSION";
if [ ! "$NODEVERSION" = "$CURRVERSION" ]; then
	echo "NODE CURRENT VERSION  : changing node version from «$CURRVERSION» to «$NODEVERSION»";
	•nodeset $NODEVERSION;
	CURRVERSION=`•nodeinfo`;
	if [ ! "$NODEVERSION" = "$CURRVERSION" ]; then
		echo "NODE CURRENT VERSION  : changing node version faluire";
		return 1;
	fi;
	echo "NODE CURRENT VERSION  : $CURRVERSION";
fi;

# ----------------------------------------------------------------------------------------------------------------------------------------------------- build
HAVECHANGES=0;
if [ -d ./dist ]; then
	if [ -d ./dist_old ]; then
		echo "🌐1️⃣ removing previous dist_old folder";
		rm -rf ./dist_old;
	fi;
	echo "🌐2️⃣ backup dist folder to dist_old";
	mv dist dist_old;
fi;
echo "🌐3️⃣ creating dist folder";
mkdir dist;
cp dist.json dist/package.json;
cd dist;
npm install libxmljs;
rm -f *.json;
cd ..;
if [ -d ./dist_old ]; then
	echo "🌐4️⃣ performing comparison for changes";
	cat `find dist_old -type f | grep package.json` > old.txt;
	cat `find dist -type f | grep package.json` > new.txt;
	DIFFERENCES=`diff new.txt old.txt | •trim`;
	if [ ! "$DIFFERENCES" = "" ]; then
		HAVECHANGES=1;
	fi;
fi;

# ----------------------------------------------------------------------------------------------------------------------------------------------------- reload published
echo "🌐5️⃣ reloading published version";
if [ -d ./check ]; then
	echo "🌐6️⃣ removing previous check version";
	rm -rf ./check;
fi;
echo "🌐7️⃣ preparing check";
PACKAGENAME=`cat package.json | grep name | •trim | awk -F'"' '{print $4}' | •trim`;
mkdir check;
cp dist.json check/package.json;
cd check;
npm install $PACKAGENAME 2>/dev/null;
PUBLISHEDVERSION=`cat package.json | grep $PACKAGENAME | •trim | awk -F'"' '{print $4}' | sed 's/^[^0-9]*//' | •trim`;
if [ "$PUBLISHEDVERSION" = "" ]; then
	PUBLISHEDVERSION="1.0.0";
fi;
cd ..;
rm -rf ./check;
FULLVERSION=`cat package.json | grep version | •trim | awk -F'"' '{print $4}' | •trim`;
cat package.json | sed 's/"version": "'$FULLVERSION'"/"version": "'$PUBLISHEDVERSION'"/' > package.json.tmp && mv package.json.tmp package.json;

# ------------------------------------------------------------------------------------------------------------------------------------------------- cleaning data
echo "🌐8️⃣ cleaning data";
rm -rf ./dist_old 2>/dev/null;
rm -f ./old.txt 2>/dev/null;
rm -f ./new.txt 2>/dev/null;
rm -rf ./check 2>/dev/null;
rm -f ./dist/package.json 2>/dev/null;
rm -f ./dist/package-lock.json 2>/dev/null;


# ----------------------------------------------------------------------------------------------------------------------------------------------------- detected changes
if [ $HAVECHANGES -ne 0 ]; then

	# ------------------------------------------------------------------------------------------------------------------------------------------------- increase version
	echo "🌐9️⃣ increase software version";
	FULLVERSION=`cat package.json | grep version | •trim | awk -F'"' '{print $4}' | •trim`;
	MAJOR=`echo "$FULLVERSION" | awk -F'.' '{print $1}'`;
	MINOR=`echo "$FULLVERSION" | awk -F'.' '{print $2}'`;
	FIXES=`echo "$FULLVERSION" | awk -F'.' '{print $3}'`;
	FIXES=`•inc $FIXES`;
	if [ $FIXES -gt 9 ]; then
		FIXES=0;
		MINOR=`•inc $MINOR`;
		if [ $MINOR -gt 9 ]; then
			MINOR=0;
			MAJOR=`•inc $MAJOR`;
		fi;
	fi;
	NEWFULLVERSION="$MAJOR.$MINOR.$FIXES";
	cat package.json | sed 's/"version": "'$FULLVERSION'"/"version": "'$NEWFULLVERSION'"/' > package.json.tmp && mv package.json.tmp package.json;
	echo "OLD SOFTWARE VERSION  : $FULLVERSION";
	echo "SOFTWARE VERSION      : $NEWFULLVERSION";

	# ------------------------------------------------------------------------------------------------------------------------------------------------- finalize
	echo "🌐🔟 finalize git and npm";
	git add .;
	git commit -m "new version $NEWFULLVERSION";
	git push;
	npm publish;

fi;

####################################################################################################################################################################################
}; main; ###########################################################################################################################################################################
####################################################################################################################################################################################