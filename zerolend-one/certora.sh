#!/bin/bash
certoraRun test/certora/confs/ERC20.conf
certoraRun test/certora/confs/Pool.conf --optimistic_loop
