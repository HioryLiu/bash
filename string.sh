#!/bin/bash -eu

string="runoob is a great company"
echo `expr index "$string" is`  # 输出 8

array=("$string" 'liudong' 'last')
echo ${array[0]}
echo ${#array[@]}
echo $#
echo $$
echo $?
echo $*