# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit cmake-utils eutils git-r3 linux-info systemd user

MY_PN="mediatomb"

DESCRIPTION="MediaTomb-v00d00 is an updated fork of MediaTomb"
HOMEPAGE="https://github.com/v00d00/mediatomb"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

EGIT_REPO_URI="https://github.com/v00d00/${MY_PN}.git"

IUSE="curl debug +exif +ffmpeg +javascript lastfm libav +magic mysql +taglib"

DEPEND="
	!!net-misc/mediatomb
	net-libs/libupnp:1.8
	>=dev-db/sqlite-3
	dev-libs/expat
	mysql? ( virtual/mysql )
	javascript? ( >=dev-lang/spidermonkey-1.8.5:0 )
	taglib? ( >=media-libs/taglib-1.11 )
	lastfm? ( >=media-libs/lastfmlib-0.4 )
	exif? ( media-libs/libexif )
	ffmpeg? (
		libav? ( >=media-video/libav-10:0= )
		!libav? ( >=media-video/ffmpeg-2.2:0= )
	)
	curl? ( net-misc/curl net-misc/youtube-dl )
	magic? ( sys-apps/file )
	sys-apps/util-linux
	sys-libs/zlib
	virtual/libiconvi
"
RDEPEND="${DEPEND}"

CONFIG_CHECK="~INOTIFY_USER"

pkg_setup() {
	linux-info_pkg_setup

	enewgroup ${MY_PN}
	enewuser ${MY_PN} -1 -1 /dev/null ${MY_PN}
}

src_configure() {
	local mycmakeargs=(
		-DWITH_CURL="$(usex curl)" \
		-DWITH_LOGGING=1 \
		-DWITH_DEBUG_LOGGING="$(usex debug)" \
		-DWITH_EXIF="$(usex exif)" \
		-DWITH_AVCODEC="$(usex ffmpeg)" \
		-DWITH_JS="$(usex javascript)" \
		-DWITH_LASTFM="$(usex lastfm)" \
		-DWITH_MAGIC="$(usex magic)" \
		-DWITH_MYSQL="$(usex mysql)"
	)

	cmake-utils_src_configure
}

src_install() {
	default

	systemd_dounit "${S}/scripts/systemd/${MY_PN}.service"
	use mysql && systemd_dounit "${S}/scripts/systemd/${PN}-mysql.service"

	newinitd "${FILESDIR}/${MY_PN}-0.12.1.initd" "${MY_PN}"
	use mysql || sed -i -e "/use mysql/d" "${ED}/etc/init.d/${MY_PN}"
	newconfd "${FILESDIR}/${MY_PN}-0.12.0.confd" "${MY_PN}"

	insinto /etc/${MY_PN}
	newins "${FILESDIR}/${MY_PN}-0.12.0.config" config.xml
	fperms 0600 /etc/${MY_PN}/config.xml
	fowners mediatomb:mediatomb /etc/${MY_PN}/config.xml

	keepdir /var/lib/${MY_PN}
	fowners ${MY_PN}:${MY_PN} /var/lib/${MY_PN}
}

pkg_postinst() {
	if use mysql ; then
		elog "MediaTomb has been built with MySQL support and needs"
		elog "to be configured before being started."
		elog "For more information, please consult the MediaTomb"
		elog "documentation: http://mediatomb.cc/pages/documentation"
		elog
	fi

	elog "To configure ${PN} edit:"
	elog "/etc/mediatomb/config.xml"
	elog
	elog "The MediaTomb web interface can be reached at (after the service is started):"
	elog "http://localhost:49152/"
}
