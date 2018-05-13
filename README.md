# common-substr
Simple awk script to extract the most common substrings from an input text. Built for password cracking.

# Usage
```
Common Substring Generator by @singe
Usage: ./common-substr.sh [-hin] [-t <n>] [-l <n>] -f <filename>
	-h|--help This help
	-i|--insensitive Ignore case of substrings
	-l|--length <n> Maximum length substring to look for. Default is 32.
	-n|--nostats Just print the substrings, no stats. Default is to include them.
	-t|--threshold <n> Only print substrings more prevalent than <n> percent.
	-f|--file <filename> The file to extract substrings from
Default output (with stats) is tab separated: <percentage>	<count>	<substring>
Sorted from most to least common
```

# Examples

Create a test file:
```
echo -e "123\n234\n345" > test
```
Find the most common substrings:
```
./common-substr.sh -f test
66.6667	2	23
66.6667	2	34
```
Do the same, but suppress printing of stats:
```
./common-substr.sh -n -f test
23
34
```
An example use for password cracking. Assuming you've put already cracked clear-text passwords in a file called 'passwords':
```
./common-substr.sh -t 1 -l 27 -n -f passwords > substrs
# Limit substrings to a max length of 27 and only include those which occur
# more than 1% of the time
sort -u passwords > uniques
hashcat -a1 hashes uniques substrs 
```
It also helps to create "base words" and combine those with the substrings:
```
grep -oi "^[a-z]*" uniques > basewords
hashcat -a1 hashes basewords substrs
```
