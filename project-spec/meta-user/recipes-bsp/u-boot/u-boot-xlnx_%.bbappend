SRC_URI_append = " file://platform-top.h"
SRC_URI += "file://bsp.cfg \
            file://user_2018-07-18-12-32-00.cfg \
            "

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
