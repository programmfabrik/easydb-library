#!/bin/sh

l=/etc/apt/sources.list.d/stretch-backports.list
echo "deb  http://ftp.de.debian.org/debian  stretch-backports  main contrib non-free" > $l

apt-get update

cd /tmp
e=boost-dev-dummy
cat > $e << EOD
Section: misc
Priority: optional
Standards-Version: 3.9.2
Package: boost-dev-dummy
Depends: libboost1.67-dev
Provides: libboost-dev
Description: libboost1.67-dev from backports does not provide libboost-dev dependency
EOD

equivs-build $e

apt-get purge \
	libboost-atomic-dev libboost-atomic1.62-dev \
	libboost-chrono-dev libboost-chrono1.62-dev \
	libboost-context-dev libboost-context1.62-dev \
	libboost-coroutine-dev libboost-coroutine1.62-dev \
	libboost-date-time-dev libboost-date-time1.62-dev \
	libboost-exception-dev libboost-exception1.62-dev \
	libboost-fiber-dev libboost-fiber1.62-dev \
	libboost-filesystem-dev libboost-filesystem1.62-dev \
	libboost-graph-parallel-dev libboost-graph-parallel1.62-dev \
	libboost-graph-dev libboost-graph1.62-dev \
	libboost-iostreams-dev libboost-iostreams1.62-dev \
	libboost-locale-dev libboost-locale1.62-dev \
	libboost-log-dev libboost-log1.62-dev \
	libboost-math-dev libboost-math1.62-dev \
	libboost-mpi-dev libboost-mpi-python1.62-dev \
	libboost-mpi-python-dev libboost-mpi-python1.62.0 \
	libboost-mpi-dev libboost-mpi1.62-dev \
	libboost-program-options-dev libboost-program-options1.62-dev \
	libboost-python-dev libboost-python1.62-dev \
	libboost-random-dev libboost-random1.62-dev \
	libboost-regex-dev libboost-regex1.62-dev \
	libboost-serialization-dev libboost-serialization1.62-dev \
	libboost-signals-dev libboost-signals1.62-dev \
	libboost-system-dev libboost-system1.62-dev \
	libboost-test-dev libboost-test1.62-dev \
	libboost-thread-dev libboost-thread1.62-dev \
	libboost-timer-dev libboost-timer1.62-dev \
	libboost-type-erasure-dev libboost-type-erasure1.62-dev \
	libboost-wave-dev libboost-wave1.62-dev \
	libboost-dev libboost1.62-dev \
	libboost-tools-dev libboost1.62-tools-dev \
	libboost-all-dev \
	libyaml-cpp-dev

apt-get install -t stretch-backports \
	libboost1.67-dev \
	libboost1.67-all-dev \
	libboost1.67-tools-dev \
	libboost-atomic1.67-dev libboost-atomic1.67.0 \
	libboost-chrono1.67-dev libboost-chrono1.67.0 \
	libboost-container1.67-dev libboost-container1.67.0 \
	libboost-context1.67-dev libboost-context1.67.0 \
	libboost-coroutine1.67-dev libboost-coroutine1.67.0 \
	libboost-date-time1.67-dev libboost-date-time1.67.0 \
	libboost-exception1.67-dev \
	libboost-fiber1.67-dev libboost-fiber1.67.0 \
	libboost-filesystem1.67-dev libboost-filesystem1.67.0 \
	libboost-graph1.67-dev libboost-graph1.67.0 \
	libboost-graph-parallel1.67-dev libboost-graph-parallel1.67.0 \
	libboost-iostreams1.67-dev libboost-iostreams1.67.0 \
	libboost-locale1.67-dev libboost-locale1.67.0 \
	libboost-log1.67-dev libboost-log1.67.0 \
	libboost-math1.67-dev libboost-math1.67.0 \
	libboost-mpi1.67-dev libboost-mpi1.67.0 \
	libboost-mpi-python1.67-dev libboost-mpi-python1.67.0 \
	libboost-numpy1.67-dev libboost-numpy1.67.0 \
	libboost-program-options1.67-dev libboost-program-options1.67.0 \
	libboost-python1.67-dev libboost-python1.67.0 \
	libboost-random1.67-dev libboost-random1.67.0 \
	libboost-regex1.67-dev libboost-regex1.67.0 \
	libboost-serialization1.67-dev libboost-serialization1.67.0 \
	libboost-signals1.67-dev libboost-signals1.67.0 \
	libboost-stacktrace1.67-dev libboost-stacktrace1.67.0 \
	libboost-system1.67-dev libboost-system1.67.0 \
	libboost-test1.67-dev libboost-test1.67.0 \
	libboost-thread1.67-dev libboost-thread1.67.0 \
	libboost-timer1.67-dev libboost-timer1.67.0 \
	libboost-type-erasure1.67-dev libboost-type-erasure1.67.0 \
	libboost-wave1.67-dev libboost-wave1.67.0

dpkg -i boost-dev-dummy_1.0_all.deb

apt-get install libyaml-cpp-dev
