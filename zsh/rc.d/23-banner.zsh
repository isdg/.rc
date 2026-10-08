# %n = the real user, not a hardcoded name: a root shell sourcing this config
# (sudo -E, su -m) says "root", so the banner can't claim to be isg while the
# shell can write anywhere.
banner_info "%B%n%b · $(banner_host_info)"
# addresses go on their own line under the identity, and only when there are
# any — a local login has no peer to name, so the banner stays three lines
_banner_net=$(banner_net_info)
[[ -n $_banner_net ]] && banner_info "$_banner_net"
unset _banner_net
banner_info "%D{%a %d %b %Y · %H:%M}"
_banner_branch=$(command git symbolic-ref --short HEAD 2>/dev/null)
banner_info "%~${_banner_branch:+ · $_banner_branch}"
unset _banner_branch
banner_render
