#!/bin/bash
# Find the most common substrings in any input text
# My intended use is for password lists
# Original idea from https://www.unix.com/302889669-post4.html?s=2268e5a250e5a7eada6116db1127b031
#
# by @singe

nocase=0
stats=1
strmax=32 # I use 32 because it's hashcat -O's max
strmin=2
threshold=0
focus=0

function longusage() {
  echo "Common Substring Generator by @singe"
  echo "Usage: $0 [-hin] [-t <n>] [-l <n>] -f <filename>"
  echo "	-h|--help This help"
  echo "	-i|--insensitive Ignore case of substrings"
  echo "	-L|--maxlength <n> Maximum length substring to look for. Default is $strmax."
  echo "	-l|--minlength <n> Minimum length substring to look for. Default is $strmin."
  echo "	-n|--nostats Just print the substrings, no stats. Default is to include them."
  echo "	-t|--threshold <n> Only print substrings more prevalent than <n> percent."
  echo "	-f|--file <filename> The file to extract substrings from"
  echo "	-s|--suffix Only look at suffix substrings at the end of a string"
  echo "	-p|--prefix Only look at prefix substrings at the beginning of a string"
  echo "Default output (with stats) is tab separated: <percentage>	<count>	<substring>"
  echo "Sorted from most to least common"
  exit 1
}

function shortusage() {
  echo "Common Substring Generator by @singe"
  echo "Usage: $0 [-hin] [-l <n>] -f <filename>"
  exit 1
}

while getopts ":hinL:l:t:f:sp" OPTIONS; do
  case "$OPTIONS" in
    h|-help)
      longusage;;
    i|-insensitive)
      nocase=1;;
    n|-nostats)
      stats=0;;
    L|-maxlength)
      if [ ${OPTARG} -lt 1 ]; then
        echo "Strings have to be longer than 1"
        exit 1
      fi
      strmax=${OPTARG};;
    l|-minlength)
      if [ ${OPTARG} -lt 2 ]; then
        echo "String lengths of 1 or less usually aren't what you want. Are you sure?"
      fi
      strmin=${OPTARG};;
    t|-threshold)
      threshold=${OPTARG};;
    f|-file)
      filename=${OPTARG};;
    s|-suffix)
      focus=1;;
    p|-prefix)
      focus=2;;
    ?)
      shortusage;;
    esac
done
if [ $OPTIND -eq 1 ]; then
  shortusage
fi
if [ $strmin -gt $strmax ]; then
  echo "Your maximum string length is smaller than your minimum string length. This won't work."
  exit 1
fi

LC_ALL=C awk -v strmax="$strmax" -v strmin="$strmin" -v nocase="$nocase" -v stats="$stats" -v threshold="$threshold" -v focus="$focus" '
NR > 0 {
  if (nocase)
    str = tolower($1)
  else
    str = $1
  if (length(str) < strmax)
    maxlen = length(str)
  else
    maxlen = strmax
  if (focus == 0)
  {
    for (i = length(str); i >= 1; i--)
      for (j = maxlen; j >= strmin; j--)
        if (length(substr(str, i, j)) == j)
          subs[substr(str, i, j)]++
  }
  if (focus == 1)
  {
    j = length(str)
    for (i = 1; i <= j; i++)
      if (length(substr(str, i, j)) >= strmin)
        subs[substr(str, i, j)]++
  }
  if (focus == 2)
  {
    i=0
    for (j = maxlen; j >= strmin; j--)
      if (length(substr(str, i, j)) == j)
        subs[substr(str, i, j)]++
  }
}
END {
  asorti(subs,wubs,"@val_num_desc")
  for (i in wubs)
    if (subs[wubs[i]] > 1)
      if (subs[wubs[i]]/NR*100 >= threshold)
        if (stats)
          printf("%s\t%s\t%s\n", subs[wubs[i]]/NR*100, subs[wubs[i]], wubs[i])
        else
          printf("%s\n", wubs[i])
}' $filename
