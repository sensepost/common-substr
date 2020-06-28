# common-substr
Simple tool to extract the most common substrings from an input text. Built for password cracking.

There are two versions, the older awk script and the newer & faster golang version. They use the same commandline switches.

# Usage
```
Common Substring Generator by @singe
Usage: ./common-substr [-hinsp] [-t <n>] [-l <n>] [-L <n>] -f <filename>
	-h|--help This help
	-i|--insensitive Ignore case of substrings
	-L|--maxlength <n> Maximum length substring to look for. Default is 32.
	-l|--minlength <n> Minimum length substring to look for. Default is 2.
	-n|--nostats Just print the substrings, no stats. Default is to include them.
	-t|--threshold <n> Only print substrings more prevalent than <n> percent.
	-f|--file <filename> The file to extract substrings from
	-s|--suffix Only look at suffix substrings at the end of a string
	-p|--prefix Only look at prefix substrings at the beginning of a string
Default output (with stats) is tab separated: <percentage>	<count>	<substring>
Sorted from most to least common
```

## Simple Usage Examples

Given the test file:
```
123
123
234
```

We can find the most common substrings:
```
./common-substr -f test
100     3 23
66.6667 2 12
66.6667 2 123
```
Read this output as "100% of the input file had the substring "23" which consisted of 3 instances".

Do the same, but suppress printing of the stats:
```
./common-substr -f test -n
23
12
123
```

Only include substrings that occur at least 70% of the time:
```
./common-substr -f test -t 70
100	3	23
```

The stats are tab-separated, to make cut'ing easy:
```
./common-substr -f test > output
cut -f 3 output
23
12
123
```

Only include substrings 3 characters or longer:
```
./common-substr -f test -l 3 
66.6667 2 123
```

Only include substrings 2 characters or shorter:
```
./common-substr -f test -L 2 
100     3 23
66.6667 2 12
```

Only include the start of the strings (prefix):
```
./common-substr -f test -p
66.6667	2	12
66.6667	2	123
```

Only include the end of the strings (suffix):
```
./common-substr -f test -s
66.6667	2	23
66.6667	2	123
```

# Password Cracking Examples

## Vanilla wordlist + substrings
An example use for password cracking. Assuming you've put already cracked clear-text passwords in a file called 'passwords':
```
# Limit substrings to a max length of 27 and only include those which occur
# at least 1% or more of the time
./common-substr -t 1 -l 27 -n -f passwords > substrs
sort -u passwords > uniques
hashcat -a1 hashes uniques substrs 
```

## Basewords + substrings

It also helps to create "base words" and combine those with the substrings:
```
grep -oi "[a-z]*[a-z]" uniques > basewords
hashcat -a1 hashes basewords substrs
```
Remember to try it the other way around too:
```
hashcat -a1 hashes substrs basewords
```

## All Substrings

Drop the threshold and throw the full list of substrings into combinator:
```
./common-substr -n -f passwords > all-substrs
hashcat -a1 hashes all-substrs all-substrs
```

## Prefix & Suffix Substrings

Take the commons starts and ends of passwords and combine them:
```
./common-substr -n -p -f passwords > prefix
./common-substr -n -s -f passwords > suffix
hashcat -a1 hashes prefix suffix
```

# Building

The golang version can be built using `go build ./common-substr.go`.

The awk version can be run using the `common-substr.sh` wrapper script. It requires awk.

I recommend the golang version.
