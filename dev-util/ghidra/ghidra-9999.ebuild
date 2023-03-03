
# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit java-pkg-2 desktop git-r3

DESCRIPTION="A software reverse engineering framework"
HOMEPAGE="https://ghidra-sre.org/"
EGIT_REPO_URI="https://github.com/NationalSecurityAgency/ghidra.git"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

#FIXME:
# * QA Notice: Files built without respecting LDFLAGS have been detected
# *  Please include the following list of files in your report:
# * /usr/share/ghidra/GPL/DemanglerGnu/os/linux_x86_64/demangler_gnu_v2_24
# * /usr/share/ghidra/GPL/DemanglerGnu/os/linux_x86_64/demangler_gnu_v2_33_1
# * /usr/share/ghidra/Ghidra/Features/Decompiler/os/linux_x86_64/decompile
# * /usr/share/ghidra/Ghidra/Features/Decompiler/os/linux_x86_64/sleigh

#java-pkg-2 sets java based on RDEPEND so the java slot in rdepend is used to build
RDEPEND="virtual/jre:17"
DEPEND="${RDEPEND}
	virtual/jdk:17
	sys-devel/bison
	dev-java/jflex
	app-arch/unzip"
BDEPEND=">=dev-java/gradle-bin-7.3:*"

S="${WORKDIR}/ghidra-Ghidra_${PV}_build"
PROPERTIES+=" live"
pkg_setup() {
	java-pkg-2_pkg_setup
	# somehow this was unset on livecd run and it shouldn't be unset
	eselect gradle update ifunset
	gradle_link_target=$(readlink -n /usr/bin/gradle)
	currentver="${gradle_link_target/gradle-bin-/}"
	requiredver="7.3"
	unsupportedver="8.0"
	einfo "Gradle version ${currentver} currently set."
	if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
		einfo "Gradle version ${currentver} is >= ${requiredver}, proceeding with check..."
		if [ "$(printf '%s\n' "$unsupportedver" "$currentver" | sort -V | head -n1)" = "$currentver" ] && [ "$unsupportedver" != "$currentver" ]; then
	                einfo "Gradle version ${currentver} is < ${unsupportedver}, proceeding with build..."
	        else
	                eerror "Gradle version lower than ${unsupportedver} must be eselected before building ${PN}."
	                die "Please run 'eselect gradle set gradle-bin-XX' when XX is a version of gradle lower than ${unsupportedver}"
	        fi
	else
		eerror "Gradle version ${requiredver} or higher must be eselected before building ${PN}."
		die "Please run 'eselect gradle set gradle-bin-XX' when XX is a version of gradle higher than ${requiredver}"
	fi
}

src_unpack() {
	# https://github.com/NationalSecurityAgency/ghidra/blob/master/DevGuide.md
	git clone "${EGIT_REPO_URI}" "${S}"
	cd "${S}"

	#gradle dependencies download
	export _JAVA_OPTIONS="$_JAVA_OPTIONS -Duser.home=$HOME -Djava.io.tmpdir=${T}"
	GRADLE="gradle --gradle-user-home .gradle --console rich --parallel --max-workers $(nproc)"
	unset TERM

	${GRADLE} -I gradle/support/fetchDependencies.gradle init
	${GRADLE} buildGhidra || die
}

src_install() {
	#FIXME: it is easier to unpack existing archive for now
	dodir /usr/share
	unzip "build/dist/ghidra_*_DEV_*_linux_x86_64.zip" -d "${ED}"/usr/share/ghidra-container || die "unable to unpack dist zip"
	rm -rf "${ED}"/usr/share/ghidra/Extensions
	mv "${ED}"/usr/share/ghidra-container/* "${ED}"/usr/share/ghidra
	rm -rf "${ED}"/usr/share/ghidra-container

	#fixme: add doc flag
	rm -r  "${ED}"/usr/share/ghidra/docs/ || die "rm failed"
	dosym "${EPREFIX}"/usr/share/ghidra/ghidraRun /usr/bin/ghidra

	# icon
	doicon GhidraDocs/GhidraClass/Beginner/Images/GhidraLogo64.png
	# desktop entry
	make_desktop_entry ${PN} "Ghidra" /usr/share/pixmaps/GhidraLogo64.png "Utility"
}
