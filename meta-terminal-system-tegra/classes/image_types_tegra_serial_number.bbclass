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
    mount -o ro ${IMAGE_BASENAME}.ext4 /mnt/rootfs
    mount ${DATAFILE} /mnt/datafile

    if [ "\${OPT_USE_MENDER}" = "false" ]; then
        if [ x != x\${SERIAL_NUMBER} ]; then
            echo "writing serial number \"\${SERIAL_NUMBER}\" to data partition"
            echo "\${SERIAL_NUMBER}" > /mnt/datafile/serial_number
        else
            echo "clear serial number"
            echo "" > /mnt/datafile/serial_number
        fi

        echo "clear mender server url and token"
        echo "[INFO] The default Mender server URL has been removed. When provisioning with Mender enabled using the same image, it is necessary to configure the Mender server URL."
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

    if [ x != x\${SERIAL_NUMBER} ]; then
        hostname="\$(echo "\${SERIAL_NUMBER}" | tr -d '_.')"
        hostname="\$(echo "\${hostname}" | sed 's/^-*//; s/-*$//')"
        hostname="\$(echo "\${hostname}" | cut -c1-63)"
    else
        hostname="terminal-system"
    fi
    echo "writing hostname \"\${hostname}\""
    echo "\${hostname}" > /mnt/datafile/overlay/etc/hostname

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
        # Copy original passwd/shadow files to overlay directory first to avoid modifying rootfs
        cp -a /mnt/rootfs/etc/passwd /mnt/rootfs/etc/shadow /mnt/datafile/overlay/etc/

        # Directly edit /etc/shadow in overlay directory (not in rootfs)
        # This avoids rootfs modification and eliminates the need for usermod/chroot/qemu
        if [ x != x\${USER_PASS_ROOT} ]; then
            echo "writing login password for root \"\${USER_PASS_ROOT}\""
            sed -i "s|^root:[^:]*:|root:\${USER_PASS_ROOT}:|" /mnt/datafile/overlay/etc/shadow
        fi
        if [ x != x\${USER_PASS_ADMIN} ]; then
            echo "writing login password for admin \"\${USER_PASS_ADMIN}\""
            sed -i "s|^admin:[^:]*:|admin:\${USER_PASS_ADMIN}:|" /mnt/datafile/overlay/etc/shadow
        fi
        if [ x != x\${USER_PASS_MAINT} ]; then
            echo "writing login password for maint \"\${USER_PASS_MAINT}\""
            sed -i "s|^maint:[^:]*:|maint:\${USER_PASS_MAINT}:|" /mnt/datafile/overlay/etc/shadow
        fi
    fi

    umount /mnt/datafile
    umount /mnt/rootfs
    rm -rf /mnt/rootfs /mnt/datafile
 }

if [ "\$(id -u)" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi
for cmd in python jq sed; do
    if ! which \${cmd} >/dev/null 2>&1; then
        echo "This installer requires '\${cmd}' command."
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