# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
# supports 12.x but URL has a specific version number
cuDNN_V="$(echo ${PV//./})"
CUDA_MA="12"
CUDA_MI="1"
CUDA_V="${CUDA_MA}${CUDA_MI}"

DESCRIPTION="NVIDIA Accelerated Deep Learning on GPU library"
HOMEPAGE="https://developer.nvidia.com/cudnn"
SRC_URI="" #https://developer.nvidia.com/downloads/c${CUDA_V}-cudnn-linux-8664-${cuDNN_V}cuda${CUDA_MA}-archivetarz -> cudnn-linux-x86_64-${PV}_cuda${CUDA_MA}-archive.tar.xz
S="${WORKDIR}/cudnn-linux-x86_64-${PV}_cuda${CUDA_MA}-archive"

LICENSE="NVIDIA-cuDNN"
SLOT="0/8"
KEYWORDS="~amd64 ~amd64-linux"
RESTRICT="mirror"

RDEPEND="=dev-util/nvidia-cuda-toolkit-12*"

QA_PREBUILT="/opt/cuda/targets/x86_64-linux/lib/*"

src_unpack() {
	unpack ${FILESDIR}/cudnn-linux-x86_64-${PV}_cuda${CUDA_MA}-archive.tar.xz
	cd ${S}
}

src_install() {
	insinto /opt/cuda/targets/x86_64-linux
	doins -r include lib
}
