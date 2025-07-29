#!/bin/bash

# Script to install NDK into AndroidIDE
# Author MrIkso - Modified by THToufique

install_dir=$HOME
sdk_dir=$install_dir/android-sdk
cmake_dir=$sdk_dir/cmake
ndk_base_dir=$sdk_dir/ndk

ndk_dir=""
ndk_ver=""
ndk_ver_name=""
ndk_file_name=""
ndk_installed=false
cmake_installed=false
is_lzhiyong_ndk=false
is_musl_ndk=false

# Install aria2c if missing
if ! command -v aria2c >/dev/null 2>&1; then
	echo "aria2c not found. Installing for faster downloads..."
	pkg install -y aria2
fi

run_install_cmake() {
	download_cmake 3.10.2
	download_cmake 3.18.1
	download_cmake 3.22.1
	download_cmake 3.25.1
}

download_cmake() {
	cmake_version=$1
	cmake_file="cmake-$cmake_version-android-aarch64.zip"
	echo "Downloading cmake-$cmake_version..."

	if [ -f "$cmake_file" ]; then
		echo "File $cmake_file already exists. Skipping download."
	else
		if command -v aria2c >/dev/null 2>&1; then
			echo "Using aria2c to download cmake..."
			aria2c -x 16 -s 16 --timeout=30 --max-tries=5 --continue=true "https://github.com/MrIkso/AndroidIDE-NDK/releases/download/cmake/$cmake_file" || {
				echo "❌ Failed to download cmake using aria2c."
				exit 1
			}
		else
			echo "Using wget to download cmake..."
			wget "https://github.com/MrIkso/AndroidIDE-NDK/releases/download/cmake/$cmake_file" --tries=5 --timeout=30 --no-verbose --show-progress -N || {
				echo "❌ Failed to download cmake using wget."
				exit 1
			}
		fi
	fi

	installing_cmake "$cmake_version"
}

download_ndk() {
	echo "Downloading NDK $1..."
	if [ -f "$1" ]; then
		echo "File $1 already exists. Skipping download."
		return
	fi

	if command -v aria2c >/dev/null 2>&1; then
		echo "Using aria2c to download..."
		aria2c -x 16 -s 16 --timeout=30 --max-tries=5 --continue=true "$2" || {
			echo "❌ Failed to download NDK using aria2c."
			exit 1
		}
	else
		echo "Using wget to download..."
		wget "$2" --tries=5 --timeout=30 --no-verbose --show-progress -N || {
			echo "❌ Failed to download NDK using wget."
			exit 1
		}
	fi
}

fix_ndk() {
	if [ -d "$ndk_dir" ]; then
		echo "Creating missing links..."
		cd "$ndk_dir"/toolchains/llvm/prebuilt || exit
		ln -s linux-aarch64 linux-x86_64
		cd "$ndk_dir"/prebuilt || exit
		ln -s linux-aarch64 linux-x86_64
		cd "$install_dir" || exit

		echo "Patching cmake configs..."
		sed -i 's/if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)/if(CMAKE_HOST_SYSTEM_NAME STREQUAL Android)\nset(ANDROID_HOST_TAG linux-aarch64)\nelseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)/g' "$ndk_dir"/build/cmake/android-legacy.toolchain.cmake
		sed -i 's/if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)/if(CMAKE_HOST_SYSTEM_NAME STREQUAL Android)\nset(ANDROID_HOST_TAG linux-aarch64)\nelseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)/g' "$ndk_dir"/build/cmake/android.toolchain.cmake
		ndk_installed=true
	else
		echo "NDK does not exist."
	fi
}

fix_ndk_musl() {
	if [ -d "$ndk_dir" ]; then
		echo "Creating missing links..."
		cd "$ndk_dir"/toolchains/llvm/prebuilt || exit
		ln -s linux-arm64 linux-aarch64
		cd "$ndk_dir"/prebuilt || exit
		ln -s linux-arm64 linux-aarch64
		cd "$ndk_dir"/shader-tools || exit
		ln -s linux-arm64 linux-aarch64 
		ndk_installed=true
	else
		echo "NDK does not exist."
	fi
}

installing_cmake() {
	cmake_version=$1
	cmake_file="cmake-$cmake_version-android-aarch64.zip"
	if [ -f "$cmake_file" ]; then
		echo "Unzipping cmake..."
		unzip -qq "$cmake_file" -d "$cmake_dir"
		rm "$cmake_file"
		chmod -R +x "$cmake_dir/$cmake_version/bin"
		cmake_installed=true
	else
		echo "$cmake_file does not exist."
	fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NDK ━━━ Starting NDK installation ━━━"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Now You'll be asked about which version of NDK to install"
echo "If your Android Version is 9 or above then choose '9'"
echo "If your Android Version is below 9 or if you faced issues with '9' (A9 and above users) then choose '8'"
echo "If you're choosing other options then you're on your own ¯\\_(ಠ_ಠ)_/¯"
echo

select item in r17c r18b r19c r20b r21e r22b r23b r24 r26b r27b r27c r28b r29-beta1 Quit; do
	case $item in
	"r17c") ndk_ver="17.2.4988734"; ndk_ver_name="r17c"; break ;;
	"r18b") ndk_ver="18.1.5063045"; ndk_ver_name="r18b"; break ;;
	"r19c") ndk_ver="19.2.5345600"; ndk_ver_name="r19c"; break ;;
	"r20b") ndk_ver="20.1.5948944"; ndk_ver_name="r20b"; break ;;
	"r21e") ndk_ver="21.4.7075529"; ndk_ver_name="r21e"; break ;;
	"r22b") ndk_ver="22.1.7171670"; ndk_ver_name="r22b"; break ;;
	"r23b") ndk_ver="23.2.8568313"; ndk_ver_name="r23b"; break ;;
	"r24") ndk_ver="24.0.8215888"; ndk_ver_name="r24"; break ;;
	"r26b") ndk_ver="26.1.10909125"; ndk_ver_name="r26b"; is_lzhiyong_ndk=true; break ;;
	"r27b") ndk_ver="27.1.12297006"; ndk_ver_name="r27b"; is_lzhiyong_ndk=true; break ;;
	"r27c") ndk_ver="27.2.12479018"; ndk_ver_name="r27c"; is_musl_ndk=true; break ;;
	"r28b") ndk_ver="28.1.13356709"; ndk_ver_name="r28b"; is_musl_ndk=true; break ;;
	"r29-beta1") ndk_ver="29.0.13113456"; ndk_ver_name="r29-beta1"; is_musl_ndk=true; break ;;
	"Quit") echo "Exit.."; exit ;;
	*) echo "Invalid option" ;;
	esac
done

echo "Selected version: $ndk_ver_name ($ndk_ver)"
echo "Warning! This NDK is for aarch64 only."
cd "$install_dir" || exit

ndk_dir="$ndk_base_dir/$ndk_ver"
if [[ $is_musl_ndk == true ]]; then
	ndk_file_name="android-ndk-$ndk_ver_name-aarch64-linux-musl.tar.xz"
else
	ndk_file_name="android-ndk-$ndk_ver_name-aarch64.zip"
fi

# Clean previous install
[ -d "$ndk_dir" ] && echo "Removing existing $ndk_dir..." && rm -rf "$ndk_dir"
[ -d "$cmake_dir/3.10.2" ] && rm -rf "$cmake_dir/3.10.2"
[ -d "$cmake_dir/3.18.1" ] && rm -rf "$cmake_dir/3.18.1"
[ -d "$cmake_dir/3.22.1" ] && rm -rf "$cmake_dir/3.22.1"
[ -d "$cmake_dir/3.25.1" ] && rm -rf "$cmake_dir/3.25.1"

# Download NDK
if [[ $is_musl_ndk == true ]]; then
	download_ndk "$ndk_file_name" "https://github.com/HomuHomu833/android-ndk-custom/releases/download/$ndk_ver_name/$ndk_file_name"
elif [[ $is_lzhiyong_ndk == true ]]; then
	download_ndk "$ndk_file_name" "https://github.com/MrIkso/AndroidIDE-NDK/releases/download/ndk/$ndk_file_name"
else
	download_ndk "$ndk_file_name" "https://github.com/jzinferno2/termux-ndk/releases/download/v1/$ndk_file_name"
fi

# Extract NDK
if [ -f "$ndk_file_name" ]; then
	echo "Extracting NDK $ndk_ver_name..."
	if [[ $is_musl_ndk == true ]]; then
		tar --no-same-owner -xf "$ndk_file_name" --warning=no-unknown-keyword
	else
		unzip -qq "$ndk_file_name"
	fi
	rm "$ndk_file_name"

	if [ ! -d "$ndk_base_dir" ]; then
		echo "Creating NDK base directory..."
		mkdir -p "$ndk_base_dir"
	fi
	mv android-ndk-$ndk_ver_name "$ndk_dir"

	if [[ $is_musl_ndk == true ]]; then
		fix_ndk_musl
	elif [[ $is_lzhiyong_ndk == false ]]; then
		fix_ndk
	else
		ndk_installed=true
	fi
else
	echo "❌ $ndk_file_name not found after download."
fi

# Install cmake
mkdir -p "$cmake_dir"
cd "$cmake_dir" || exit
run_install_cmake

# Final check
if [[ $ndk_installed == true && $cmake_installed == true ]]; then
	echo '✅ Installation complete! Please restart AndroidIDE.'
else
	echo '❌ Installation failed. Please check logs.'
fi
