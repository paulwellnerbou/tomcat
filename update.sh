#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	majorVersion="${version%%-*}" # "6"
	suffix="${version#*-}" # "jre7"
	
	baseImage='java'
	case "$suffix" in
		jre*|jdk*)
			baseImage+=":${suffix:3}-${suffix:0:3}" # ":7-jre"
			;;
	esac
	
	fullVersion="$(curl -fsSL --compressed "https://www.apache.org/dist/tomcat/tomcat-$majorVersion/" | grep '<a href="v'"$majorVersion." | sed -r 's!.*<a href="v([^"/]+)/?".*!\1!' | sort -V | tail -1)"
	(
		set -x
		sed -ri '
			s/^(FROM) .*/\1 '"$baseImage"'/;
			s/^(ENV TOMCAT_MAJOR) .*/\1 '"$majorVersion"'/;
			s/^(ENV TOMCAT_VERSION) .*/\1 '"$fullVersion"'/;
		' "$version/Dockerfile"
	)
done
