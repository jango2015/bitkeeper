#!/bin/sh
#
# Copyright 1999-2006,2008-2016 BitMover, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# generate config settings for make

ms_env()
{
	gcc --version | grep -q cyg && {
		echo No Mingw GCC found, I quit.
		exit 1
	}

	XLIBS="/mingw/lib/CRT_noglob.o -lws2_32 -lole32 -luuid -lpsapi"
	CC="gcc -pipe -DWINVER=0x0500 -D_WIN32_WINNT=0x0500"
	LD="gcc -Wl,--stack,33554432"
}

test "X$CC" = X && CC=gcc
test "X$LD" = X && LD=$CC
test "X$RANLIB" = X && RANLIB=ranlib

case "X`uname -s`" in
    XCYGWIN*|XMINGW*)
	;;
    XDarwin)
	# Create fresh, clean path, prepending ccache
	eval `/usr/libexec/path_helper`
	;;
    *)	AR=/usr/ccs/bin
	GREP=/usr/xpg4/bin:/usr/xpg2/bin
	GNU=/opt/gnu/bin:/usr/local/bin:/usr/gnu/bin:/usr/freeware/bin
	PATH=${GREP}:/bin:/usr/bin:/usr/bsd:${GNU}:${AR}:/usr/bin/X11
	export PATH
	;;
esac
case "X`uname -s`" in
	XAIX)	CCXTRA="-DHAVE_LOCALZONE -DNOPROC -mminimal-toc"
		;;
	XCYGWIN*|XMINGW*)
		ms_env;
		;;
	XDarwin)
		CC=gcc
		LD=gcc
		CCXTRA="-Qunused-arguments -DHAVE_GMTOFF -DNOPROC -no-cpp-precomp"
		XLIBS="-lresolv"
		;;
	XFreeBSD)
		CCXTRA="-DNOPROC -DHAVE_GMTOFF"
		;;
	XHP-UX)
		CCXTRA="-Dhpux -DNOPROC"
		;;
	XIRIX*)
		CCXTRA="-DHAVE_LOCALZONE -DNOPROC"
		RANLIB="touch"
		;;
	XLinux) CCXTRA=-DHAVE_GMTOFF
		test "x`uname -m`" = xx86_64 && {
			PATH=/usr/gnu/bin:$PATH
			export PATH
		}
		;;
	XNetBSD)
		CC=gcc
		LD=gcc
		PATH="/usr/local/bin:${PATH}"
		CCXTRA="-DHAVE_GMTOFF -DNOPROC -DRLIMIT_DEFAULT_SUCKS"
		;;
	XOpenBSD)
		CCXTRA="-DHAVE_GMTOFF -DNOPROC"
		;;
	XSCO_SV)
		PATH="/usr/local/bin:${PATH}"
		XLIBS="-lsocket"
		CCXTRA="-DHAVE_LOCALZONE -DNOPROC"
		RANLIB="touch"
		;;
	XSunOS)	XLIBS="-lnsl -lsocket -lresolv"
		CCXTRA="-DHAVE_LOCALZONE -DNOPROC"
		test X`uname -p` = Xi386 && {
			CCXTRA="$CCXTRA -DLTC_NO_ASM"
		}
		;;
	*)
		CHECK=1
		;;
esac

if [ "$CHECK" ]; then
	# check to see if the system we're building on has tm_gmtoff,
	# or altzone/localzone
	#

	# then look for tm_gmtoff, and if that doesn't exist, altzone/localzone
	#
	echo "#include <time.h>" 	                   > $$.c
	echo "main() { struct tm *now; now->tm_gmtoff; }" >> $$.c

	if $CC -o $$ $$.c 1>/dev/null 2>/dev/null; then
		CCXTRA="$CCXTRA -DHAVE_GMTOFF"
	else
		echo "main() { extern int localzone, altzone;"  > $$.c
		echo "         localzone; altzone; }"          >> $$.c
		if $CC -o $$ $$.c 1>/dev/null 2>/dev/null; then
			CCXTRA="$CCXTRA -DHAVE_LOCALZONE"
		fi
	fi
	rm -f $$ $$.c
	test -d /proc || CCXTRA="$CCXTRA -DNOPROC"
fi

test -f /build/.static && BK_STATIC=YES
test -z "$BK_STATIC" || {
	# XXX - GCC static syntax, will need to be updated for others.
	LD="$LD -static"
	CC="$CC -static"
	export BK_STATIC
}


test "x$BK_VERBOSE_BUILD" != "x" && { echo V=1; }
echo PATH=$PATH
echo CC="$CC $CCXTRA"
echo LD=$LD
echo XLIBS=$XLIBS
echo RANLIB=$RANLIB