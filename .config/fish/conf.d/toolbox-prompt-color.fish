# Override host color when running in a toolbox
if test -f /run/.containerenv -a -f /run/.toolboxenv
    set -g fish_color_host magenta
end
