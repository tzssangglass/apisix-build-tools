#!/usr/bin/env bash
set -euo pipefail
set -x

openssl_prefix=/usr/local/openresty-debug/openssl111
zlib_prefix=/usr/local/openresty/zlib
pcre_prefix=/usr/local/openresty/pcre

export cc_opt="-DNGX_LUA_USE_ASSERT -DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O0"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
export luajit_xcflags="-DLUAJIT_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -O0 -g"
export OR_PREFIX=/usr/local/openresty-develop
export or_ver="1.21.4.1"

if [ ! -f $PWD/openresty-${or_ver}.tar.gz ]; then
    wget --no-check-certificate https://openresty.org/download/openresty-${or_ver}.tar.gz
fi

rm -rf /opt/openresty-${or_ver}
tar -zxvpf openresty-${or_ver}.tar.gz -C /opt
mv /opt/openresty-${or_ver} /opt/openresty-develop

cd /opt/openresty-develop
./configure --prefix="$OR_PREFIX" \
    --with-cc-opt="-DOPENRESTY_VER=openresty-develop $cc_opt" \
    --with-ld-opt="-Wl,-rpath, $ld_opt" \
    --with-debug \
    --add-module=/usr/local/nginx/src/lua-resty-events \
    --with-poll_module \
    --with-pcre-jit \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-threads \
    --with-compat \
    --with-luajit-xcflags="$luajit_xcflags" \
    -j16

make -j16
make install
