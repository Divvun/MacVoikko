#!/bin/sh

ROOT="$PWD"
SDKHOME=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
MACOSTARGET=10.11
SDKNAME=MacOSX${MACOSTARGET}.sdk
SDK=${SDKHOME}/${SDKNAME}

# set by Xcode, causes conflicts
unset PROJECT

export PKG_CONFIG_PATH="$ROOT/build/lib/pkgconfig"

echo "\n** Building libarchive **\n"

if [[ ! -d libarchive-build ]]; then
	mkdir libarchive-build && cd libarchive-build
	# Disable some things that aren't included in OS X but might have been installed by Homebrew
	cmake -DCMAKE_INSTALL_PREFIX="$ROOT/build" \
		  -DENABLE_NETTLE=OFF \
		  -DENABLE_LZMA=OFF \
		  -DENABLE_ACL=OFF \
		  -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
		  -DCMAKE_OSX_SYSROOT=${SDK} \
		  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSTARGET} \
		  ../libarchive
	make all install
	cd "$ROOT"
	install_name_tool -id @rpath/libarchive.dylib build/lib/libarchive.14.dylib
	install_name_tool -id @rpath/libarchive.dylib build/lib/libarchive.dylib
fi

echo "\n** Building TinyXML2 **\n"

if [[ ! -d tinyxml2-build ]]; then
	mkdir tinyxml2-build && cd tinyxml2-build
	cmake -DCMAKE_INSTALL_PREFIX="$ROOT/build" \
		  -DCMAKE_MACOSX_RPATH=ON \
		  -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
		  -DCMAKE_OSX_SYSROOT=${SDK} \
		  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSTARGET} \
		  ../tinyxml2
	make all install
	cd "$ROOT"
fi

echo "\n** Building hfst-ospell **\n"

if [[ ! -f build/lib/libhfstospell.dylib ]]; then
	cd hfst-ospell
	[[ -f configure ]] || ./autogen.sh
	./configure --prefix="$ROOT/build" --enable-zhfst \
				--with-tinyxml2=$ROOT/tinyxml2-build/ \
				--without-libxmlpp \
				CPPFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
				LDFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
				CFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
				CXXFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
				PKG_CONFIG_PATH=$ROOT/build/lib/pkgconfig
	make all install
	cd "$ROOT"
	install_name_tool -id @rpath/libhfstospell.dylib build/lib/libhfstospell.6.dylib
	install_name_tool -id @rpath/libhfstospell.dylib build/lib/libhfstospell.dylib
	# Hack to work around configure picking libraries from macports instead of local ones:
	for i in $(otool -L build/lib/libhfstospell.dylib | fgrep '/opt/local/lib' \
				| cut -f2 | cut -d' ' -f1); do
		target=$(basename $i)
		cp $i build/lib/$target
		install_name_tool -change $i @rpath/$target build/lib/libhfstospell.dylib
	done
fi

echo "\n** Building libvoikko **\n"

if [[ ! -f build/lib/libvoikko.dylib ]]; then
	cd corevoikko/libvoikko
	[[ -f configure ]] || ./autogen.sh
	# Look in both /usr/local/lib/voikko and /Library/Spelling/voikko for dictionaries
	./configure --prefix="$ROOT/build" \
	   --with-dictionary-path="/Library/Spelling/voikko:/usr/local/share/voikko:/usr/local/lib/voikko"
	make all install
	cd "$ROOT"
	install_name_tool -id @rpath/libvoikko.dylib build/lib/libvoikko.1.dylib
	install_name_tool -id @rpath/libvoikko.dylib build/lib/libvoikko.dylib
	# Hack to work around configure picking libraries from macports instead of local ones:
	for i in $(otool -L build/lib/libvoikko.dylib | fgrep '/opt/local/lib' \
				| cut -f2 | cut -d' ' -f1); do
		target=$(basename $i)
		cp $i build/lib/$target
		install_name_tool -change $i @rpath/$target build/lib/libvoikko.dylib
	done
	install_name_tool -change libarchive.14.dylib @rpath/libarchive.14.dylib build/lib/libvoikko.dylib
	install_name_tool -change @rpath/libtinyxml2.3.dylib @rpath/libtinyxml2.3.0.0.dylib build/lib/libvoikko.dylib
fi

echo "\n** Building suomimalaga **\n"

which malmake 2>&1 > /dev/null
if [[ $? -eq 0 ]]; then
	cd corevoikko/suomimalaga
	make voikko
	make voikko-install DESTDIR="$ROOT/../Dictionaries"
	cd "$ROOT"
else
	echo "Malaga not installed. Using prebuilt dictionaries"
fi
