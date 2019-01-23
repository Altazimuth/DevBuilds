#!/bin/bash
# shellcheck disable=SC2155

gzdoom_configure() {
	#declare -n Config=$1
	shift
	declare ProjectDir=$1
	shift
	declare Arch=$1
	shift

	declare -a CMakeArgs=()
	cmake_config_init CMakeArgs
	cmake_vs_cflags CMakeArgs
	CMakeArgs+=(
		'-DZDOOM_GENERATE_MAPFILE=ON'
	)

	case "$Arch" in
	x64)
		CMakeArgs+=(
			'-GVisual Studio 15 2017 Win64'
		)
		;;
	x86)
		CMakeArgs+=(
			'-GVisual Studio 15 2017'
			'-Tv141_xp'
		)
		;;
	esac

	cmake "$ProjectDir" "${CMakeArgs[@]}"
}

gzdoom_package() {
	declare -n Config=$1
	shift
	#declare ProjectDir=$1
	shift
	declare Version=$1
	shift
	declare -n Artifacts=$1
	shift

	declare Arch
	for Arch in ${Config[multiarch]}; do
		(
			declare DepsDir=$(lookup_build_dir "GZDoom-Deps-$Arch")

			cd "$Arch/Release" &&
			7z a "../../gzdoom-$Arch-$Version.7z" \
				./*.exe ./*.pk3 soundfonts/* fm_banks/* \
				"$DepsDir"/*.dll \
				-mx=9 &&
			7z a "../../gzdoom-$Arch-$Version.map.bz2" gzdoom.map -mx=9
		) &&
		Artifacts+=("gzdoom-$Arch-$Version.7z" "gzdoom-$Arch-$Version.map.bz2")
	done
}

# shellcheck disable=SC2034
declare -A GZDoomWin=(
	[branch]='master'
	[build]=cmake_generic_build
	[configure]=gzdoom_configure
	[multiarch]='x64 x86'
	[outoftree]=1
	[package]=gzdoom_package
	[project]='GZDoom'
	[remote]='https://github.com/coelckers/gzdoom.git'
	[uploaddir]=gzdoom
	[vcs]=GitVCS
)
register_build GZDoomWin

# shellcheck disable=SC2034
declare -A GZDoomLegacyWin=(
	[branch]='legacy'
	[build]=cmake_generic_build
	[configure]=gzdoom_configure
	[multiarch]='x64 x86'
	[outoftree]=1
	[package]=gzdoom_package
	[project]='GZDoomLegacy'
	[remote]='https://github.com/drfrag666/gzdoom.git'
	[uploaddir]=gzdoom-vintage
	[vcs]=GitVCS
)
register_build GZDoomLegacyWin

# libmpg123 isn't distributed with it's MinGW deps and libsndfile is distributed
# in an installer. Additionally we want to provide fluidsynth which isn't
# provided in binary form by upstream, so it's easiest to just pull a GZDoom
# release as the source for dependencies.
gzdoom_null() {
	:
}

gzdoom_deps_configure() {
	declare -n Config=$1
	shift
	#declare ProjectDir=$1
	shift
	#declare Arch=$1
	shift

	declare Image=${Config[remote]##*/}
	7z x "$Image" '*.dll'
}

# shellcheck disable=SC2034
declare -A GZDoomDepsWin32=(
	[branch]=''
	[build]=gzdoom_null
	[configure]=gzdoom_deps_configure
	[multiarch]='all'
	[outoftree]=0
	[package]=gzdoom_null
	[project]='GZDoom-Deps-x86'
	[remote]='https://zdoom.org/files/gzdoom/bin/gzdoom-bin-3-7-2.zip'
	[uploaddir]=''
	[vcs]=DownloadVCS
)
register_dep GZDoomDepsWin32

# shellcheck disable=SC2034
declare -A GZDoomDepsWin64=(
	[branch]=''
	[build]=gzdoom_null
	[configure]=gzdoom_deps_configure
	[multiarch]='all'
	[outoftree]=0
	[package]=gzdoom_null
	[project]='GZDoom-Deps-x64'
	[remote]='https://zdoom.org/files/gzdoom/bin/gzdoom-bin-3-7-2-x64.zip'
	[uploaddir]=''
	[vcs]=DownloadVCS
)
register_dep GZDoomDepsWin64