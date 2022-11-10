#!/usr/bin/env bash
set -euo pipefail
set -x

wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
apt-get -y update --fix-missing
apt-get -y install software-properties-common
add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty"
apt-get update
apt-get install -y make
apt-get install -y openresty-openssl111-debug-dev openresty-openssl111-debug-dbgsym openresty-pcre-dev openresty-pcre-dbgsym openresty-zlib-dev openresty-zlib-dbgsym

export openssl_prefix=/usr/local/openresty-debug/openssl111
export zlib_prefix=/usr/local/openresty/zlib
export pcre_prefix=/usr/local/openresty/pcre

export cc_opt="-DNGX_LUA_USE_ASSERT -DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O0"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
export luajit_xcflags="-DLUAJIT_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -O0 -g"
export OR_PREFIX=/usr/local/openresty-debug
export debug_args=--with-debug

./build-apisix-base.sh latest
