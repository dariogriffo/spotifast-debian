ARG DEBIAN_DIST=trixie
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG FASTPOTIFY_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG PACKAGE_DEPENDS=""
ARG PACKAGE_RECOMMENDS=""

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/fastpotify
RUN mkdir -p /output/usr/share/applications
RUN mkdir -p /output/usr/share/icons/hicolor/scalable/apps
RUN mkdir -p /output/DEBIAN

# build_debian.sh stages the extracted upstream archive as dist/$ARCH.
COPY dist/${ARCH}/fastpotify /output/usr/bin/fastpotify
COPY dist/${ARCH}/packaging/applications/fastpotify.desktop /output/usr/share/applications/fastpotify.desktop
COPY dist/${ARCH}/packaging/icons/fastpotify.svg /output/usr/share/icons/hicolor/scalable/apps/fastpotify.svg
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/fastpotify/
COPY output/changelog.Debian /output/usr/share/doc/fastpotify/
COPY output/README.md /output/usr/share/doc/fastpotify/

# Normalise permissions: files copied from the build host may carry group write
# bits, which dpkg-deb would preserve and lintian would flag.
RUN find /output/usr -type d -exec chmod 755 {} + \
 && find /output/usr -type f -exec chmod 644 {} + \
 && chmod 755 /output/usr/bin/fastpotify

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/fastpotify/changelog.Debian
# FULL_VERSION carries the architecture suffix used for the .deb filename;
# the changelog must show the package version instead.
RUN sed -i "s/FULL_VERSION/${FASTPOTIFY_VERSION}-${BUILD_VERSION}~${DEBIAN_DIST}/" /output/usr/share/doc/fastpotify/changelog.Debian
RUN gzip -9n /output/usr/share/doc/fastpotify/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/FASTPOTIFY_VERSION/$FASTPOTIFY_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control
RUN if [ -n "$PACKAGE_DEPENDS" ]; then \
        sed -i "s%^PACKAGE_DEPENDS$%Depends: $PACKAGE_DEPENDS%" /output/DEBIAN/control; \
    else \
        sed -i "/^PACKAGE_DEPENDS$/d" /output/DEBIAN/control; \
    fi
RUN if [ -n "$PACKAGE_RECOMMENDS" ]; then \
        sed -i "s%^PACKAGE_RECOMMENDS$%Recommends: $PACKAGE_RECOMMENDS%" /output/DEBIAN/control; \
    else \
        sed -i "/^PACKAGE_RECOMMENDS$/d" /output/DEBIAN/control; \
    fi

RUN dpkg-deb --build /output /fastpotify_${FULL_VERSION}.deb
