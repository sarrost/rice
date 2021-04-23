#!/bin/sh

# NOTE: All the exporting is for the chroot later.

# TODO fix networking, do I need netifrc?

export REPO_DOTFILES='https://github.com/sarrost/dotfiles'
export REPO_SCRIPTS='https://github.com/sarrost/scripts'
export REPO_KERNEL='https://github.com/sarrost/gentoo-kernel'
export REPO_DWM='https://github.com/sarrost/dwm'
export REPO_ST='https://github.com/sarrost/st'
export REPO_DWMBLOCKS='https://github.com/sarrost/dwmblocks'
export REPO_DMENU='https://github.com/sarrost/dmenu'

# Colors
export clear=$(printf '\033[0m')
export black=$(printf '\033[0;30m')					; export dark_gray=$(printf '\033[1;30m')
export red=$(printf '\033[0;31m')						; export light_red=$(printf '\033[1;31m')
export green=$(printf '\033[0;32m')					; export light_green=$(printf '\033[1;32m')
export orange=$(printf '\033[0;33m')				; export yellow=$(printf '\033[1;33m')
export blue=$(printf '\033[0;34m')					; export light_blue=$(printf '\033[1;34m')
export purple=$(printf '\033[0;35m')				; export light_purple=$(printf '\033[1;35m')
export cyan=$(printf '\033[0;36m')					; export light_cyan=$(printf '\033[1;36m')
export light_gray=$(printf '\033[0;37m')		; export white=$(printf '\033[1;37m')

export emphasis="${light_cyan}"
export prompt_style="${light_blue}"

# Variables
export i1="   "
export header="${cyan}RICE ${blue}=>${clear} "
export warning="${light_red}WARNING ${red}=>${clear} "
export error="${light_red}ERROR ${red}=>${clear} "
export prompt=" ${light_gray}> ${clear}"
export default_yes="${i1}${green}[BLANK]${clear} yes  /  ${red}[N]${clear} no${prompt}"
export default_no="${i1}${red}[BLANK]${clear} no  /  ${green}[Y]${clear} yes${prompt}"
export any_key="${i1}${purple}[ANY KEY]${clear}"

# Error messages.
export err_dotfiles="${error}Cannot locate dotfiles dir, or it's there but the structure is not what is expected."
export err_root="${error}Cannot locate ${emphasis}/root${clear} dir."


# TODO args for stages
if [ -z "$1" ]; then
	printf "%sSpecify a stage.\\n" "$error"
else
	case "$1" in
		1) export stage_1='true';;
		1_9) export stage_1_9='true';;
		1_99) export stage_1_99='true';;
		2) export stage_2='true';;
		2_9) export stage_2_9='true';;
		3) export stage_3='true';;
	esac
fi


#-----------------------------------------------------------
#                         STAGE 1
#-----------------------------------------------------------
if [ -n "$stage_1" ]; then

# TODO format to use one printf
printf "%s\\n" "------------------------------------------------------------"
printf "PERFORMING GENTOO RICE INSTALLATION %sSTAGE 1%s !!!\\n" "${cyan}" "${clear}"
printf "%s\\n" "------------------------------------------------------------"
printf "Hit %s[ANY KEY]%s to proceed OR %s[CTRL-C]%s to exit at any point...\\n" \
	"${purple}" "${clear}" "${light_red}" "${clear}"
read -r

# Check that there is internet
if ping -q -c 1 -W 1 gnu.org >/dev/null; then
	printf "%sLovely, the internet connection is working!\\n" "${header}"
else
	printf "%sCannot connect to the internet. Please insure that the internet is working beforehand, please see the README for more info.\\n" \
		"${error}"
	exit 1
fi

#-----------------------------------------------------------
#	PROMPTS
#-----------------------------------------------------------
# Prompt user to select hostname
while [ -z "$valid_hostname" ]; do
	printf "%sEnter a name for this machine. For example, %sfoobar%s.\\n%s[HOSTNAME] > %s" \
		"${header}" "${emphasis}" "${clear}" "${i1}${prompt_style}" "${clear}"
	read -r chosen_hostname
	if [ -n "$chosen_hostname" ]; then
		printf "%sYou have chosen %s, do you wish to proceed?\\n%s" \
			"${header}" "${emphasis}${chosen_hostname}${clear}" "${default_yes}"
		read -r confirmation
		case "$confirmation" in
			n|N|no|nO|No|NO) printf "%sYou have cancelled the selection.\\n" "${header}" ;;
			*) valid_hostname='true'; export HOSTNAME="$chosen_hostname" ;;
		esac
	fi
done

# Prompt user to select storage device.
while [ -z "$valid_device" ]; do
	printf "%sChoose a storage device to install the OS to. For example, %ssda%s.\\n%sThe drive will be formatted and all content on it will be lost.\\nListing all storage devices:\\n%s\\n%s[DEVICE] > %s" \
		"${header}" "${emphasis}" "${clear}" "${warning}" "$(lsblk -o NAME,SIZE)" "${i1}${prompt_style}" "${clear}"
	read -r chosen_device
	if stat "/dev/$chosen_device" > /dev/null 2>&1; then
		printf "%sYou have chosen %s, type %sYES%s (in full) to proceed.\\n%sChanges made to this device cannot be undone.\\n%s[CONFIRM] > %s" \
			"${header}" "${emphasis}${chosen_device}${clear}" "${green}" "${clear}" "${warning}" "${i1}${prompt_style}" "${clear}"
		read -r confirmation
		case "$confirmation" in
			yes|YES) valid_device='true'; export device=/dev/"$chosen_device" ;;
			*) printf "%sYou have cancelled the selection.\\n" "${header}" ;;
		esac
	else
		printf "%sInvalid device.\\n" "${error}"
	fi
done
# Devices.
export boot_partition="${device}2"
export swap_partition="${device}3"
export rootfs_partition="${device}4"

# Prompt user to select mount point.
while [ -z "$valid_mount_point" ]; do
	printf "%sDo you wish to change the default mount point for the root filesystem from %s/mnt/gentoo%s to something else?\\n%s" \
		"${header}" "${emphasis}" "${clear}" "${default_no}"
	read -r choice
	case "$choice" in
		y|Y|ye|yE|Ye|YE|yes|yeS|yEs|yES|Yes|YeS|YEs|YES) 
			printf "%sPlease enter the full path of the mount point you would like to use. If the directory does not already exist it will be created.\\n%s[MOUNTPOINT] > %s" \
				"${header}" "${i1}${prompt_style}" "${clear}"
			read -r chosen_mount_point
			mkdir -p "$chosen_mount_point"
			valid_mount_point='true'
			;;
		*) valid_mount_point='true'
			export mount_point=/mnt/gentoo ;;
	esac
done
export err_mount_point="${error}Cannot locate ${emphasis}/mnt/gentoo${clear}, the mount point dir."

# Prompt user to determine boot type.
while [ -z "$valid_boot_type" ]; do
	# TODO color
	printf "%sChoose the correct system boot type from the list below. For example %s1%s.\\n %s[1]%s UEFI\\n %s[2]%s BIOS\\n%s[BOOT] > %s" \
		"${header}" "${emphasis}" "${clear}" "${light_blue}" "${clear}" "${light_blue}" "${clear}" "${i1}${prompt_style}" "${clear}"
	read -r choice
	case "$choice" in
		1) export boot_type='uefi'; valid_boot_type='true';;
		2) export boot_type='bios'; valid_boot_type='true';;
	esac
done

# Prompt user to enter manual datetime, and set it.
while [ -z "$valid_datetime" ]; do
	printf "%sEnter current date and time. Format is %sMMDDhhmmYYYY%s, for example %s011523002021%s for '15 January 23:00 2021'\\n%s[DATETIME] > %s" \
		"${header}" "${emphasis}" "${clear}" "${emphasis}" "${clear}" "${i1}${prompt_style}" "${clear}"
	read -r chosen_datetime
	# Manually set system time.
	date "$chosen_datetime"
	printf "%sIs the date and time correct?\\n%s\\n%s" \
		"${header}" "$(date)" "${default_yes}"
	read -r confirmation
	case "$confirmation" in
		n|N|no|nO|No|NO) ;;
		*) valid_datetime='yes' ;;
	esac
done

# Prompt user to select timezone.
while [ -z "$valid_timezone" ]; do
	printf "%sPlease enter your timezone. For example %sAfrica/Johannesburg%s.\\n%s[TIMEZONE] > %s" \
		"${header}" "${emphasis}" "${clear}" "${i1}${prompt_style}" "${clear}"
	read -r chosen_timezone
	# # TODO update check, cannot use zoneinfo
	# if [ -f "/usr/share/zoneinfo/$chosen_timezone" ]; then
		export valid_timezone='true'
		export timezone="$chosen_timezone"
	# else
	# 	printf "${error}Invalid timezone, please see the README for more info if you are confused.\\n"
	# fi
done

# Prompt user to change locale.
valid_locale='false'
while [ "$valid_locale" = 'false' ]; do
	printf "%sDefault locale is %sen_US%s, do you wish to change locale?\\n%s" \
		"${header}" "${emphasis}" "${clear}" "${default_no}"
	read -r choice
	if [ -z "$choice" ]; then
		valid_locale='true'
	else
		# User must enter custom locale info.
		custom_locale='true'; export custom_locale
		# Get first line.
		printf "%sPlease see the README for the required info regarding your desired locale.\\nEnter the first line of your locale code, for example, %sen_US ISO-8859-1%s\\n%s[LOCALE LINE 1] > %s" \
			"${header}" "${emphasis}" "${clear}" "${i1}${prompt_style}" "${clear}"
		read -r locale_1
		if [ -n "$locale_1" ]; then
			grep "$locale_1" /usr/share/i18n/SUPPORTED > /dev/null 2>&1 && 
				valid_locale='true'
		else
			valid_locale='true'
		fi
		# Get second line.
		if [ "$valid_locale" = 'true' ]; then
			valid_locale='false'
			printf "%sEnter the second line (if any) of your locale code, for example, %sen_US.UTF-8 UTF-8%s\\n%s[LOCALE LINE 2] > %s" \
				"${header}" "${emphasis}" "${clear}" "${i1}${prompt_style}" "${clear}"
			read -r locale_2
			if [ -n "$locale_2" ]; then
				grep "$locale_2" /usr/share/i18n/SUPPORTED > /dev/null 2>&1 &&
					valid_locale='true' && export locale_2
			else
				if [ -n "$locale_1" ]; then
					valid_locale='true'
					export locale_1
				else
					printf "%sBoth lines cannot be left blank.\\n" "${error}"
				fi
			fi
		fi
	fi
done

# Prompt user for number of jobs to use to build packages.
while [ -z "$valid_makeopts" ]; do
	threads=$(nproc); export threads
	printf "%sDetected %s total [logical] threads on this machine, would you like to use all of them to compile your packages?\\n%s" \
		"${header}" "${emphasis}${threads}${clear}" "${default_yes}"
	read -r confirmation
	case "$confirmation" in
		n|N|no|nO|No|NO) 
			printf "%sEnter the amount of threads you would like to use instead of the default of %s.\\n%s[THREADS] > %s" \
				"${header}" "${emphasis}${threads}${clear}" "${i1}${prompt_style}" "${clear}"
			read -r custom_threads
			[ "$custom_threads" -le "$threads" ] && 
				valid_makeopts='yes' && export threads=$((threads + 1));;
		*) valid_makeopts='yes' 
			export threads=$((threads + 1));;
	esac
done

# Prompt user to select mirrors.
while [ -z "$valid_mirrors" ]; do
	printf "%sPackages will be downloaded from French mirrors (the packages themselves will still be in your locale/language), do you wish to change the mirrors to something else?\\n%s" \
		"${header}" "${default_no}"
	read -r choice
	case "$choice" in
		y|Y|ye|yE|Ye|YE|yes|yeS|yEs|yES|Yes|YeS|YEs|YES) custom_mirrors='true'
			printf "%sA menu with a list of mirrors will be presented, hit %s[SPACE]%s to toggle which mirrors you wish to use. It is recommended that you select more than one mirror in case one or more are offline.\\n%s" \
				"${header}" "${emphasis}" "${clear}" "${any_key}"
			read -r
			mirrors=$(mirrorselect -i -o); export mirrors
			[ -n "$mirrors" ] && valid_mirrors='true';;
		*) valid_mirrors='true';;
	esac
done


# TODO Prompt user to select kernel dir.
export KERNEL_DIR=msi

# Fetch kernel version.
# TODO proper link variable
KERNEL_VER=$(curl --silent https://raw.githubusercontent.com/sarrost/gentoo-kernel/master/configs/msi/latest.txt); export KERNEL_VER

# Prompt user to select kernel version.
# TODO register proper choice
while [ -z "$valid_kernel" ]; do
	printf "%sDo you wish to change the kernel version from %s?\\n%s" \
		"${header}" "${emphasis}${KERNEL_VER}${clear}" "${default_no}"
	read -r choice
	case "$choice" in
		y|Y|ye|yE|Ye|YE|yes|yeS|yEs|yES|Yes|YeS|YEs|YES) 
			printf "%sPlease enter the kernel version you would like to use, for example, %s.\\n%sThe version number will not be checked for validity, so please ensure you have entered it correctly.\\n%s[KERNEL]%s" \
				"${header}" "${emphasis}${KERNEL_VER}${clear}" "${warning}" "${i1}${prompt_style}" "${prompt}"
			read -r chosen_kernel_version
			printf "%sYou have chosen %s as your kernel version, is this correct?\\n%s" \
				"${header}" "${emphasis}${chosen_kernel_version}${clear}" "${default_yes}"
			read -r confirmation
			case "$confirmation" in
				n|N|no|nO|No|NO) 
					printf "%sYou have cancelled the selection.\\n" "${header}" ;;
				*) valid_kernel='true'
					export KERNEL_VER="$chosen_kernel_version" ;;
			esac ;;
		*) valid_kernel='true';;
	esac
done

#-----------------------------------------------------------
#	LIVEUSB
#-----------------------------------------------------------
printf "%sFormatting storage device and creating partitions. This will take some time as the storage medium is being overwritten with random data for a secure-ish wipe.\\n" "${header}"
# TODO: re-enable when stable 1.9 is reached.
## Erase disk
#dd if=/dev/urandom of="$device" bs=1M > /dev/null 2>&1
# Create new partitions
parted --align optimal "$device" --script "\
mklabel gpt \
unit mib \
mkpart primary 1 3 \
name 1 \
grub set 1 \
bios_grub on \
mkpart primary 3 131 \
name 2 boot \
mkpart primary 131 643 \
name 3 swap  \
mkpart primary 643 -1 \
name 4 rootfs \
set 2 boot on \
"

printf "%sFormatting root filesystem.\\n" "${header}"
mkfs.ext4 -q "$rootfs_partition"

printf "%sActivate swap partition.\\n" "${header}"
mkswap "$swap_partition" >/dev/null
swapon "$swap_partition" >/dev/null

printf "%sMounting root filesystem.\\n" "${header}"
mount "$rootfs_partition" "$mount_point"
cd "$mount_point" || ( printf "%s\\n" "${err_mount_point}"; exit 1 )

# TODO??? hwclock --localtime
# I'm not sure how to sync system time to hwclock.

printf "%sDownloading stage-3 tarball.\\n" "${header}"
STAGE3_VER=$(curl -s 'https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt' | grep .tar.)
STAGE3_VER="${STAGE3_VER%%/*}"
wget -q --show-progress -O stage3.tar.xz "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/current-stage3-amd64-nomultilib/stage3-amd64-nomultilib-${STAGE3_VER}.tar.xz"

printf "%sUnpacking stage-3 tarball.\\n" "${header}"
tar xpf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

printf "%sModifying default make.conf.\\n" "${header}"
# Update optimization flags for package compilation.
sed -i "s/COMMON_FLAGS=\".\+\"/COMMON_FLAGS=\"-march=native -O2 -pipe\"/g" "$mount_point"/etc/portage/make.conf
# Update amount of jobs to use when emerging packages.
printf "\\nMAKEOPTS=\"-j%s\"" "${threads}" >> "$mount_point"/etc/portage/make.conf

printf "%sSelect mirrors to use.\\n" "${header}"
if [ -z "$custom_mirrors" ]; then
	printf "\\nGENTOO_MIRRORS=\"ftp://ftp.free.fr/mirrors/ftp.gentoo.org/ http://ftp.free.fr/mirrors/ftp.gentoo.org/ http://gentoo.modulix.net/gentoo/ http://gentoo.mirrors.ovh.net/gentoo-distfiles/ https://mirrors.soeasyto.com/distfiles.gentoo.org/ http://mirrors.soeasyto.com/distfiles.gentoo.org/ ftp://mirrors.soeasyto.com/distfiles.gentoo.org/\"\\n" >> "$mount_point"/etc/portage/make.conf
else
	printf "\\n%s\\n" "$mirrors" >> "$mount_point"/etc/portage/make.conf
fi

printf "%sConfiguring ebuild repository.\\n" "${header}"
mkdir --parents "$mount_point"/etc/portage/repos.conf
cp "$mount_point"/usr/share/portage/config/repos.conf "$mount_point"/etc/portage/repos.conf/gentoo.conf
# TODO custom gentoo repo

printf "%sCopying DNS info.\\n" "${header}"
cp --dereference /etc/resolv.conf "$mount_point"/etc/

printf "%sMounting the necessary filesystems.\\n" "${header}"
mount --types proc /proc "$mount_point"/proc
mount --rbind /sys "$mount_point"/sys
mount --make-rslave "$mount_point"/sys
mount --rbind /dev "$mount_point"/dev
mount --make-rslave "$mount_point"/dev 

#-----------------------------------------------------------
#	CHROOT
#-----------------------------------------------------------
printf "%sChanging root to %s.\\n" "${header}" "${emphasis}${mount_point}${clear}"
# NOTE: comment out this line when editing to restore syntax
#       highlighting if broken.
chroot "$mount_point" /bin/bash << "EOT"

printf "%sInstalling ebuild repo snapshot from web.\\n" "${header}"
emerge --sync --quiet > /dev/null 2>&1
printf "%sUpdating package manager.\\n" "${header}"
emerge --oneshot --quiet sys-apps/portage
printf "%sInstalling git and stow.\\n" "${header}"
emerge --quiet dev-vcs/git app-admin/stow
printf "%sInstalling dosfstools.\\n" "${header}" # dosfstools is needed for vfat.
emerge --quiet sys-fs/dosfstools

# Properly format boot partition.
mkfs.vfat -F 32 "$boot_partition" >/dev/null
# Mount boot partition
mount "$boot_partition" /boot	

# Fetch dotfiles and scripts
cd /root ||
	( printf "%s\\n" "${err_root}"; exit 1 )
printf "%sCloning dotfiles repository.\\n" "${header}"
git clone "$REPO_DOTFILES" --depth 1
printf "%sCloning scripts repository.\\n" "${header}"
git clone "$REPO_SCRIPTS" --depth 1
printf "%sCloning kernel configuration repository.\\n" "${header}"
git clone "$REPO_KERNEL" --depth 1

printf "%sDeploying portage configurations.\\n" "${header}"
cd /root/dotfiles/dotfiles/ ||
	( printf "%s\\n" "${err_dotfiles}"; exit 1 )
# TODO remove old files beforehand, update makeopts
./dot.sh sys-portage

# Re:update amount of jobs to use.
sed -i "s/MAKEOPTS=\"-j[[:digit:]]\+\"/MAKEOPTS=\"-j${threads}\"/g" /etc/portage/make.conf

printf "%sInstalling tree.\\n" "${header}"
emerge --quiet app-text/tree

printf "%sInstalling vim.\\n" "${header}"
emerge --quiet app-editors/vim

printf "%sInstalling eix.\\n" "${header}"
emerge --quiet app-portage/eix

printf "%sUpdating entire system.\\n" "${header}"
emerge --verbose --update --deep --newuse --ask --quiet @world

printf "%sSetting timezone.\\n" "${header}"
echo "$timezone" > /etc/timezone
emerge --config sys-libs/timezone-data

printf "%sSetting locale.\\n" "${header}"
if [ -z "$custom_locale" ]; then
	printf "en_US ISO-8859-1\\nen_US.UTF-8 UTF-8" > /etc/locale.gen
else
	printf "%s\\n%s" "${locale_1}" "${locale_2}" > /etc/locale.gen
fi
locale-gen
if [ -z "$custom_locale" ]; then
	printf "LANG=\"en_US.UTF-8\"\\nLC_COLLATE=\"C\"" > /etc/env.d/02locale
else
	locale=$(grep UTF /etc/locale.gen )
	locale="${locale% *}"
	printf "%s\\nLC_COLLATE=\"C\"" "${locale}" > /etc/env.d/02locale
fi
env-update && . /etc/profile

printf "%sInstalling kernel.\\n" "${header}"
emerge --quiet "=sys-kernel/gentoo-sources-${KERNEL_VER}"

# Fetch custom kernel config.
printf "%sFetching kernel config.\\n" "${header}"
cd /usr/src/linux-"${KERNEL_VER}"-gentoo || 
	( printf "%sCannot locate kernel src dir in ${emphasis}/usr/src/${clear}.\\n" "${error}"; exit 1 )
cp /root/gentoo-kernel/configs/"${KERNEL_DIR}"/"${KERNEL_VER}"/config .config

# Build and install kernel.
printf "%sBuilding kernel.\\n" "${header}"
make && make modules
make install && make modules_install

## Fetch modules
cd /root/dotfiles/dotfiles/ || 
	( printf "%s\\n" "${err_dotfiles}"; exit 1 )
./dot.sh sys-kernel
## get `/etc/modules-load.d `

printf "%sEmerging linux-firmware.\\n" "${header}"
emerge --quiet sys-kernel/linux-firmware

printf "%sConfiguring fstab.\\n" "${header}"
printf "%s	/boot	vfat	defaults,noatime	0	2
%s	none	swap	sw	0	0
%s	/	ext4	noatime	0	1" \
"${boot_partition}" "${swap_partition}" "${rootfs_partition}" >> /etc/fstab

printf "%sSetting hostname.\\n" "${header}"
printf "hostname=\"%s\"\\n" "${HOSTNAME}" > /etc/conf.d/hostname

# Configure networking.
printf "%sEmerging NetworkManager.\\n" "${header}"
emerge net-misc/networkmanager

# Set root password.
printf "%sSetting root password.\\nYou will presented with a prompt to enter a password for the root user. Hit %s to continue\\n%s" "${header}" "${any_key}" "${any_key}"
read -r
passwd

# Install system logger.
printf "%sEmerging system logger.\\n" "${header}"
emerge --quiet app-admin/sysklogd
rc-update add sysklogd default

# Install grub2.
printf "%sEmerging grub2.\\n" "${header}"
emerge --verbose --quiet sys-boot/grub:2

# TODO stage 1 must end here, re-chroot
#-----------------------------------------------------------
#                         STAGE 1.9
#-----------------------------------------------------------
if [ -n "$stage_1_9" ]; then
	printf "%sRunning grub-install command.\\n" "${header}"
	# Run grub-install command for UEFI.
	if [ "$boot_type" = 'uefi' ]; then
		# TODO need to test this. 
		grub-install --target=x86_64-efi --efi-directory=/boot
	else # For BIOS.
		grub-install "$device"
	fi

	printf "%sConfiguring grub2.\\n" "${header}"
	# Create grub config.
	grub-mkconfig -o /boot/grub/grub.cfg
fi
##-----------------------------------------------------------
##                         STAGE 1.99
##-----------------------------------------------------------
#if [ -n "$stage_1_99" ]; then
#	# TODO stop here and ask to confirm that all is well
#
#	# Reboot and remove liveusb
#	printf "%sLeaving chroot environment.\\n" "${header}"
#	exit
#	printf "%sUnmounting storage devices.\\n" "${header}"
#	umount -l "$mount_point"/dev/shm
#	umount -l "$mount_point"/dev/pts
#	umount -l "$mount_point"/dev
#	umount -R "$mount_point"
#
#	printf "%sSTAGE 1 installation complete!.. Hopefully! You will have to shutdown the machine, then eject the liveusb, then starup the machine again. Run 'halt' to shutdown the machine.\\n" "${header}"
#fi
#EOT
#fi
##-----------------------------------------------------------
##                         STAGE 2
##-----------------------------------------------------------
#if [ -n "$stage_2" ]; then
#
#downloads_dir=/root
#st_ver=0.8.4
#dwm_ver=6.2
#url_st="http://dl.suckless.org/st/st-${st_ver}.tar.gz"
#url_dwm="http://dl.suckless.org/dwm/dwm-${dwm_ver}.tar.gz"
#test_script=/root/test.sh
#
#printf "%sOrganizing downloads.\\n" "${header}"
#mkdir -p "${downloads_dir}"
#mv stage3.tar.xz "${downloads_dir}"
#
#printf "%sDownloading xorg. This will take a long time.\\n" "${header}"
#emerge --quiet x11-base/xorg-server 
#
#printf "%sDownloading twm and xterm for testing X.\\n" "${header}"
#emerge --quiet x11-wm/twm x11-terms/xterm
#
#printf "%sCreating test script.\\n" "${header}"
#cd /root
#printf "#!/bin/sh\\nstartx; sleep 7; pkill x" > "${test_script}"
#chmod +x "${test_script}"
#
#fi
##-----------------------------------------------------------
##                         STAGE 2.9
##-----------------------------------------------------------
#if [ -n "$stage_2_9" ]; then
#
#s="${header}Run ${emphasis}rice.sh 2.9${clear} to show this message again.\\n\\n"
#s="${s} Test that X is working by running ${emphasis}./root/test.sh${clear}."
#s="${s} This will start ${emphasis}twm${clear} and a few ${emphasis}xterm${clear} terminal windows,"
#s="${s} which will last ${emphasis}7 seconds${clear} before closing itself and returning here (the tty)."
#s="${s} Ideally you have a mouse/trackpad available and can move it around"
#s="${s} during the test period to additionally test the mouse/trackpad is"
#s="${s} functional in X.\\n\\nIf twm does indeed appear with the xterm terminal"
#s="${s} windows (and if you have a mouse/trackpad can move around the cursor)"
#s="${s} then X is working as expected. You can move on to stage 3. If the"
#s="${s} screen is black/off for the 7 seconds then it means xorg is not"
#s="${s} configured correctly. Inspect TODO log file and conf files.\\n"
#printf "%s" "$s"
#
#fi
##-----------------------------------------------------------
##                         STAGE 3
##-----------------------------------------------------------
#if [ -z "$stage_3" ]; then
#	
#printf "%sInstalling necessary packages to get to working wm.\\n" "${header}"
#emerge --quiet app-admin/doas app-shells/zsh
#
#printf "%sConfiguring doas.\\n" "${header}"
#printf "permit :wheel" > /etc/doas.conf
## TODO custom doas conf later.
#
## TODO make p10k ebuild and install it
#
## TODO create user home dir.
#sed startx .profile > /tmp/tmp-profile
#. /tmp/tmp-profile
#mkdir -p \
#	"$XDG_CACHE_HOME" \
#	"$XDG_CONFIG_HOME" \
#	"$XDG_DATA_HOME" \
#	"$XDG_DOWNLOAD_DIR"
#
## TODO install dotfiles for user
## TODO deploy x11 dotfiles
#
## TODO install here
#printf "%sInstalling dwm.\\n" "${header}"
#printf "%sInstalling dwmblocks.\\n" "${header}"
#printf "%sInstalling dmenu.\\n" "${header}"
#printf "%sInstalling st.\\n" "${header}"
#
#printf "%sPicking shell for new user.\\n" "${header}"
## TODO prompts for shell
## here
#
## TODO prompt
#printf "%sCreating new user.\\n" "${header}"
#useradd -m -s "$shell" \
#	-G users,wheel,audio "$username"
#passwd "$username"
#
#printf "%sCopying rice.sh to new user's home dir.\\n" "${header}"
#cp /root/rice.sh /home/"$username"/
#
##-----------------------------------------------------------
##                       STAGE 3.9
##-----------------------------------------------------------
#
#s="${header}Run ${emphasis}rice.sh 3.9${clear} to show this message again.\\n\\n"
#s="${s}Minimal install of desktop environment is now complete. Logout by running ${emphasis}exit${clear} and login as your newly created user. Once logged Run ${emphasis}doas ./rice.sh 4${clear} to "
#printf "%s" "$s"
#
#fi
##-----------------------------------------------------------
##                       STAGE 4
##-----------------------------------------------------------
#if [ -z "$stage_3_1" ]; then
#
## - install zsh
## 	- zsh-completions, gentoo-zsh-completions
#
## - install fonts (Inconsolata, Source Code Pro, Bitstream Vera Sans, Noto Sans CJK, Noto Sans)
##  Glacial Indifference, Quicksand, Metropolis, Roboto, Caviar Dreams, Cantarell
#
## - install
## 	https://github.com/uditkarode/libxft-bgra
## - install ueberzug through pip (for both root and user)
## - install fontpreview-ueberzug
## - install mutt-wizard
## - install linux-firmware, need to update package.mask and reboot
## - install vim-plug
## 	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
##        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
#
## TODO setup python
#
## TODO setup gnupg
## # TODO mkdir
## # chmod 600 ~/.gnupg/*
## # chmod 700 ~/.gnupg
## # export GNUPGHOME="$XDG_DATA_HOME/gnupg"
#fi
#
#	# "$XDG_DESKTOP_DIR"
#	# "$XDG_DOCUMENTS_DIR"
#	# "$XDG_MUSIC_DIR"
#	# "$XDG_PICTURES_DIR"
#	# "$XDG_PUBLICSHARE_DIR"
#	# "$XDG_TEMPLATES_DIR"
#	# "$XDG_VIDEOS_DIR"
#	# "$RICE_ANIME_DIR"
#	# "$RICE_ARTICLES_DIR"
#	# "$RICE_AUDIO_DIR"
#	# "$RICE_CODE_DIR"
#	# "$RICE_DOTFILES_DIR"
#	# "$RICE_GAMES_DIR"
#	# "$RICE_LIBRARY_DIR"
#	# "$RICE_MEDIA_DIR"
#	# "$RICE_MOVIE_DIR"
#	# "$RICE_NOTES_DIR"
#	# "$RICE_NOTES_FILE"
#	# "$RICE_REPO_DIR"
#	# "$RICE_SCRIPTS_DIR"
#	# "$RICE_SCREENSHOT_DIR"
#	# "$RICE_TV_DIR"
#	# "$RICE_WALLPAPER_DIR"
#	# "$RICE_WORK_DIR"
#	# "$RICE_WORLD_REPO_DIR"
#	# "$GNUPGHOME"
#
## mkdir .config/task
