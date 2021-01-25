#!/bin/sh

# TODO args for stages
export stage_1='true'
export stage_1_9='true'

export REPO_DOTFILES='https://github.com/sarrost/dotfiles'
export REPO_SCRIPTS='https://github.com/sarrost/scripts'
export REPO_KERNEL='https://github.com/sarrost/gentoo-kernel'

# Colors
export clear='\033[0m'
export black='\033[0;30m'					; export dark_gray='\033[1;30m'
export red='\033[0;31m'						; export light_red='\033[1;31m'
export green='\033[0;32m'					; export light_green='\033[1;32m'
export orange='\033[0;33m'				; export yellow='\033[1;33m'
export blue='\033[0;34m'					; export light_blue='\033[1;34m'
export purple='\033[0;35m'				; export light_purple='\033[1;35m'
export cyan='\033[0;36m'					; export light_cyan='\033[1;36m'
export light_gray='\033[0;37m'		; export white='\033[1;37m'

export emphasis="${light_cyan}"
export prompt_style="${light_blue}"

# Variables
export header="${cyan}RICE ${blue}=>${clear} "
export warning="${light_red}WARNING ${red}=>${clear} "
export error="${light_red}ERROR ${red}=>${clear} "
export prompt=" ${gray}> ${clear}"
export default_yes="${green}[BLANK]${clear} yes  /  ${red}[N]${clear} no${prompt}"
export default_no="${prompt_style}[BLANK]${clear} no  /  ${green}[Y]${clear} yes${prompt}"
export any_key="${purple}[ANY KEY]${clear}"

export yes_pattern='y/Y/ye/yE/Ye/YE/yes/yeS/yEs/yES/Yes/YeS/YEs/YES'
export no_pattern='n/N/no/nO/No/NO'
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
[ -z "$stage_1" ] && exit

#-----------------------------------------------------------
#	PROMPTS
#-----------------------------------------------------------
# Prompt user to select hostname
while [ -z "$valid_hostname" ]; do
	printf "${header}Enter a name for this machine. For example, ${emphasis}foobar${clear}.\\n${prompt_style}[HOSTNAME] > ${clear}"
	read chosen_hostname
	if [ ! -z "$chosen_hostname" ]; then
		printf "${header}You have chosen ${emphasis}${chosen_hostname}${clear}, do you wish to proceed?\\n${default_yes}"
		read confirmation
		case "$confirmation" in
			@("$no_pattern")) printf "${header}You have cancelled the selection.\\n" ;;
			*) valid_hostname='true'
				export HOSTNAME="$chosen_hostname" ;;
		esac
	fi
done

# Prompt user to select storage device.
while [ -z "$valid_device" ]; do
	printf "${header}Choose a storage device to install the OS to. For example, 'sda' (without the quotes).\\n${warning}The drive will be formatted and all content on it will be lost.\\nListing all storage devices:\\n"
	lsblk -o NAME,SIZE
	printf "${prompt_style}[DEVICE] > ${clear}"
	read chosen_device
	stat "/dev/$chosen_device" > /dev/null 2>&1
	if [ "$?" = 0 ]; then
		printf "${header}You have chosen ${emphasis}${chosen_device}${clear}, type ${emphasis}YES${clear} (in full) to proceed.\\n${warning}Changes made to this device cannot be undone.\\n${prompt_style}[CONFIRM] > ${clear}"
		read confirmation
		case "$confirmation" in
			yes|YES) valid_device='true'
				export device=/dev/"$chosen_device" ;;
			*) printf "${header}You have cancelled the selection.\\n" ;;
		esac
	else
		printf "${error}Invalid device.\\n"
	fi
done
# Devices.
export boot_partition="${device}2"
export swap_partition="${device}3"
export rootfs_partition="${device}4"

# Prompt user to select mount point.
while [ -z "$valid_mount_point" ]; do
	printf "${header}Do you wish to change the default mount point for the root filesystem from ${emphasis}/mnt/gentoo${clear} to something else?\\n${default_no}"
	read choice
	case "$choice" in
		@("$yes_pattern")) printf "${header}Please enter the full path of the mount point you would like to use. If the directory does not already exist it will be created.\\n${prompt_style}[MOUNTPOINT] > ${clear}"
			read chosen_mount_point
			mkdir -p "$chosen_mount_point"
			[ "$?" = 0 ] && valid_mount_point='true'
			;;
		*) valid_mount_point='true'
			export mount_point=/mnt/gentoo ;;
	esac
done


# Prompt user to determine boot type.
while [ -z "$valid_boot_type" ]; do
	# TODO color
	printf "${header}Choose the correct system boot type from the list below. For example ${emphasis}1${clear}.\\n[1] UEFI\\n[2] BIOS\\n[BOOT] > "
	read choice
	case "$choice" in
		1) export boot_type='uefi'; valid_boot_type='true';;
		2) export boot_type='bios'; valid_boot_type='true';;
	esac
done

# Prompt user to enter manual datetime, and set it.
while [ -z "$valid_datetime" ]; do
	printf "${header}Enter current date and time. Format is ${emphasis}MMDDhhmmYYYY${clear}, for example ${emphasis}011523002021${clear} for '23:00, 15 January 2021'\\n${prompt_style}[DATETIME] > ${clear}"
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
	printf "${header}Please enter your timezone. For example ${emphasis}Africa/Johannesburg${clear}.\\n${prompt_style}[TIMEZONE] > ${clear}"
	read chosen_timezone
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
	printf "${header}Default locale is ${emphasis}en_US${clear}, do you wish to change locale?\\n${default_no}"
	read choice
	if [ -z "$choice" ]; then
		valid_locale='true'
	else
		# User must enter custom locale info.
		custom_locale='true'
		# Get first line.
		printf "${header}Please see the README for the required info regarding your desired locale.\\nEnter the first line of your locale code, for example, ${emphasis}en_US ISO-8859-1${clear}\\n${prompt_style}[LOCALE LINE 1] > ${clear}"
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
			printf "${header}Enter the second line (if any) of your locale code, for example, ${emphasis}en_US.UTF-8 UTF-8${clear}\\n${prompt_style}[LOCALE LINE 2] > ${clear}"
			read locale_2
			if [ ! -z "$locale_2" ]; then
				cat /usr/share/i18n/SUPPORTED | grep "$locale_2" > /dev/null 2>&1
				[ "$?" = 0 ] && valid_locale='true' && export locale_2
			else
				if [ ! -z "$locale_1" ]; then
					valid_locale='true'
					export locale_1
				else
					printf "${error}Both lines cannot be left blank.\\n"
				fi
			fi
		fi
	fi
done

# Prompt user for number of jobs to use to build packages.
while [ -z "$valid_makeopts" ]; do
	export threads=$(nproc)
	printf "${header}Detected ${emphasis}${threads}${clear} total [logical] threads on this machine, would you like to use all of them to compile your packages?\\n${default_yes}"
	read confirmation
	case "$confirmation" in
		@("$no_pattern")) printf "${header}Enter the amount of threads you would like to use instead of the default of ${emphasis}${threads}${clear}.\\n${prompt_style}[THREADS] > ${clear}" 
			read custom_threads
			[ "$custom_threads" -le "$threads" ] && 
				valid_makeopts='yes' && export threads=$((threads + 1));;
		*) valid_makeopts='yes' 
			export threads=$((threads + 1));;
	esac
done

# Prompt user to select mirrors.
while [ -z "$valid_mirrors" ]; do
	printf "${header}Packages will be downloaded from French mirrors (the packages themselves will still be in your locale/language), do you wish to change the mirrors to something else?\\n${default_no}"
	read choice
	case "$choice" in
		@("$yes_pattern")) custom_mirrors='true'
			printf "${header}A menu with a list of mirrors will be presented, hit ${emphasis}[SPACE]${clear} to toggle which mirrors you wish to use. It is recommended that you select more than one mirror in case one or more are offline.\\n${any_key}"
			read dummy
			export mirrors=$(mirrorselect -i -o)
			[ -z "$mirrors" ] || valid_mirrors='true';;
		*) valid_mirrors='true';;
	esac
done


# TODO Prompt user to select kernel dir.
export KERNEL_DIR=msi

# Fetch kernel version.
# TODO proper link variable
export KERNEL_VER=$(curl --silent https://raw.githubusercontent.com/sarrost/gentoo-kernel/master/configs/msi/latest.txt)

# Prompt user to select kernel version.
# TODO register proper choice
while [ -z "$valid_kernel" ]; do
	printf "${header}Do you wish to change the kernel version from ${emphasis}${KERNEL_VER}${clear}?\\n${default_no}"
	read choice
	case "$choice" in
		*) valid_kernel='true';;
		@("$yes_pattern")) printf "${header}Please enter the kernel version you would like to use, for example, ${emphasis}${KERNEL_VER}${clear}.\\n${warning}The version number will not be checked for validity, so please ensure you have entered it correctly.\\n${prompt_style}[KERNEL]${prompt}"
			read chosen_kernel_version
			printf "${header}You have chosen ${emphasis}${chosen_kernel_version}${clear} as your kernel version, is this correct?\\n${default_yes}"
			read confirmation
			case "$confirmation" in
				@("$no_pattern")) printf "${header}You have cancelled the selection.\\n" ;;
				*) valid_kernel='true'
					export KERNEL_VER="$chosen_kernel_version" ;;
			esac
	esac
done

#-----------------------------------------------------------
#	LIVEUSB
#-----------------------------------------------------------
printf "${header}Formatting storage device and creating partitions. This will take some time as the strorage medium is being overwritten with random data for a secure-ish wipe.\\n"
# Erase disk
dd if=/dev/urandom of="$device" bs=1M > /dev/null 2>&1
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
mkfs.ext4 -q "$rootfs_partition"

printf "${header}Activate swap partition.\\n"
mkswap "$swap_partition" >/dev/null
swapon "$swap_partition" >/dev/null

printf "${header}Mounting root filesystem.\\n"
mount "$rootfs_partition" "$mount_point"
cd "$mount_point"

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
sed -i "s/COMMON_FLAGS=\".\+\"/COMMON_FLAGS=\"-march=native -O2 -pipe\"/g" "$mount_point"/etc/portage/make.conf
# Update amount of jobs to use when emerging packages.
printf "\\nMAKEOPTS=\"-j${threads}\"" >> "$mount_point"/etc/portage/make.conf

printf "${header}Select mirrors to use.\\n"
if [ -z "$custom_mirrors" ]; then
	printf "\\nGENTOO_MIRRORS=\"ftp://ftp.free.fr/mirrors/ftp.gentoo.org/ http://ftp.free.fr/mirrors/ftp.gentoo.org/ http://gentoo.modulix.net/gentoo/ http://gentoo.mirrors.ovh.net/gentoo-distfiles/ https://mirrors.soeasyto.com/distfiles.gentoo.org/ http://mirrors.soeasyto.com/distfiles.gentoo.org/ ftp://mirrors.soeasyto.com/distfiles.gentoo.org/\"\\n" >> "$mount_point"/etc/portage/make.conf
else
	printf "\\n$mirrors\\n" >> "$mount_point"/etc/portage/make.conf
fi

printf "${header}Configuring ebuild repository.\\n"
mkdir --parents "$mount_point"/etc/portage/repos.conf
cp "$mount_point"/usr/share/portage/config/repos.conf "$mount_point"/etc/portage/repos.conf/gentoo.conf
# TODO custom gentoo repo

printf "${header}Copying DNS info.\\n"
cp --dereference /etc/resolv.conf "$mount_point"/etc/

printf "${header}Mounting the necessary filesystems.\\n"
mount --types proc /proc "$mount_point"/proc
mount --rbind /sys "$mount_point"/sys
mount --make-rslave "$mount_point"/sys
mount --rbind /dev "$mount_point"/dev
mount --make-rslave "$mount_point"/dev 

#-----------------------------------------------------------
#	CHROOT
#-----------------------------------------------------------
printf "${header}Changing root to ${emphasis}${mount_point}${clear}.\\n"
# NOTE: comment out this line when editing to restore syntax
#       highlighting if broken.
chroot "$mount_point" /bin/bash << "EOT"

printf "${header}Installing ebuild repo snapshot from web.\\n"
emerge --sync --quiet > /dev/null 2>&1
printf "${header}Updating package manager.\\n"
emerge --oneshot --quiet sys-apps/portage
printf "${header}Installing git and stow.\\n"
emerge --quiet dev-vcs/git app-admin/stow
printf "${header}Installing dosfstools.\\n" # dosfstools is needed for vfat.
emerge --quiet dosfstools

# Properly format boot partition.
mkfs.vfat -q -F 32 "$boot_partition"
# Mount boot partition
mount "$boot_partition" /boot	

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
echo "$timezone" > /etc/timezone
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
printf "${boot_partition}	/boot	vfat	defaults,noatime	0	2
${swap_partition}	none	swap	sw	0	0
${rootfs_partition}	/	ext4	noatime	0	1" >> /etc/fstab

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
[ -z "$stage_1_9" ] && exit

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
[ -z "$stage_1_99" ] && exit
# TODO stop here and ask to confirm that all is well

# Reboot and remove liveusb
printf "${header}Leaving chroot environment.\\n"
exit
printf "${header}Unmounting storage devices.\\n"
umount -l "$mount_point"/dev{/shm,/pts,}
umount -R "$mount_point"

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
