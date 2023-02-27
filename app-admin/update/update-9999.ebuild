# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="update is a hook for updating via portage and other updating-related tasks"
HOMEPAGE="https://github.com/Allen050329/update-for-gentoo"
SLOT="1"

inherit git-r3
EGIT_REPO_URI="https://github.com/Allen050329/update-for-gentoo.git"

RDEPEND="sys-apps/portage
        app-shells/bash"
DEPEND="${RDEPEND}"

src_unpack() {
        git clone ${EGIT_REPO_URI} ${P}
}

src_install() {
	dodir "/usr/share/updater"
	exeinto "/usr/share/updater/"
	doexe "addrepo"
	doexe "build_rest"
        doexe "update"
        doexe "update_whilst_borked"
        doexe "updater"
	dosym "/usr/share/updater/updater" "/usr/bin/update"
	dodoc README.md
}

pkg_postinst() {
	ewarn "This package has only been tested by the dev himself as of 2023/1/24 0300 UTC time, and has NO WARRANTY WHATSOEVER."
	ewarn "Proceed at your own risk; but if there are bugs, please feel free to open an issue at ${HOMEPAGE} ."
}
