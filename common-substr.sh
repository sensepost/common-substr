#!/bin/bash
# Find the most common substrings in any input text
# My intended use is for password lists
# Original idea from https://www.unix.com/302889669-post4.html?s=2268e5a250e5a7eada6116db1127b031
#
# by @singe

nocase=0
stats=1
strlen=32
threshold=0
# I use 32 as the length, since that's what hashcat -O's max is

function longusage() {
  echo "Common Substring Generator by @singe"
  echo "Usage: $0 [-hin] [-t <n>] [-l <n>] -f <filename>"
  echo "	-h|--help This help"
  echo "	-i|--insensitive Ignore case of substrings"
  echo "	-l|--length <n> Maximum length substring to look for. Default is $strlen."
  echo "	-n|--nostats Just print the substrings, no stats. Default is to include them."
  echo "	-t|--threshold <n> Only print substrings more prevalent than <n> percent."
  echo "	-f|--file <filename> The file to extract substrings from"
  echo "Default output (with stats) is tab separated: <percentage>	<count>	<substring>"
  echo "Sorted from most to least common"
  exit 1
}

function shortusage() {
  echo "Common Substring Generator by @singe"
  echo "Usage: $0 [-hin] [-l <n>] -f <filename>"
  exit 1
}

while getopts ":hinl:t:f:" OPTIONS; do
  case "$OPTIONS" in
    h|-help)
      longusage;;
    i|-insensitive)
      nocase=1;;
    n|-nostats)
      stats=0;;
    l|-length)
      strlen=${OPTARG};;
    t|-threshold)
      threshold=${OPTARG};;
    f|-file)
      filename=${OPTARG};;
    ?)
      shortusage;;
    esac
done
if [ $OPTIND -eq 1 ]; then
  shortusage
fi

LC_ALL=C awk -v strlen="$strlen" -v nocase="$nocase" -v stats="$stats" -v threshold="$threshold" '
NR > 0 {
  if(nocase)
    str = tolower($1)
  else
    str = $1
  if(length(str) < strlen)
    tmplen = length(str)
  else
    tmplen = strlen
  for(i = length(str); i >= 1; i--)
    for(j = tmplen; j > 1; j--)
      if(length(substr(str, i, j)) == j)
        subs[substr(str, i, j)]++
}
END {
  asorti(subs,wubs,"@val_num_desc")
  for(i in wubs)
    if(subs[wubs[i]] > 1)
      if(subs[wubs[i]]/NR*100 > threshold)
        if(stats)
          printf("%s\t%s\t%s\n", subs[wubs[i]]/NR*100, subs[wubs[i]], wubs[i])
        else
          printf("%s\n", wubs[i])
}' $filename
