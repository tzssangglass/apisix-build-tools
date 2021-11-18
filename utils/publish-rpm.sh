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



rpm_checksig() {
#    rpm --import https://repos.apiseven.com/KEYS
    rpm --import /tmp/rpm-gpg-publish.public

    out=$(rpm --checksig ./apisix-base-${APISIX_BASE_TAG_VERSION}-0.el7.x86_64.rpm)
    if ! echo "$out" | grep "digests signatures OK"; then
        echo "failed: check rpm digests signatures"
        exit 1
    fi
}


init_rpmmacros() {
    cat > ~/.rpmmacros <<EOF
# Macros for signing RPMs.
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_NAME} ${GPG_MAIL}
%_gpgbin /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} gpg --batch --verbose --no-armor --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}
EOF
}


sign_apisix_base() {
    import_gpg_key

    init_rpmmacros

    rpmsign --addsign ./apisix-base-${APISIX_BASE_TAG_VERSION}-0.el7.x86_64.rpm

    rpm_checksig
}


download_ossutil64() {
    echo "[Credentials]" >> /tmp/ossutilconfig
    echo "language=EN" >> /tmp/ossutilconfig
    echo "endpoint=oss-cn-shanghai.aliyuncs.com" >> /tmp/ossutilconfig
    echo "accessKeyID=${ACCESS_KEY_ID}" >> /tmp/ossutilconfig
    echo "accessKeySecret=${ACCESS_KEY_SECRET}" >> /tmp/ossutilconfig
    wget http://gosspublic.alicdn.com/ossutil/1.7.3/ossutil64
    chmod 755 ossutil64
}


backup_and_rebuild_repo() {
    download_ossutil64

    # backup origin repo
    date_tag=$(date +%Y%m%d)
    ./ossutil64 cp -r oss://tzs-apisix-repo/packages/centos/7/x86_64 oss://tzs-apisix-repo/packages/backup/centos/7/x86_64_$date_tag --config-file=/tmp/ossutilconfig

    # download origin repo
    ./ossutil64 cp -r oss://tzs-apisix-repo/packages/centos/7/x86_64 ./ --config-file=/tmp/ossutilconfig

    # rebuild repo
    cp ./apisix-base-${APISIX_BASE_TAG_VERSION}-0.el7.x86_64.rpm ./x86_64
    cd ./x86_64

    sudo apt-get update
    sudo apt install createrepo -y
    createrepo .
    cd ../
}


sign_repo_metadata() {
    gpg --batch --pinentry-mode loopback --passphrase-file /tmp/rpm-gpg-publish.passphrase --detach-sign --armor ./x86_64/repodata/repomd.xml

    out=$(gpg --verify x86_64/repodata/repomd.xml.asc)
    if ! echo "$out" | grep "Good signature from"; then
        echo "failed: check rpm metadata signatures"
        exit 1
    fi
}


upload_new_repo() {
    # rm origin repo and upload new repo
    ./ossutil64 rm -r -f oss://tzs-apisix-repo/packages/centos/7/x86_64 --config-file=/tmp/ossutilconfig
    ./ossutil64 cp -r ./x86_64 oss://tzs-apisix-repo/packages/centos/7/x86_64 --config-file=/tmp/ossutilconfig
}


check_down_load_apisix_base_rpm() {
    mkdir temp && cd temp
    wget https://repos.apiseven.com/packages/centos/7/x86_64/apisix-base-${APISIX_BASE_TAG_VERSION}-0.el7.x86_64.rpm
    if [ ! -f apisix-base-${APISIX_BASE_TAG_VERSION}-0.el7.x86_64.rpm ]; then
        echo "failed: download new apisix-base rpm package"
        exit 1
    fi
    cd ../
}


rm_backup_repo() {
    date_tag=$(date +%Y%m%d)
    ./ossutil64 rm -r -f oss://tzs-apisix-repo/packages/backup/centos/7/x86_64_$date_tag --config-file=/tmp/ossutilconfig
}


case_opt=$1

case ${case_opt} in
sign_apisix_base)
    sign_apisix_base
    ;;
backup_and_rebuild_repo)
    backup_and_rebuild_repo
    ;;
sign_repo_metadata)
    sign_repo_metadata
    ;;
upload_new_repo)
    upload_new_repo
    ;;
check_down_load_apisix_base_rpm)
    check_down_load_apisix_base_rpm
    ;;
rm_backup_repo)
    rm_backup_repo
    ;;
esac
