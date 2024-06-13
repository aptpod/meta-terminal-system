# write serial number to datafile

inherit image_types_tegra

tegraflash_custom_post() {
    if [ -n "${DATAFILE}" -a -n "${IMAGE_TEGRAFLASH_DATA}" ]; then
        cat > doflash_pre.sh <<END
#!/bin/sh

OPT_USE_MENDER="\${OPT_USE_MENDER:-"true"}"

check_arg() {
    if eval [ x = x"\\\${\$1}" ]; then
        echo "ERROR: Set variable \"\$1\""
        exit 1
    fi
 }
validate_arg() {
    if eval [ x != x"\\\${\$1}" ]; then
        if ! eval echo "\\\${\$1}" | grep -qE \$2; then
            echo "ERROR: \$1 must match regex '\$2'"
            exit 1
        fi
    fi
 }
prepare_datafile() {
    mkdir -p /mnt/rootfs /mnt/datafile
    mount ${IMAGE_BASENAME}.ext4 /mnt/rootfs
    mount ${DATAFILE} /mnt/datafile

    if [ "\${OPT_USE_MENDER}" = "false" ]; then
        mender_conf=\$(echo "{\"ServerURL\":\"\",\"TenantToken\":\"\"}")
        mender_conf=\$(jq ". * \${mender_conf}" /mnt/datafile/mender/mender.conf)
        printf "%s" "\${mender_conf}" > /mnt/datafile/mender/mender.conf
    else
        echo "writing serial number \"\${SERIAL_NUMBER}\" to data partition"
        echo "\${SERIAL_NUMBER}" > /mnt/datafile/serial_number

        test -z "\${OPT_MENDER_SERVER_URL}" || echo "writing mender server url \"\${OPT_MENDER_SERVER_URL}\""
        test -z "\$MENDER_TENANT_TOKEN" || echo "writing mender server token \"\$(echo \$MENDER_TENANT_TOKEN | cut -c 1-47)...\""
        mender_conf=\$(echo "{\"ServerURL\":\"\${OPT_MENDER_SERVER_URL}\",\"TenantToken\":\"\$MENDER_TENANT_TOKEN\"}" | jq -c 'with_entries(select(.value != ""))')
        mender_conf=\$(jq ". * \${mender_conf}" /mnt/datafile/mender/mender.conf)
        printf "%s" "\${mender_conf}" > /mnt/datafile/mender/mender.conf
    fi

    mkdir -p /mnt/datafile/overlay/etc/core

    if [ x != x\${API_USER_PASS_ADMIN} -o x != x\${API_USER_PASS_USER} ]; then
        cp -a /mnt/rootfs/etc/core/htpasswd /mnt/datafile/overlay/etc/core
        if [ x != x\${API_USER_PASS_ADMIN} ]; then
            echo "writing api password for admin \"\${API_USER_PASS_ADMIN}\""
            sed -i "s@^admin:.*@admin:\${API_USER_PASS_ADMIN}@g" /mnt/datafile/overlay/etc/core/htpasswd
        fi
        if [ x != x\${API_USER_PASS_USER} ]; then
            echo "writing api password for user \"\${API_USER_PASS_USER}\""
            sed -i "s@^user:.*@user:\${API_USER_PASS_USER}@g" /mnt/datafile/overlay/etc/core/htpasswd
        fi
    fi

    if [ x != x\${USER_PASS_ROOT} -o x != x\${USER_PASS_ADMIN} -o x != x\${USER_PASS_MAINT} ]; then
        if [ "aarch64" != "$(uname -m)" ]; then
            cp -a /usr/bin/qemu-aarch64-static /mnt/rootfs/usr/bin/
        fi

        if [ x != x\${USER_PASS_ROOT} ]; then
            echo "writing login password for root \"\${USER_PASS_ROOT}\""
            chroot /mnt/rootfs /usr/sbin/usermod -p \${USER_PASS_ROOT} root
        fi
        if [ x != x\${USER_PASS_ADMIN} ]; then
            echo "writing login password for admin \"\${USER_PASS_ADMIN}\""
            chroot /mnt/rootfs /usr/sbin/usermod -p \${USER_PASS_ADMIN} admin
        fi
        if [ x != x\${USER_PASS_MAINT} ]; then
            echo "writing login password for maint \"\${USER_PASS_MAINT}\""
            chroot /mnt/rootfs /usr/sbin/usermod -p \${USER_PASS_MAINT} maint
        fi

        cp -a /mnt/rootfs/etc/passwd /mnt/rootfs/etc/shadow /mnt/datafile/overlay/etc/
        rm -f /mnt/rootfs/usr/bin/qemu-aarch64-static
    fi

    umount /mnt/datafile
    umount /mnt/rootfs
    rm -rf /mnt/rootfs /mnt/datafile
 }

if [ "\$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi
for cmd in jq; do
    if ! which \${cmd} >/dev/null 2>&1; then
        echo "This installer requires '\${cmd}' to run."
        exit 1
    fi
done

if [ "\${OPT_USE_MENDER}" = "true" ]; then
    check_arg SERIAL_NUMBER
    check_arg MENDER_TENANT_TOKEN
fi
check_arg API_USER_PASS_ADMIN
check_arg API_USER_PASS_USER
check_arg USER_PASS_ROOT
check_arg USER_PASS_ADMIN
check_arg USER_PASS_MAINT
validate_arg SERIAL_NUMBER '^[0-9a-zA-Z_.-]*$'
# you can generate API_USER_PASS_XXXX with openssl:
#   API_USER_PASS_XXXX=\$(echo p@ssword | openssl passwd -apr1 -stdin)
#   or
#   API_USER_PASS_XXXX='$apr1$aNOi.ZS1$3MNDjruW3MMlHK.EXAMPLE'
validate_arg API_USER_PASS_ADMIN '^\\\$apr1\\\$'
validate_arg API_USER_PASS_USER '^\\\$apr1\\\$'
# you can generate USER_PASS_XXXX with openssl:
#   USER_PASS_XXXX=\$(echo p@ssword | openssl passwd -6 -stdin)
#   or
#   USER_PASS_XXXX='$6$3RgJeiy2nEpwmNX4$RjjGNuDJDFpDGkpkBCUvkPqqAhvrChBNlWouLaJbDqQEdzGvdxPz.vdfoLe3ckmyPcHNx5E3liqhgA.EXAMPLE'
validate_arg USER_PASS_ROOT '^\\\$6\\\$'
validate_arg USER_PASS_ADMIN '^\\\$6\\\$'
validate_arg USER_PASS_MAINT '^\\\$6\\\$'
validate_arg OPT_MENDER_SERVER_URL '^https?://.*$'
validate_arg MENDER_TENANT_TOKEN '^.+$'
validate_arg OPT_USE_MENDER '^(true|false)$'
prepare_datafile
END

        # update doflash.sh
        sed -i 's|^#!/bin/sh$||' doflash.sh
        cat doflash_pre.sh doflash.sh > doflash_merged.sh
        mv doflash_merged.sh doflash.sh
        chmod +x doflash.sh
        rm doflash_pre.sh
    fi
}