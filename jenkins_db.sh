#!/bin/bash
mysql -u jenkins -pcakephp_jenkins -e 'DROP DATABASE IF EXISTS skeleton_test; CREATE DATABASE skeleton_test';

