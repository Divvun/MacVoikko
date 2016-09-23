#!/bin/sh

ROOT="$(pwd)"
SDKHOME=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
MACOSTARGET=10.12
SDKNAME=MacOSX${MACOSTARGET}.sdk
SDK=${SDKHOME}/${SDKNAME}

# set by Xcode, causes conflicts
unset PROJECT

export PKG_CONFIG_PATH="$ROOT/build/lib/pkgconfig"

echo "\n** Building libarchive **\n"

if [[ ! -f build/lib/libarchive.dylib ]]; then
	cd libarchive
	[[ -f configure ]] || ./build/autogen.sh
	# Disable some things that aren't included in OS X but might have been installed by Homebrew
	./configure \
			--prefix="$ROOT/build" \
			--enable-silent-rules \
			--without-bz2lib \
			--without-lzmadec \
			--without-iconv \
			--without-lzo2 \
			--without-nettle \
			--without-openssl \
			--without-xml2 \
			--without-expat \
			--with-lzma \
			--with-zlib \
			--disable-bsdcpio \
			--disable-bsdtar \
			--with-sysroot=$ROOT/build \
    		CPPFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
    		LDFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
    		CFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
    		CXXFLAGS=" -I$ROOT/build/include -L$ROOT/build/lib" \
    		PKG_CONFIG_PATH=$ROOT/build/lib/pkgconfig
	make all install -j
	cd "$ROOT"
	install_name_tool -id @rpath/libarchive.dylib build/lib/libarchive.13.dylib
	install_name_tool -id @rpath/libarchive.dylib build/lib/libarchive.dylib
fi

echo "\n** Building TinyXML2 **\n"

if [[ ! -f build/lib/libtinyxml2.dylib ]]; then
	mkdir -p tinyxml2-build && cd tinyxml2-build
	cmake -DCMAKE_INSTALL_PREFIX="$ROOT/build" \
		  -DCMAKE_MACOSX_RPATH=ON \
		  -DCMAKE_OSX_SYSROOT=${SDK} \
		  -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSTARGET} \
		  ../tinyxml2
	make all install -j
	cd "$ROOT"
fi

echo "\n** Building hfst-ospell **\n"

if [[ ! -f build/lib/libhfstospell.dylib ]]; then
	mkdir -p hfst-ospell-build
	cd hfst-ospell
	[[ -f configure ]] || ./autogen.sh
	cd $ROOT/hfst-ospell-build
	../hfst-ospell/configure \
				--prefix="$ROOT/build" \
				--enable-zhfst \
				--enable-silent-rules \
				--disable-extra-demos \
				--disable-hfst-ospell-office \
				--with-tinyxml2=$ROOT/build/lib \
				--without-libxmlpp \
				--with-sysroot=$ROOT/build \
				PKG_CONFIG_PATH=$ROOT/build/lib/pkgconfig
	make all install -j
	cd "$ROOT"
	install_name_tool -id @rpath/libhfstospell.dylib build/lib/libhfstospell.7.dylib
	install_name_tool -id @rpath/libhfstospell.dylib build/lib/libhfstospell.dylib
#	# Hack to work around configure picking libraries from macports instead of local ones:
	for i in $(otool -L build/lib/libhfstospell.dylib | fgrep '/opt/local/lib' \
				| cut -f2 | cut -d' ' -f1); do
		target=$(basename $i)
		install_name_tool -change $i /usr/lib/$target build/lib/libhfstospell.dylib
	done
#	install_name_tool -delete_rpath /usr/lib/libicuuc.55.dylib build/lib/libhfstospell.7.dylib
#	install_name_tool -delete_rpath /usr/lib/libicudata.55.dylib build/lib/libhfstospell.7.dylib
fi

echo "\n** Building libvoikko **\n"

if [[ ! -f build/lib/libvoikko.dylib ]]; then
	mkdir -p libvoikko-build
	cd corevoikko/libvoikko
	[[ -f configure ]] || ./autogen.sh
	cd $ROOT/libvoikko-build
	# Look in both /usr/local/[share|lib]/voikko and /Library/Spelling/voikko for dictionaries
	../corevoikko/libvoikko/configure \
		--prefix="$ROOT/build" \
		--enable-silent-rules \
		--with-dictionary-path="/Library/Spelling/voikko:/usr/local/share/voikko:/usr/local/lib/voikko" \
		--with-sysroot=$ROOT/build \
		PKG_CONFIG_PATH=$ROOT/build/lib/pkgconfig
	make all install V=1
	cd "$ROOT"
	install_name_tool -id @rpath/libvoikko.dylib build/lib/libvoikko.1.dylib
	install_name_tool -id @rpath/libvoikko.dylib build/lib/libvoikko.dylib
#	# Hack to work around configure picking libraries from macports instead of local ones:
#	for i in $(otool -L build/lib/libvoikko.dylib | fgrep '/opt/local/lib' \
#				| cut -f2 | cut -d' ' -f1); do
#		target=$(basename $i)
#		cp $i build/lib/$target
#		install_name_tool -change $i @rpath/$target build/lib/libvoikko.dylib
#	done
	install_name_tool -change libarchive.14.dylib @rpath/libarchive.14.dylib build/lib/libvoikko.dylib
	install_name_tool -change @rpath/libtinyxml2.3.dylib @rpath/libtinyxml2.3.0.0.dylib build/lib/libvoikko.dylib
fi
