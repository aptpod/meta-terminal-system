# On EDGEPLANT T1, the /data partition is limited to 2GB.
# This means that if an artifact exceeds 1GB in size, extracting its contents will fail.
# To avoid this issue, we set a temporary file for use.
CUSTOM_CONTENTS_TGZ_TMP = "/media/ssd/tmp-contents.tgz"
