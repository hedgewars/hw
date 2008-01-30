# Ports collection makefile for:  hedgewars
# Date created:			  30 January 2008
# Whom:				  Andrey Korotaev <unC0Rr@gmail.com>
#
# $FreeBSD$
#

PORTNAME=	hedgewars
PORTVERSION=	0.9.2
PORTREVISION=	1
CATEGORIES=	games
MASTER_SITES=	http://www.hedgewars.org/download/
DISTNAME=	${PORTNAME}-src-${PORTVERSION}

MAINTAINER=	unC0Rr@gmail.com
COMMENT=	Turn-based Worms-like strategy game

USE_BZIP2=	yes
USE_SDL=	sdl image ttf mixer net
USE_QT_VER=	4
QT_COMPONENTS=	gui corelib network xml svg moc_build rcc_build

BUILD_DEPENDS+=	fpc:${PORTSDIR}/lang/fpc \
		${CMAKE}:${PORTSDIR}/devel/cmake

WRKSRC=		${WRKDIR}/${PORTNAME}-${PORTVERSION}

PLIST_FILES=	bin/hedgewars bin/hwengine

HAS_CONFIGURE=	yes

CMAKE?=		${LOCALBASE}/bin/cmake
CMAKE_ARGS=	-DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
		-DCMAKE_CXX_COMPILER:STRING="${CXX}" \
		-DCMAKE_CXX_FLAGS:STRING="${CXXFLAGS}"

do-configure:
	cd ${WRKSRC} && ${SETENV} ${CONFIGURE_ENV} ${CMAKE} ${CMAKE_ARGS} .

.include <bsd.port.mk>
