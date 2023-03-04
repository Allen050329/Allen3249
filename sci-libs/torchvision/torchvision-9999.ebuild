# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_11 )
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 git-r3

DESCRIPTION="Datasets, transforms and models to specific to computer vision"
HOMEPAGE="https://github.com/pytorch/vision"
EGIT_REPO_URI="https://github.com/pytorch/vision.git"
S="${WORKDIR}/vision-${PV}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/scipy[${PYTHON_USEDEP}]
	')
	sci-libs/pytorch-uvm[${PYTHON_SINGLE_USEDEP}]
	media-video/ffmpeg
	dev-qt/qtcore:5
"
DEPEND="${RDEPEND}"
BDEPEND="
	test? (
		$(python_gen_cond_dep '
		dev-python/mock[${PYTHON_USEDEP}]
		')
	)"
IUSE+=" test"
src_prepare() {
        git clone --recursive "${EGIT_REPO_URI}" "${S}"
        cd "${S}"
	distutils-r1_src_prepare
}

src_compile() {
	USE_SYSTEM_LIBS=ON \
	CMAKE_BUILD_DIR="${BUILD_DIR}" \
	BUILD_DIR= \
	distutils-r1_src_compile
}

src_install() {
	USE_SYSTEM_LIBS=ON distutils-r1_src_install
}
