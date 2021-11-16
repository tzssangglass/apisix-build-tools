#!/usr/bin/env bash
set -euo pipefail
set -x

export openssl_prefix=/usr/local/Cellar/openresty-openssl111/1.1.1l_1
export zlib_prefix=/usr/local/Cellar/zlib/1.2.11
export pcre_prefix=/usr/local/Cellar/pcre/8.45

export cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"

./build-apisix-base.sh  latest

