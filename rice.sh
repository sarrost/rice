emerge -aq 

acct-user/mpd
app-admin/doas
app-admin/pass
app-admin/stow
app-admin/sysklogd
app-arch/unrar
app-crypt/pinentry
app-editors/neovim
app-editors/vim
app-eselect/eselect-repository
app-misc/anki
app-misc/neofetch
app-misc/task
app-misc/vifm
app-portage/eix
app-portage/gentoolkit
app-shells/dash
app-shells/fzf
app-shells/zsh
app-text/texlive
app-text/tree
app-text/zathura
app-text/zathura-pdf-poppler
dev-lang/python
dev-libs/libressl
dev-python/neovim-remote
dev-python/pip
dev-python/pynvim
dev-tex/latexmk
dev-vcs/git
mail-client/neomutt
media-fonts/fontawesome
media-fonts/noto-cjk
media-fonts/noto-emoji
media-gfx/gimp
media-gfx/imagemagick
media-gfx/scrot
media-libs/libpng
media-plugins/alsa-plugins
media-sound/alsa-utils
media-sound/audacity
media-sound/mpd
media-sound/ncmpcpp
media-sound/pamix
media-sound/pulseaudio
media-video/ffmpeg
media-video/ffmpegthumbnailer
media-video/mpv
net-libs/nodejs
net-mail/isync
net-mail/notmuch
net-misc/networkmanager
net-misc/youtube-dl
net-p2p/transmission
sys-apps/bat
sys-apps/fd
sys-apps/pciutils
sys-apps/ripgrep
sys-auth/elogind
sys-boot/grub
sys-boot/os-prober
sys-fs/dosfstools
sys-fs/ntfs3g
sys-kernel/gentoo-sources
sys-kernel/linux-firmware
sys-libs/libcap
sys-libs/libseccomp
sys-process/cronie
sys-process/htop
virtual/cron
www-client/firefox
www-client/lynx
x11-apps/setxkbmap
x11-apps/xdpyinfo
x11-apps/xmodmap
x11-apps/xset
x11-base/xorg-server
x11-drivers/nvidia-drivers
x11-misc/compton
x11-misc/dunst
x11-misc/unclutter
x11-misc/xcape
x11-misc/xdg-utils
x11-misc/xdotool
x11-misc/xsel
x11-misc/xwallpaper


add VIDEO_CARDS="intel nvidia" to make.conf
- install nvidia drivers
add INPUT_DEVICES="libinput synaptics" to make.conf
add 'X xinerama' use flags to make.conf
- install dwm, dwmblocks, st

- install zsh
	- zsh-completions, gentoo-zsh-completions

- install fonts (Inconsolata, Source Code Pro, Bitstream Vera Sans, Noto Sans CJK, Noto Sans)
 Glacial Indifference, Quicksand, Metropolis, Roboto, Caviar Dreams, Cantarell

- install
	https://github.com/uditkarode/libxft-bgra
- install powerlevel10k
- install ueberzug through pip (for both root and user)
- install fontpreview-ueberzug
- install mutt-wizard
- install linux-firmware, need to update package.mask and reboot
- install vim-plug
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

ncmpcpp

# set python
# eselect python list
# eselect python set <number>
