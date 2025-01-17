#!/data/data/com.termux/files/usr/bin/bash

ARCHITECTURE=$(dpkg --print-architecture)

#Adding colors
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

#Warning
echo ${R}"Warning!
Error may occur during installation."
echo " "
echo ${C}"Script made by No Hope#0281 "
sleep 2
clear

#requirements
pkg install proot pulseaudio wget -y
clear
echo "Please allow storage permissions"
termux-setup-storage
clear

#Notice
echo ${C}"Please check your architecture first in order to install the right rootfs."
echo ${C}"Your architecture is $ARCHITECTURE ."
case `dpkg --print-architecture` in
    aarch64)
            echo "Please download the rootfs file for arm64." ;;
    arm*)
            echo "Please download the rootfs file for armhf." ;;
    ppc64el)
            echo "Please download the rootfs file for ppc64el.";;
    x86_64)
            echo "Please download the rootfs file for amd64." ;;
    *)
            echo "Unknown architecture"; exit 1 ;;
esac
echo "Press enter to continue"
read enter
sleep 1
clear

#Links
echo ${G}"Have you already downloaded the file? (y/n)"
read link 
if [[ "$link" =~ ^([yY])$ ]]; then 
        echo ${G}"Please put in the absolute path you put the file in"
        echo ${G}"If you put your file in your downloads, the absolute path would be"
        echo ${Y}"/sdcard/Download/"your file""
        read path  
        sleep 1
        echo 
        echo ${Y}"Your path is $path"
        sleep 1 
        echo 
        if [ ! -f "$path" ]; then
        echo ${R}"Cannot find your file"
        echo "No such file or directory "
        sleep 2
        exit 1
        fi 
elif [[ "$link" =~ ^([nN])$ ]]; then
        echo ${G}"Please put in your URL here for downloading rootfs: "${W}
        read URL        
        sleep 1
else 
        echo "Cannot identify your answer" ; exit 1
fi 
echo ${G}"Please put in your distro name in order to login after the installation.
If you put in 'kali' , afterwards your login script will be 'bash kali.sh' "${W}
read ds_name
sleep 1
echo ${Y}"Your distro name is $ds_name "${W}
sleep 2

folder=$ds_name-fs
if [ -d "$folder" ]; then
        echo ${G}"Existing file found, are you sure to remove it? (y or n)"${W}
        read ans
        if [[ "$ans" =~ ^([yY])$ ]]; then
                echo ${W}"Deleting existing directory...."${W}
                rm -rf ~/$folder
                rm -rf ~/$ds_name.sh
                sleep 2
        elif [[ "$ans" =~ ^([nN])$ ]]; then
        echo ${R}"Sorry, but we cannot complete the installation"
        exit
        else 
        echo
        fi
else 
mkdir -p $folder
fi


#Downloading and decompressing rootfs
clear      
if [[ "$link" =~ ^([nN])$ ]]; then
        echo ${G}"Downloading Rootfs....."${W}
        wget $URL -P ~/$folder/ 
        path=~/$folder/*.tar.*
fi 
echo ${G}"Decompressing Rootfs....."${W}
proot --link2symlink \
    tar -xpf $path -C ~/$folder/ --exclude='dev'||:
if [[ ! -d "$folder/etc" ]]; then
     mv $folder/*/* $folder/
fi
echo "127.0.0.1 localhost" > ~/$folder/etc/hosts
rm -rf ~/$folder/etc/resolv.conf
echo "nameserver 8.8.8.8" > ~/$folder/etc/resolv.conf
echo -e "#!/bin/sh\nexit" > "$folder/usr/bin/groups"
mkdir -p $folder/binds


#Sound Fix
echo "export PULSE_SERVER=127.0.0.1" >> $folder/root/.bashrc

##script
echo ${G}"writing launch script"
sleep 1
bin=$ds_name.sh
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
## uncomment following line if you are having FATAL: kernel too old message.
#command+=" -k 4.14.81"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A $folder/binds)" ]; then
    for f in $folder/binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /dev/null:/proc/stat"
command+=" -b /sys"
command+=" -b /data/data/com.termux/files/usr/tmp:/tmp"
command+=" -b $folder/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    pulseaudio --start \
     --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
     --exit-idle-time=-1;
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "#!/bin/bash
touch ~/.hushlogin
rm -rf ~/.bash_profile
exit" > $folder/root/.bash_profile
clear
termux-fix-shebang $bin
rm -rf $folder/*.tar.*
bash $bin
clear 
#rm -rf ~/wget-proot.sh
echo ""
echo ${R}"If you find problem, try to restart Termux !"
echo ${G}"You can now start your distro with '$ds_name.sh' script next time"
echo ""
