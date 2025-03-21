# . /usr/local/opt/emsdk/emsdk_env.fish
if [ -d /usr/local/opt/emsdk ]
    set -l emsdk_dir /usr/local/opt/emsdk
    eval ($emsdk_dir/emsdk construct_env 2> /dev/null)
    set -e -l emsdk_dir
end

