# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

DESCRIPTION="Darling is a runtime environment for macOS applications."
HOMEPAGE="https://darlinghq.org"
SRC_URI="https://github.com/darlinghq/${PN}/releases/download/v${PV}/${PN}_${PV}.focal_amd64.deb -> ${P}.deb"

S="${WORKDIR}"

SLOT="0"
KEYWORDS="~amd64"



src_install() {
	into /
	cp -a  "${S}/" "${D}/" || die "Install failed!"
}
