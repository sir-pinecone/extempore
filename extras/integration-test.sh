#!/usr/bin/env bash

cd .. # move up one level into top-level extempore directory
SRC_DIR=$PWD

if [ ! -f $SRC_DIR/extras/integration-test.sh ]; then
    echo -e "\033[0;31mError:\033[0;00m integration-test.sh must be run from inside the extras/ directory"
    exit 1
fi

TEST_DIR=/tmp/extempore-integration-test
# port to run the Extempore primary process on
TEST_PORT=17097

if [ ! -d $TEST_DIR ]; then
    mkdir $TEST_DIR
fi

cd $TEST_DIR

echo "Running tests in ${TEST_DIR}..."

# without MCJIT

cmake -DCMAKE_INSTALL_PREFIX=$TEST_DIR -DCMAKE_BUILD_TYPE=Release -DMCJIT=OFF $SRC_DIR && make clean && make && make install && $TEST_DIR/bin/extempore --port=${TEST_PORT} --sharedir $TEST_DIR/share/extempore --run tests/all.xtm

if (($? != 0)); then
    echo -e "\033[0;31mIntegration test failed (AOT:false, MCJIT:false) $f\033[0;00m"
    echo
    exit 1
fi

# aot-compile the stdlib, then run all the tests again

make aot_stdlib && $TEST_DIR/bin/extempore --port=${TEST_PORT} --sharedir $TEST_DIR/share/extempore --run tests/all.xtm

if (($? != 0)); then
    echo -e "\033[0;31mIntegration test failed (AOT:true, MCJIT:false) $f\033[0;00m"
    echo
    exit 1
fi

# repeat the above steps, this time with MCJIT

cmake -DCMAKE_INSTALL_PREFIX=$TEST_DIR -DCMAKE_BUILD_TYPE=Release -DMCJIT=ON $SRC_DIR && make clean && make && make install && $TEST_DIR/bin/extempore --port=${TEST_PORT} --sharedir $TEST_DIR/share/extempore --run tests/all.xtm

if (($? != 0)); then
    echo -e "\033[0;31mIntegration test failed (AOT:false, MCJIT:true) $f\033[0;00m"
    echo
    exit 1
fi

make aot_stdlib && $TEST_DIR/bin/extempore --port=${TEST_PORT} --sharedir $TEST_DIR/share/extempore --run tests/all.xtm

if (($? != 0)); then
    echo -e "\033[0;31mIntegration test failed (AOT:true, MCJIT:true) $f\033[0;00m"
    echo
    exit 1
else
    echo -e "\033[0;32mAll integration tests passed\033[0;00m"
    echo
    exit 0
fi