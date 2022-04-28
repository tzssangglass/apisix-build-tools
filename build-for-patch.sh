#!/usr/bin/env bash
set -euo pipefail
set -x

openssl_prefix=/usr/local/openresty-debug/openssl111
zlib_prefix=/usr/local/openresty/zlib
pcre_prefix=/usr/local/openresty/pcre

cc_opt="-DNGX_LUA_USE_ASSERT -DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O0"
ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
luajit_xcflags="-DLUAJIT_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -O0 -g"
OR_PREFIX=/usr/local/openresty-dev-apisix-base
version=${version:-0.0.0}
debug_args=--with-debug
or_ver="1.19.9.1"


cd /usr/local
rm -rf openresty-${or_ver}
tar -zxvpf openresty-${or_ver}.tar.gz > /dev/null

cd /usr/local/apisix-nginx-module/patch
./patch.sh /usr/local/openresty-${or_ver}

cd /usr/local

cd openresty-${or_ver} || exit 1
./configure --prefix="$OR_PREFIX" \
    --with-cc-opt="-DAPISIX_BASE_VER=$version $cc_opt" \
    --with-ld-opt="-Wl,-rpath,$OR_PREFIX/wasmtime-c-api/lib $ld_opt" \
    $debug_args \
    --add-module=/usr/local/apisix-nginx-module \
    --add-module=/usr/local/apisix-nginx-module/src/stream \
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
    -j4

make -j4
sudo make install
cd ..

cd /usr/local/apisix-nginx-module || exit 1
OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..
