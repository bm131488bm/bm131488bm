#!/bin/bash
#
#	Version: 1.3
#
#	Made by autopear@WeiPhone
#
#	Put all deb files into the sub-folder "debs"
#
#	This script must be put at the parent folder of "debs"
#
#	Type "sh scandebs" to run the script
#
# beginning of script
ws=$(pwd)
if [ $# -ge 2 ]; then
	echo "Invalid operand!"
	exit
fi
if [ $# -eq 1 ]; then
	if [[ $1 = "-h" || $1 = "--help" ]]; then
		echo "-v | --version        Show version"
		echo "-s | --sign           Sign Release"
		echo "-h | --help           Show this help"
		exit
	fi
	if [[ $1 = "-v" || $1 = "--version" ]]; then
		echo "scandebs"
		echo "Version: 1.3"
		exit
	fi
	if [[ $1 = "-s" || $1 = "--sign" ]]; then
		sign=1
	else
		sign=0
	fi
	if [[ $1 != "-h" && $1 != "--help" && $1 != "-v" && $1 != "--version" && $1 != "-s" && $1 != "--sign" ]]; then
		echo "Invalid operand!"
		exit
	fi
fi
rm -f "$ws/Release" "$ws/Release.gpg" "$ws/Packages.bz2" "$ws/Packages.gz"
if [ -e "$ws/Packages" ]; then
	echo "Packages already existed!"
else
#
# other repo should modify this url
	wget http://35free.net/jackie099
# end of modify Packages' url
#
fi
#
# check EOF of Packages
if [ "$(tail -1 "$ws/Packages" | wc -m)" -ne 1 ]; then
	echo >> "$ws/Packages"
fi
# end of checking EOF of Packages
#
# write control to Packages
if [ ! -e "$ws/debs" ]; then
	echo "Folder debs does not exist, program will quit..."
	exit 1
fi
cd "$ws/debs"
nodeb=$(find "$ws/debs" -name "*.deb" | wc -l)
if [ "$nodeb" == 0 ]; then
	echo "There is no deb file under folder debs, program will quit..."
	exit 1
fi
ls *.deb > "$ws/debs/.debtmp"
cd ..
to=$(ls "$ws/debs/"*.deb | wc -l)
cnt=1
while [ "$cnt" -le "$to" ]; do
	line=$(sed -n "$cnt"p "$ws/debs/.debtmp")
	cnt=$((cnt+1))
	deb=$(ls "debs/$line" | sed "s:^:`pwd`/:")
	filename=$(basename "$deb")
	size=$(stat -c %s "$deb")
	if [ -e /usr/bin/md5sum ]; then 
		md5=$(md5sum "$deb" | cut -c -32)
	else
		md5=$(openssl md5 "$deb" | cut -f2 -d' ')
	fi
	dpkg-deb -e "$deb" "$ws/debs/.infotmp"
	sed -i "/^$/d" "$ws/debs/.infotmp/control"
	sed -i '3a\Filename: debs/'"$filename"'\nSize: '"$size"'\nMD5sum: '"$md5"'' "$ws/debs/.infotmp/control"
	pkl=$(grep -m 1 "Package: " "$ws/debs/.infotmp/control")
	sed -i "s/$pkl//g" "$ws/debs/.infotmp/control"
	sed -i '1i\'"$pkl"'' "$ws/debs/.infotmp/control"
	sed -i "/^$/d" "$ws/debs/.infotmp/control"
	echo >> "$ws/debs/.infotmp/control"
#
# delete old duplicate entries
	pack=$(grep -m 1 "Package: " "$ws/debs/.infotmp/control")
	#h=$(grep -n "$pack" "$ws/Packages" | grep -v "$pack".. | cut -f1 -d':')
	h=$(grep -n "$pack"$ "$ws/Packages" | cut -f1 -d':')
	nl=$(echo "$h" | wc -m)
	if [ "$nl" -gt 1 ]; then
		tail --lines=+"$h" "$ws/Packages" > "$ws/.tmp"
		h=$((h-1))
		head --lines="$h" "$ws/Packages" > "$ws/.hd"
		t=$(($(grep -nm 1 "^$" "$ws/.tmp" | cut -f1 -d':')+1))
		tail --lines=+"$t" "$ws/.tmp" > "$ws/.tl"
		cat "$ws/.hd" "$ws/.tl" > "$ws/Packages"
		rm -f "$ws/.tmp" "$ws/.hd" "$ws/.tl"
	fi
# end of deleting old duplicate entries
#
	cat "$ws/debs/.infotmp/control" >> "$ws/Packages"
	rm -rf "$ws/debs/.infotmp"
done
rm -f "$ws/debs/.debtmp"
# end of writing control to Packages
#
# rearrange Packages
rm -f "$ws/.sortlist" "$ws/.pksort"
grep "Package: " "$ws/Packages" | sort -f > "$ws/.sortlist"
nop=$(grep "Package: " "$ws/Packages" | wc -l)
cnt=1
while [ "$cnt" -le "$nop" ]; do
	pk=$(sed -n "$cnt"p "$ws/.sortlist")
	#pb=$(grep -n "$pk" "$ws/Packages" | grep -v "$pk".. | cut -f1 -d':')
	pb=$(grep -n "$pk"$ "$ws/Packages" | cut -f1 -d':')
	pe=$(($(tail --lines=+"$pb" "$ws/Packages" | grep -nm 1 "^$" | cut -f1 -d':')-1))
	tail --lines=+"$pb" "$ws/Packages" | head --line="$pe" >> "$ws/.pksort"
	echo >> "$ws/.pksort"
	cnt=$(($cnt+1))
done
mv -f "$ws/.pksort" "$ws/Packages"
rm -f "$ws/.sortlist"
# end of rearranging Packages
#
# compress Packages to bz2 and gz
bzip2 -zkf "$ws/Packages"
cp -p "$ws/Packages" "$ws/.p"
gzip -f "$ws/Packages"
mv -f "$ws/.p" "$ws/Packages"
# end of compression
#
# create and add entries to Release
if [ -e /usr/bin/md5sum ]; then 
	md5=$(md5sum "$ws/Packages" | cut -c -32)
else
	md5=$(openssl md5 "$ws/Packages" | cut -f2 -d' ')
fi
size=$(stat -c %s "$ws/Packages")
echo " $md5 $size Packages" >> "$ws/.rel"
if [ -e /usr/bin/md5sum ]; then 
	md5=$(md5sum "$ws/Packages.bz2" | cut -c -32)
else
	md5=$(openssl md5 "$ws/Packages.bz2" | cut -f2 -d' ')
fi
size=$(stat -c %s "$ws/Packages.bz2")
echo " $md5 $size Packages.bz2" >> "$ws/.rel"
if [ -e /usr/bin/md5sum ]; then 
	md5=$(md5sum "$ws/Packages.gz" | cut -c -32)
else
	md5=$(openssl md5 "$ws/Packages.gz" | cut -f2 -d' ')
fi
size=$(stat -c %s "$ws/Packages.gz")
echo " $md5 $size Packages.gz" >> "$ws/.rel"
echo >> "$ws/.rel"
echo "Origin: jackie099的cydia源" > "$ws/.rl"
echo "Label: jackie099" >> "$ws/.rl"
echo "Suite: stable" >> "$ws/.rl"
echo "Version: 1.0" >> "$ws/.rl"
echo "Codename: jackie099" >> "$ws/.rl"
echo "Architectures: iphoneos-arm" >> "$ws/.rl"
echo "Components: main" >> "$ws/.rl"
echo "Description: 099的常用软件源" >> "$ws/.rl"
echo "MD5Sum:" >> "$ws/.rl"
cat "$ws/.rl" "$ws/.rel" > "$ws/Release"
rm -f "$ws/.rel" "$ws/.rl"
# end of creating Release
#
# sign Release
if [ "$sign" = 1 ]; then
	gpg -abs --passphrase "Edit_as_password_of_private_key" -r "Edit_as_user_of_private_key" -o "$ws/Release.gpg" "$ws/Release"
fi
# end of signing Release
echo "All done!"
if [ "$sign" = 1 ]; then
	echo "Upload Packages, Packages.bz2, Packages.gz, Release, Release.gpg and all the deb files to the repo's FTP manually."
else
	echo "Upload Packages, Packages.bz2, Packages.gz, Release and all the deb files to the repo's FTP manually."
fi
# end of script
