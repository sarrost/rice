#!/bin/sh

# TODO args for stages
STAGE_1='true'
STAGE_1_9='true'

REPO_DOTFILES='https://github.com/sarrost/dotfiles'
REPO_SCRIPTS='https://github.com/sarrost/scripts'
REPO_KERNEL='https://github.com/sarrost/gentoo-kernel'

# Colors
clear='\033[0m'
black='\033[0;30m'				; dark_gray='\033[1;30m'
red='\033[0;31m'					; light_red='\033[1;31m'
green='\033[0;32m'				; light_green='\033[1;32m'
orange='\033[0;33m'				; yellow='\033[1;33m'
blue='\033[0;34m'					; light_blue='\033[1;34m'
purple='\033[0;35m'				; light_purple='\033[1;35m'
cyan='\033[0;36m'					; light_cyan='\033[1;36m'
light_gray='\033[0;37m'		; white='\033[1;37m'

# Variables
header="${cyan}RICE ${blue}=>${clear} "
warning="${light_red}WARNING ${red}=>${clear} "
error="${light_red}ERROR ${red}=>${clear} "
prompt=" ${gray}> ${clear}"
default_yes="${green}[BLANK]${clear} yes  /  ${light_red}[N]${clear} no${prompt}"
default_no="${light_blue}[BLANK]${clear} no  /  ${light_green}[Y]${clear} yes${prompt}"
any_key="${purple}[ANY KEY]${clear}"
# TODO vars for y/n/blanks

yes_pattern='y/Y/ye/yE/Ye/YE/yes/yeS/yEs/yES/Yes/YeS/YEs/YES'
no_pattern='n/N/no/nO/No/NO'
shopt -s extglob

# stage 1
printf "%s\\n" "------------------------------------------------------------"
printf "PERFORMING GENTOO RICE INSTALLATION ${cyan}STAGE 1${clear} !!!\\n"
printf "%s\\n" "------------------------------------------------------------"
printf "Hit ${purple}[ANY KEY]${clear} to proceed OR ${light_red}[CTRL-C]${clear} to exit at any point...\\n"
read dummy

# Check that there is internet
if ping -q -c 1 -W 1 gnu.org >/dev/null; then
	printf "${header}Lovely, the internet connection is working!\\n"
else
	printf "${error}Cannot connect to the internet. Please insure that the internet is working beforehand, please see the README for more info.\\n"
	exit 1
fi

#-----------------------------------------------------------
#                         STAGE 1
#-----------------------------------------------------------
[ -z "$STAGE_1" ] && exit

#-----------------------------------------------------------
#	PROMPTS
#-----------------------------------------------------------
# Prompt user to select hostname
while [ -z "$valid_hostname" ]; do
	printf "${header}Enter a name for this machine. For example, ${light_blue}foobar${clear}.\\n${light_blue}[HOSTNAME] > ${clear}"
	read chosen_hostname
	if [ ! -z "$chosen_hostname" ]; then
		printf "${header}You have chosen '$chosen_hostname', do you wish to proceed?\\n${default_yes}"
		read confirmation
		case "$confirmation" in
			@("$no_pattern")) printf "${header}You have cancelled the selection.\\n" ;;
			*) valid_hostname='true'
				HOSTNAME="$chosen_hostname" ;;
		esac
	fi
done

# Prompt user to select storage device.
while [ -z "$valid_device" ]; do
	printf "${header}Choose a storage device to install the OS to. For example, 'sda' (without the quotes).\\n${warning}The drive will be formatted and all content on it will be lost.\\nListing all storage devices:\\n"
	lsblk -o NAME,SIZE
	printf "${light_blue}[DEVICE] > ${clear}"
	read chosen_device
	stat "/dev/$chosen_device" > /dev/null 2>&1
	if [ "$?" = 0 ]; then
		printf "${header}You have chosen ${light_blue}${chosen_device}${clear}, type ${light_blue}YES${clear} (in full) to proceed.\\n${warning}Changes made to this device cannot be undone.\\n${light_blue}[CONFIRM] > ${clear}"
		read confirmation
		case "$confirmation" in
			yes|YES) valid_device='true'
				device=/dev/"$chosen_device" ;;
			*) printf "${header}You have cancelled the selection.\\n" ;;
		esac
	else
		printf "${error}Invalid device.\\n"
	fi
done
# Devices.
RICE_BOOT_PART="${device}2"
RICE_SWAP_PART="${device}3"
RICE_ROOTFS_PART="${device}4"

# Prompt user to select mount point.
while [ -z "$valid_mount_point" ]; do
	printf "${header}Do you wish to change the default mount point for the root filesystem from ${light_blue}/mnt/gentoo${clear} to something else?\\n${default_no}"
	read choice
	case "$choice" in
		@("$yes_pattern")) printf "${header}Please enter the full path of the mount point you would like to use. If the directory does not already exist it will be created.\\n${light_blue}[MOUNTPOINT] > ${clear}"
			read chosen_mount_point
			mkdir -p "$chosen_mount_point"
			[ "$?" = 0 ] && valid_mount_point='true'
			;;
		*) valid_mount_point='true'
			RICE_MOUNT_POINT=/mnt/gentoo ;;
	esac
done


# Prompt user to determine boot type.
while [ -z "$valid_boot_type" ]; do
	# TODO color
	printf "${header}Choose the correct system boot type from the list below. For example ${light_blue}1${clear}.\\n[1] UEFI\\n[2] BIOS\\n[BOOT] > "
	read choice
	case "$choice" in
		1) boot_type='uefi'; valid_boot_type='true';;
		2) boot_type='bios'; valid_boot_type='true';;
	esac
done

# Prompt user to enter manual datetime, and set it.
while [ -z "$valid_datetime" ]; do
	printf "${header}Enter current date and time. Format is ${light_blue}MMDDhhmmYYYY${clear}, for example ${light_blue}011523002021${clear} for '23:00, 15 January 2021'\\n${light_blue}[DATETIME] > ${clear}"
	read chosen_datetime
	# Manually set system time.
	date "$chosen_datetime"
	printf "${header}Is the date and time correct?\\n"
	date
	printf "${default_yes}"
	read confirmation
	case "$confirmation" in
		@("$no_pattern")) ;;
		*) valid_datetime='yes' ;;
	esac
done

# Prompt user to select timezone.
while [ -z "$valid_timezone" ]; do
	printf "${header}Please enter your timezone. For example ${light_blue}Africa/Johannesburg${clear}.\\n${light_blue}[TIMEZONE] > ${clear}"
	read chosen_timezone
	# # TODO update check, cannot use zoneinfo
	# if [ -f "/usr/share/zoneinfo/$chosen_timezone" ]; then
		valid_timezone='true'
		RICE_TIMEZONE="$chosen_timezone"
	# else
	# 	printf "${error}Invalid timezone, please see the README for more info if you are confused.\\n"
	# fi
done

# Prompt user to change locale.
valid_locale='false'
while [ "$valid_locale" = 'false' ]; do
	printf "${header}Default locale is ${light_blue}en_US${clear}, do you wish to change locale?\\n${default_no}"
	read choice
	if [ -z "$choice" ]; then
		valid_locale='true'
	else
		# User must enter custom locale info.
		custom_locale='true'
		# Get first line.
		printf "${header}Please see the README for the required info regarding your desired locale.\\nEnter the first line of your locale code, for example, ${light_blue}en_US ISO-8859-1${clear}\\n${light_blue}[LOCALE LINE 1] > ${clear}"
		read locale_1
		if [ ! -z "$locale_1" ]; then
			cat /usr/share/i18n/SUPPORTED | grep "$locale_1" > /dev/null 2>&1
			[ "$?" = 0 ] && valid_locale='true'
		else
			valid_locale='true'
		fi
		# Get second line.
		if [ "$valid_locale" = 'true' ]; then
			valid_locale='false'
			printf "${header}Enter the second line (if any) of your locale code, for example, ${light_blue}en_US.UTF-8 UTF-8${clear}\\n${light_blue}[LOCALE LINE 2] > ${clear}"
			read locale_2
			if [ ! -z "$locale_2" ]; then
				cat /usr/share/i18n/SUPPORTED | grep "$locale_2" > /dev/null 2>&1
				[ "$?" = 0 ] && valid_locale='true'
			else
				if [ ! -z "$locale_1" ]; then
					valid_locale='true'
				else
					printf "${error}Both lines cannot be left blank.\\n"
				fi
			fi
		fi
	fi
done

# Prompt user for number of jobs to use to build packages.
while [ -z "$valid_makeopts" ]; do
	threads=$(nproc)
	printf "${header}Detected ${light_blue}${threads}${clear} total [logical] threads on this machine, would you like to use all of them to compile your packages?\\n${default_yes}"
	read confirmation
	case "$confirmation" in
		@("$no_pattern")) printf "${header}Enter the amount of threads you would like to use instead of the default of ${light_blue}${threads}${clear}.\\n${light_blue}[THREADS] > ${clear}" 
			read custom_threads
			[ "$custom_threads" -le "$threads" ] && 
				valid_makeopts='yes' && threads=$((threads + 1));;
		*) valid_makeopts='yes' 
			threads=$((threads + 1));;
	esac
done

# Prompt user to select mirrors.
while [ -z "$valid_mirrors" ]; do
	printf "${header}Packages will be downloaded from French mirrors (the packages themselves will still be in your locale/language), do you wish to change the mirrors to something else?\\n${default_no}"
	read choice
	case "$choice" in
		@("$yes_pattern")) custom_mirrors='true'
			printf "${header}A menu with a list of mirrors will be presented, hit ${light_blue}[SPACE]${clear} to toggle which mirrors you wish to use. It is recommended that you select more than one mirror in case one or more are offline.\\n${any_key}"
			read dummy
			mirrors=$(mirrorselect -i -o)
			[ -z "$mirrors" ] || valid_mirrors='true';;
		*) valid_mirrors='true';;
	esac
done


# TODO Prompt user to select kernel dir.
KERNEL_DIR=msi

# Fetch kernel version.
# TODO proper link variable
KERNEL_VER=$(curl --silent https://raw.githubusercontent.com/sarrost/gentoo-kernel/master/configs/msi/latest.txt)

# Prompt user to select kernel version.
# TODO register proper choice
while [ -z "$valid_kernel" ]; do
	printf "${header}Do you wish to change the kernel version from ${light_blue}${KERNEL_VER}${clear}?\\n${default_no}"
	read choice
	case "$choice" in
		*) valid_kernel='true';;
		@("$yes_pattern")) printf "${header}Please enter the kernel version you would like to use, for example, ${light_blue}${KERNEL_VER}${clear}.\\n${warning}The version number will not be checked for validity, so please ensure you have entered it correctly.\\n${light_blue}[KERNEL]${prompt}"
			read chosen_kernel_version
			printf "${header}You have chosen ${light_blue}${chosen_kernel_version}${clear} as your kernel version, is this correct?\\n${default_yes}"
			read confirmation
			case "$confirmation" in
				@("$no_pattern")) printf "${header}You have cancelled the selection.\\n" ;;
				*) valid_kernel='true'
					KERNEL_VER="$chosen_kernel_version" ;;
			esac
	esac
done

#-----------------------------------------------------------
#	LIVEUSB
#-----------------------------------------------------------
printf "${header}Formatting storage device and creating partitions.\\n"
# Erase disk
dd if=/dev/urandom of="$device" bs=1M 
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

printf "${header}Formatting root filesystem.\\n"
mkfs.ext4 -q "$RICE_ROOTFS_PART"

printf "${header}Activate swap partition."
mkswap "$RICE_SWAP_PART"
swapon "$RICE_SWAP_PART"

printf "${header}Mounting root filesystem.\\n"
mount "$RICE_ROOTFS_PART" "$RICE_MOUNT_POINT"
cd "$RICE_MOUNT_POINT"

# TODO??? hwclock --localtime
# I'm not sure how to sync system time to hwclock.

printf "${header}Downloading stage-3 tarball.\\n"
STAGE3_VER=$(curl -s 'https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-nomultilib.txt' | grep .tar.)
STAGE3_VER="${STAGE3_VER%%/*}"
wget -q --show-progress -O stage3.tar.xz "https://mirror.bytemark.co.uk/gentoo/releases/amd64/autobuilds/current-stage3-amd64-nomultilib/stage3-amd64-nomultilib-${STAGE3_VER}.tar.xz"

printf "${header}Unpacking stage-3 tarball.\\n"
tar xpf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

printf "${header}Modifying default make.conf.\\n"
# Update optimization flags for package compilation.
sed -i "s/COMMON_FLAGS=\".\+\"/COMMON_FLAGS=\"-march=native -O2 -pipe\"/g" "$RICE_MOUNT_POINT"/etc/portage/make.conf
# Update amount of jobs to use when emerging packages.
printf "\\nMAKEOPTS=\"-j${threads}\"" >> "$RICE_MOUNT_POINT"/etc/portage/make.conf

printf "${header}Select mirrors to use.\\n"
if [ -z "$custom_mirrors" ]; then
	printf "\\nGENTOO_MIRRORS=\"ftp://ftp.free.fr/mirrors/ftp.gentoo.org/ http://ftp.free.fr/mirrors/ftp.gentoo.org/ http://gentoo.modulix.net/gentoo/ http://gentoo.mirrors.ovh.net/gentoo-distfiles/ https://mirrors.soeasyto.com/distfiles.gentoo.org/ http://mirrors.soeasyto.com/distfiles.gentoo.org/ ftp://mirrors.soeasyto.com/distfiles.gentoo.org/\"\\n" >> "$RICE_MOUNT_POINT"/etc/portage/make.conf
else
	printf "\\n$mirrors\\n" >> "$RICE_MOUNT_POINT"/etc/portage/make.conf
fi

printf "${header}Configuring ebuild repository.\\n"
mkdir --parents "$RICE_MOUNT_POINT"/etc/portage/repos.conf
cp "$RICE_MOUNT_POINT"/usr/share/portage/config/repos.conf "$RICE_MOUNT_POINT"/etc/portage/repos.conf/gentoo.conf
# TODO custom gentoo repo

printf "${header}Copying DNS info.\\n"
cp --dereference /etc/resolv.conf "$RICE_MOUNT_POINT"/etc/

printf "${header}Mounting the necessary filesystems.\\n"
mount --types proc /proc "$RICE_MOUNT_POINT"/proc
mount --rbind /sys "$RICE_MOUNT_POINT"/sys
mount --make-rslave "$RICE_MOUNT_POINT"/sys
mount --rbind /dev "$RICE_MOUNT_POINT"/dev
mount --make-rslave "$RICE_MOUNT_POINT"/dev 

#-----------------------------------------------------------
#	CHROOT
#-----------------------------------------------------------
# Chroot in.
# NOTE: comment out this line when editing to restore syntax
#       highlighting if broken.
chroot "$RICE_MOUNT_POINT" /bin/bash << "EOT"

printf "${header}Installing ebuild repo snapshot from web.\\n"
emerge --sync --quiet
printf "${header}Updating package manager.\\n"
emerge --oneshot --quiet sys-apps/portage
printf "${header}Installing git.\\n"
emerge --quiet dev-vcs/git
printf "${header}Installing dosfstools.\\n" # dosfstools is needed for vfat.
emerge --quiet dosfstools

# Properly format boot partition.
mkfs.vfat -q -F 32 "$RICE_BOOT_PART"
# Mount boot partition
mount "$RICE_BOOT_PART" /boot	

# Fetch dotfiles and scripts
cd /root
printf "${header}Cloning dotfiles repository.\\n"
git clone "$REPO_DOTFILES" --depth 1
printf "${header}Cloning scripts repository.\\n"
git clone "$REPO_SCRIPTS" --depth 1
printf "${header}Cloning kernel configuration repository.\\n"
git clone "$REPO_KERNEL" --depth 1

printf "${header}Deploying portage configurations.\\n"
cd /root/dotfiles/dotfiles/
./dot.sh sys-portage

# Re:update amount of jobs to use.
sed -i "s/MAKEOPTS=\"-j[[:digit:]]\+\"/MAKEOPTS=\"-j${cores}\"/g" /etc/portage/make.conf

# Install vim to make life easier.
emerge --quiet vim
# Update entire system.
emerge --verbose --update --deep --newuse --ask --quiet @world

# Set timezone.
echo "$RICE_TIMEZONE" > /etc/timezone
emerge --config sys-libs/timezone-data

# Set locale
if [ -z "$custom_locale" ]; then
	printf "en_US ISO-8859-1\\nen_US.UTF-8 UTF-8" /etc/locale.gen
else
	printf "locale_1\\nlocale_2" > /etc/locale.gen
fi
locale-gen
if [ -z "$custom_locale" ]; then
	printf "LANG=\"en_US.UTF-8\"\\nLC_COLLATE=\"C\"" /etc/env.d/02locale
else
	locale=$(cat /etc/locale.gen | grep UTF)
	locale="${locale% *}"
	printf "$locale\\nLC_COLLATE=\"C\"" > /etc/env.d/02locale
fi
env-update && source /etc/profile

# Install kernel package.
emerge --quiet "=sys-kernel/gentoo-sources-${KERNEL_VER}"

# Fetch custom kernel config.
cd /usr/src/linux-"${KERNEL_VER}"-gentoo
cp /root/gentoo-kernel/configs/"${KERNEL_DIR}"/"${KERNEL_VER}"/config .config

# Build and install kernel.
make && make modules
make install && make modules_install

## Fetch modules
cd /root/dotfiles/dotfiles/
./dot.sh sys-kernel
## get `/etc/modules-load.d `

printf "${header}Emerging linux-firmware.\\n"
emerge --quiet sys-kernel/linux-firmware

printf "${header}Configuring fstab.\\n"
printf "${RICE_BOOT_PART}	/boot	vfat	defaults,noatime	0	2
${RICE_SWAP_PART}	none	swap	sw	0	0
${RICE_ROOTFS_PART}	/	ext4	noatime	0	1" >> /etc/fstab

printf "${header}Setting hostname.\\n"
printf "hostname=\"${HOSTNAME}\"\\n" > /etc/conf.d/hostname

# Configure networking.
printf "${header}Emerging NetworkManager.\\n"
emerge net-misc/networkmanager

# Set root password.
printf "${header}Setting root password.\\n"
printf "You will presented with a prompt to enter a password for the root user. Hit [ANY KEY] to continue\\n[ANY KEY]"
read dummy
passwd

# Install system logger.
printf "${header}Emerging system logger.\\n"
emerge --quiet app-admin/sysklogd
rc-update add sysklogd default

# Install grub2.
printf "${header}Emerging grub2.\\n"
emerge --verbose --quiet sys-boot/grub:2

#-----------------------------------------------------------
#                         STAGE 1.9
#-----------------------------------------------------------
[ -z "$STAGE_1_9" ] && exit

printf "${header}Running grub-install command.\\n"
# Run grub-install command for UEFI.
if [ "$boot_type" = 'uefi' ]; then
	# TODO need to test this. 
	grub-install --target=x86_64-efi --efi-directory=/boot
else # For BIOS.
	grub-install "$device"
fi

printf "${header}Configuring grub2.\\n"
# Create grub config.
grub-mkconfig -o /boot/grub/grub.cfg

#-----------------------------------------------------------
#                         STAGE 1.99
#-----------------------------------------------------------
[ -z "$STAGE_1_99" ] && exit
# TODO stop here and ask to confirm that all is well

# Reboot and remove liveusb
printf "${header}Leaving chroot environment.\\n"
exit
printf "${header}Unmounting storage devices.\\n"
umount -l "$RICE_MOUNT_POINT"/dev{/shm,/pts,}
umount -R "$RICE_MOUNT_POINT"

printf "${header}STAGE 1 installation complete!.. Hopefully! You will have to shutdown the machine, then eject the liveusb, then starup the machine again. Run 'halt' to shutdown the machine.\\n"

#-----------------------------------------------------------
#                         STAGE 2
#-----------------------------------------------------------
[ -z "$STAGE_2" ] && exit
# stage 2 - setup wm

# TODO remove tarball at start of stage 2.
# rm -f stage3-*.tar.*

#-----------------------------------------------------------
#                         STAGE 3
#-----------------------------------------------------------
[ -z "$STAGE_3" ] && exit
# stage 3 - rice

# emerge -aq 

# dcron
# anacron
# openjdk
# virtual/jre
# eclean-kernel
# acct-user/mpd
# app-admin/doas
# app-admin/pass
# app-admin/stow
# app-admin/sysklogd
# app-arch/unrar
# app-crypt/pinentry
# app-editors/neovim
# app-editors/vim
# app-eselect/eselect-repository
# app-misc/anki
# app-misc/neofetch
# app-misc/task
# app-misc/vifm
# app-portage/eix
# app-portage/gentoolkit
# app-shells/dash
# app-shells/fzf
# app-shells/zsh
# app-text/texlive
# app-text/tree
# app-text/zathura
# app-text/zathura-pdf-poppler
# dev-lang/python
# dev-libs/libressl
# dev-python/neovim-remote
# dev-python/pip
# dev-python/pynvim
# dev-tex/latexmk
# dev-util/shellcheck
# dev-vcs/git
# mail-client/neomutt
# media-fonts/fontawesome
# media-fonts/noto-cjk
# media-fonts/noto-emoji
# media-gfx/gimp
# media-gfx/imagemagick
# media-gfx/scrot
# media-libs/libpng
# media-plugins/alsa-plugins
# media-sound/alsa-utils
# media-sound/audacity
# media-sound/mpd
# media-sound/ncmpcpp
# media-sound/pamix
# media-sound/pulseaudio
# media-video/ffmpeg
# media-video/ffmpegthumbnailer
# media-video/mpv
# net-libs/nodejs
# net-mail/isync
# net-mail/notmuch
# net-misc/networkmanager
# net-misc/youtube-dl
# net-p2p/transmission
# sys-apps/bat
# sys-apps/fd
# sys-apps/pciutils
# sys-apps/ripgrep
# sys-auth/elogind
# sys-boot/grub
# sys-boot/os-prober
# sys-fs/dosfstools
# sys-fs/ntfs3g
# sys-kernel/gentoo-sources
# sys-kernel/linux-firmware
# sys-libs/libcap
# sys-libs/libseccomp
# sys-process/cronie
# sys-process/htop
# virtual/cron
# www-client/firefox
# www-client/lynx
# x11-apps/setxkbmap
# x11-apps/xdpyinfo
# x11-apps/xmodmap
# x11-apps/xset
# x11-base/xorg-server
# x11-drivers/nvidia-drivers
# x11-misc/compton
# x11-misc/dunst
# x11-misc/unclutter
# x11-misc/xcape
# x11-misc/xdg-utils
# x11-misc/xdotool
# x11-misc/xsel
# x11-misc/xwallpaper


# add VIDEO_CARDS="intel nvidia" to make.conf
# - install nvidia drivers
# add INPUT_DEVICES="libinput synaptics" to make.conf
# add 'X xinerama' use flags to make.conf
# - install dwm, dwmblocks, st

# - install zsh
# 	- zsh-completions, gentoo-zsh-completions

# - install fonts (Inconsolata, Source Code Pro, Bitstream Vera Sans, Noto Sans CJK, Noto Sans)
#  Glacial Indifference, Quicksand, Metropolis, Roboto, Caviar Dreams, Cantarell

# - install
# 	https://github.com/uditkarode/libxft-bgra
# - install powerlevel10k
# - install ueberzug through pip (for both root and user)
# - install fontpreview-ueberzug
# - install mutt-wizard
# - install linux-firmware, need to update package.mask and reboot
# - install vim-plug
# 	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
#        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# ncmpcpp

# # set python
# # eselect python list
# # eselect python set <number>


# # TODO mkdir
# # chmod 600 ~/.gnupg/*
# # chmod 700 ~/.gnupg
# # export GNUPGHOME="$XDG_DATA_HOME/gnupg"
EOT
