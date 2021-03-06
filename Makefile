# Makefile for a standard golang repo with associated container

##### These variables need to be adjusted in most repositories #####

# This repo's root import path (under GOPATH).
#PKG := github.com/drud/docker.nginx-php-fpm

# Docker repo for a push
DOCKER_REPO ?= drud/nginx-php-fpm7-local

# Upstream repo used in the Dockerfile
NGINX_LOCAL_UPSTREAM_FPM7_REPO_TAG ?= v0.4.2
UPSTREAM_REPO ?= drud/nginx-php-fpm7:$(NGINX_LOCAL_UPSTREAM_FPM7_REPO_TAG)

# Top-level directories to build
#SRC_DIRS := filexs drudapi secrets utils

# Optional to docker build
DOCKER_ARGS = --build-arg MAILHOG_VERSION=0.2.1

# VERSION can be set by
  # Default: git tag
  # make command line: make VERSION=0.9.0
# It can also be explicitly set in the Makefile as commented out below.

# This version-strategy uses git tags to set the version string
# VERSION can be overridden on make commandline: make VERSION=0.9.1 push
VERSION := $(shell git describe --tags --always --dirty)
#
# This version-strategy uses a manual value to set the version string
#VERSION := 1.2.3

# Each section of the Makefile is included from standard components below.
# If you need to override one, import its contents below and comment out the
# include. That way the base components can easily be updated as our general needs
# change.
#include ../build-tools/makefile_components/base_build_go.mak
include build-tools/makefile_components/base_build_python-docker.mak
include build-tools/makefile_components/base_container.mak
include build-tools/makefile_components/base_push.mak
#include build-tools/makefile_components/base_test_go.mak
#include build-tools/makefile_components/base_test_python.mak

test: container
	@docker stop web-local-test || true
	@docker rm web-local-test || true
	docker run -p 1081:80 -e "DOCROOT=docroot" -d --name web-local-test -d `awk '{print $$1}' .docker_image`
	CONTAINER_NAME=web-local-test test/containercheck.sh
	docker exec -it web-local-test php --version | grep "PHP 7"
	curl -s localhost:1081/test/test-email.php | grep "Test email sent"
	@docker stop web-local-test && docker rm web-local-test
	docker run -p 1081:80 -e "DOCROOT=potato" -v `pwd`/test/test-custom.conf:/var/www/html/.ddev/nginx-site.conf -d --name web-local-test -d `awk '{print $$1}' .docker_image`
	docker exec -it web-local-test cat /etc/nginx/sites-available/nginx-site.conf | grep "docroot is /var/www/html/potato in custom conf"
	@docker stop web-local-test && docker rm web-local-test
