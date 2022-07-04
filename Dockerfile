FROM debian:bullseye  

RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
		ca-certificates \
		wget \
		gnupg \
	&& apt-get install --yes \
		bash-completion \
		curl \
		git \
		vim \
	&& apt-get clean \
	&& rm -rf \
		/var/lib/apt/lists/* \
		/tmp/* \
		/var/tmp/*
