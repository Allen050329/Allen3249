# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake git-r3

DESCRIPTION="library of floating-point neural network inference operators"
HOMEPAGE="https://github.com/google/XNNPACK/"
EGIT_REPO_URI="https://github.com/google/XNNPACK.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+assembly jit +memopt +sparse static-libs test"

RDEPEND="
	dev-libs/cpuinfo
	dev-libs/pthreadpool
"
DEPEND="${RDEPEND}
	dev-libs/FP16
	dev-libs/FXdiv
"

BDEPEND="test? ( dev-cpp/gtest )"
RESTRICT="!test? ( test )"
REQUIRED_USE="test? ( static-libs )"

S="${WORKDIR}"/${P}

src_prepare() {
	sed -i \
		-e "/PRIVATE fp16)/d" \
		-e "/PRIVATE fxdiv)/d" \
		-e "/PRIVATE clog)/d" \
		-e "/TARGET_LINK_LIBRARIES/s: fp16::" \
		CMakeLists.txt \
		|| die
	dropTest=(
		"add-nd-test"
		"subtract-nd-test"
		"f32-velu-test"
		"qc8-dwconv-minmax-fp32-test"
		"qs8-dwconv-minmax-fp32-test"
		"qs8-vadd-minmax-test"
		"qs8-vaddc-minmax-test"
		"qu8-dwconv-minmax-fp32-test"
		"qu8-vadd-minmax-test"
		"qu8-vaddc-minmax-test"
	)
	for id in ${dropTest[@]}
	do
		sed -i \
			-e "/ADD_TEST(${id}/d" \
			CMakeLists.txt \
			|| die
	done

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DXNNPACK_BUILD_BENCHMARKS=OFF
		-DCMAKE_C_FLAGS=-fPIC
		-DCMAKE_CXX_FLAGS=-fPIC
		-DBUILD_SHARED_LIBS=ON
		-DXNNPACK_LIBRARY_TYPE=shared
		-DXNNPACK_USE_SYSTEM_LIBS=ON
		-DXNNPACK_BUILD_TESTS=$(usex test ON OFF)
		-DXNNPACK_ENABLE_ASSEMBLY=$(usex assembly ON OFF)
		-DXNNPACK_ENABLE_JIT=$(usex jit ON OFF)
		-DXNNPACK_ENABLE_MEMOPT=$(usex memopt ON OFF)
		-DXNNPACK_ENABLE_SPARSE=$(usex sparse ON OFF)
	)

	cmake_src_configure
}
