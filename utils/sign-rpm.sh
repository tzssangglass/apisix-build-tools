#!/usr/bin/env bash
set -euo pipefail
set -x


import_gpg_key() {
    gpg --import --pinentry-mode loopback --batch --passphrase-file \
    /tmp/rpm-gpg-publish.passphrase /tmp/rpm-gpg-publish.private

    gpg --list-keys --fingerprint | grep "${GPG_MAIL}" -B 1 \
    | tr -d ' ' | head -1 | awk 'BEGIN { FS = "\n" } ; { print $1":6:" }' \
    | gpg --import-ownertrust
}

rpm_sign() {
    cat > ~/.rpmmacros <<EOF
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_NAME} ${GPG_MAIL}
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
EOF
    rpmsign --addsign ./apisix-base-${{ steps.tag_env.outputs.version }}-0.el7.x86_64.rpm
}

rpm_checksig() {
    rpm --import https://repos.apiseven.com/KEYS

    out=$(rpm --checksig ./apisix-base-${{ steps.tag_env.outputs.version }}-0.el7.x86_64.rpm)
    if ! echo "$out" | grep "digests signatures OK"; then
        echo "failed: check rpm digests signatures failure"
        exit 1
    fi
}

case_opt=$1

case ${case_opt} in
import_gpg_key)
    import_gpg_key
    ;;
rpm_sign)
    rpm_sign
    ;;
rpm_checksig)
    rpm_checksig
    ;;
esac
