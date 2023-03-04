# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_11 )
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1 git-r3 python-single-r1 cmake cuda flag-o-matic

DESCRIPTION="(Forked) Tensors and Dynamic neural networks in Python"
HOMEPAGE="https://pytorch.org/"
EGIT_REPO_URI="https://github.com/Allen050329/pytorch-uvm.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

REQUIRED_USE=${PYTHON_REQUIRED_USE}
RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep 'dev-python/typing-extensions[${PYTHON_USEDEP}]')
"
DEPEND="${RDEPEND}
	$(python_gen_cond_dep '	dev-python/pyyaml[${PYTHON_USEDEP}]')
"
S="${WORKDIR}/pytorch"

src_prepare() {
	git clone --recursive "${EGIT_REPO_URI}" "${S}"
	filter-lto #bug 862672
	cmake_src_prepare
	pushd ${S}/csrc/jit/serialization || die
	flatc --cpp --gen-mutable --scoped-enums mobile_bytecode.fbs || die
	popd

	cd "${S}"
	eapply \
		"${FILESDIR}"/0002-Don-t-build-libtorch-again-for-PyTorch-1.7.1.patch \
		"${FILESDIR}"/pytorch-1.9.0-Change-library-directory-according-to-CMake-build.patch \
		"${FILESDIR}"/pytorch-global-dlopen.patch \
		"${FILESDIR}"/pytorch-1.7.1-torch_shm_manager.patch \
		"${FILESDIR}"/pytorch-1.13.0-setup.patch \
	# Set build dir for pytorch's setup
	sed -i \
		-e "/BUILD_DIR/s|build|/var/lib/caffe2/|" \
		tools/setup_helpers/env.py \
		|| die
	distutils-r1_src_prepare
}

src_configure() {
	if use cuda && [[ -z ${TORCH_CUDA_ARCH_LIST} ]]; then
		ewarn "WARNING: caffe2 is being built with its default CUDA compute capabilities: 3.5 and 7.0."
		ewarn "These may not be optimal for your GPU."
		ewarn ""
		ewarn "To configure caffe2 with the CUDA compute capability that is optimal for your GPU,"
		ewarn "set TORCH_CUDA_ARCH_LIST in your make.conf, and re-emerge caffe2."
		ewarn "For example, to use CUDA capability 7.5 & 3.5, add: TORCH_CUDA_ARCH_LIST=7.5,3.5"
		ewarn "For a Maxwell model GPU, an example value would be: TORCH_CUDA_ARCH_LIST=Maxwell"
		ewarn ""
		ewarn "You can look up your GPU's CUDA compute capability at https://developer.nvidia.com/cuda-gpus"
		ewarn "or by running /opt/cuda/extras/demo_suite/deviceQuery | grep 'CUDA Capability'"
	fi

	local mycmakeargs=(
		-DBUILD_CUSTOM_PROTOBUF=OFF
		-DBUILD_SHARED_LIBS=ON

		-DUSE_CCACHE=OFF
		-DUSE_CUDA=$(usex cuda)
		-DUSE_CUDNN=$(usex cuda)
		-DUSE_FAST_NVCC=$(usex cuda)
		-DTORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-3.5 7.0}"
		-DUSE_DISTRIBUTED=$(usex distributed)
		-DUSE_MPI=$(usex mpi)
		-DUSE_FAKELOWP=OFF
		-DUSE_FBGEMM=OFF # TODO
		-DUSE_FFMPEG=$(usex ffmpeg)
		-DUSE_GFLAGS=ON
		-DUSE_GLOG=ON
		-DUSE_GLOO=OFF
		-DUSE_KINETO=OFF # TODO
		-DUSE_LEVELDB=OFF
		-DUSE_MAGMA=OFF # TODO: In GURU as sci-libs/magma
		-DUSE_MKLDNN=OFF
		-DUSE_NCCL=OFF # TODO: NVIDIA Collective Communication Library
		-DUSE_NNPACK=$(usex nnpack)
		-DUSE_QNNPACK=$(usex qnnpack)
		-DUSE_XNNPACK=$(usex xnnpack)
		-DUSE_SYSTEM_XNNPACK=$(usex xnnpack)
		-DUSE_TENSORPIPE=$(usex tensorpipe)
		-DUSE_PYTORCH_QNNPACK=OFF
		-DUSE_NUMPY=$(usex numpy)
		-DUSE_OPENCL=$(usex opencl)
		-DUSE_OPENCV=$(usex opencv)
		-DUSE_OPENMP=$(usex openmp)
		-DUSE_ROCM=OFF # TODO
		-DUSE_SYSTEM_CPUINFO=ON
		-DUSE_SYSTEM_PYBIND11=ON
		-DUSE_UCC=OFF
		-DUSE_VALGRIND=OFF
		-DPYBIND11_PYTHON_VERSION="${EPYTHON#python}"
		-DPYTHON_EXECUTABLE="${PYTHON}"
		-DUSE_ITT=OFF
		-DUSE_SYSTEM_EIGEN_INSTALL=ON
		-DUSE_SYSTEM_PTHREADPOOL=ON
		-DUSE_SYSTEM_FXDIV=ON
		-DUSE_SYSTEM_FP16=ON
		-DUSE_SYSTEM_GLOO=ON
		-DUSE_SYSTEM_ONNX=ON
		-DUSE_SYSTEM_SLEEF=ON

		-Wno-dev
		-DTORCH_INSTALL_LIB_DIR="${EPREFIX}"/usr/$(get_libdir)
		-DLIBSHM_INSTALL_LIB_SUBDIR="${EPREFIX}"/usr/$(get_libdir)
	)

	if use cuda; then
		addpredict "/dev/nvidiactl" # bug 867706

		mycmakeargs+=(
			-DCMAKE_CUDA_FLAGS="$(cuda_gccdir -f | tr -d \")"
		)
	fi
	cmake_src_configure
}

src_compile() {
	PYTORCH_BUILD_NUMBER=0 \
	USE_SYSTEM_LIBS=ON \
	CMAKE_BUILD_DIR="${BUILD_DIR}" \
	BUILD_DIR= \
	distutils-r1_src_compile
}

src_install() {
	cmake_src_install

	insinto "/var/lib/caffe2"
	doins "${BUILD_DIR}"/CMakeCache.txt

	rm -rf python
	mkdir -p python/torch/include || die
	mv "${ED}"/usr/lib/python*/site-packages/caffe2 python/ || die
	mv "${ED}"/usr/include/torch python/torch/include || die
	cp torch/version.py python/torch/ || die
	rm -r "${ED}"/var/tmp || die
	python_domodule python/caffe2
	python_domodule python/torch

        insinto "/var/lib/pytorch"
        doins "${BUILD_DIR}"/CMakeCache.txt
}
