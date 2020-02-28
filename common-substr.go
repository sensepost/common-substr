package main

import (
  "fmt"
  "os"
  "bufio"
  "sort"
  "flag"
  "strings"
)

// Allow the substring map to be sorted
// Source: https://groups.google.com/d/msg/golang-nuts/FT7cjmcL7gw/Gj4_aEsE_IsJ
func rankByWordCount(wordFrequencies map[string]int) PairList{
  pl := make(PairList, len(wordFrequencies))
  i := 0
  for k, v := range wordFrequencies {
    pl[i] = Pair{k, v}
    i++
  }
  sort.Sort(sort.Reverse(pl))
  return pl
}

type Pair struct {
  Key string
  Value int
}

type PairList []Pair

// Required for Sort to be able to work
func (p PairList) Len() int { return len(p) }
func (p PairList) Less(i, j int) bool { return p[i].Value < p[j].Value }
func (p PairList) Swap(i, j int){ p[i], p[j] = p[j], p[i] }

func shortusage() {
  fmt.Println("Common Substring Generator by @singe")
  fmt.Println("Usage: $0 [-hinsp] [-t <n>] [-l <n>] [-L <n>] -f <filename>")
  os.Exit(1)
}

func longusage() {
  fmt.Println("Common Substring Generator by @singe")
  fmt.Println("Usage: "+os.Args[0]+" [-hinsp] [-t <n>] [-l <n>] [-L <n>] -f <filename>")
  fmt.Println("  -h|--help This help")
  fmt.Println("  -i|--insensitive Ignore case of substrings")
  fmt.Println("  -L|--maxlength <n> Maximum length substring to look for.")
  fmt.Println("  -l|--minlength <n> Minimum length substring to look for.")
  fmt.Println("  -n|--nostats Just print the substrings, no stats. Default is to include them.")
  fmt.Println("  -t|--threshold <n> Only print substrings more prevalent than <n> percent.")
  fmt.Println("  -f|--file <filename> The file to extract substrings from")
  fmt.Println("  -s|--suffix Only look at suffix substrings at the end of a string")
  fmt.Println("  -p|--prefix Only look at prefix substrings at the beginning of a string")
  fmt.Println("Default output (with stats) is tab separated: <percentage>  <count> <substring>")
  fmt.Println("Sorted from most to least common")
  os.Exit(1)
}

func main() {

  var nocase bool = false
  var nostats bool = false
  var strmax int = 32
  var strmin int = 2
  var threshold int = 0
  var focus int = 0
  var filenamePtr *string
  var suffixPtr *bool
  var prefixPtr *bool

  if ( len(os.Args) == 1 ) {
    shortusage()
  }

  helpPtr := flag.Bool("help", false, "Longer help.")
  flag.BoolVar(&nocase, "insensitive", false, "Ignore case of substrings")
  flag.BoolVar(&nocase, "i", false, "Ignore case of substrings")
  flag.IntVar(&strmax, "maxlength", 32, "Maximum length substring to look for.")
  flag.IntVar(&strmax, "L", 32, "Maximum length substring to look for.")
  flag.IntVar(&strmin, "minlength", 2, "Minimum length substring to look for.")
  flag.IntVar(&strmin, "l", 2, "Minimum length substring to look for.")
  flag.BoolVar(&nostats, "nostats", false, "Just print the substrings, no stats. Default is to include them.")
  flag.BoolVar(&nostats, "n", false, "Just print the substrings, no stats. Default is to include them.")
  flag.IntVar(&threshold, "threshold", 0, "Only print substrings more prevalent than <int> percent.")
  flag.IntVar(&threshold, "t", 0, "Only print substrings more prevalent than <int> percent.")
  filenamePtr = flag.String("file", "", "The file to extract substrings from.")
  filenamePtr = flag.String("f", "", "The file to extract substrings from.")
  suffixPtr = flag.Bool("suffix", false, "Only look at suffix substrings at the end of a string.")
  suffixPtr = flag.Bool("s", false, "Only look at suffix substrings at the end of a string.")
  prefixPtr = flag.Bool("prefix", false, "Only look at prefix substrings at the beginning of a string.")
  prefixPtr = flag.Bool("p", false, "Only look at prefix substrings at the beginning of a string.")
  flag.Parse()

  if ( *helpPtr ) {
    longusage()
  }
  if _, err := os.Stat(*filenamePtr); err != nil {
    fmt.Printf("Unable to open file \"%s\".\n",*filenamePtr)
  }
  if ( *suffixPtr ) {
    focus = 1
  }
  if ( *prefixPtr ) {
    focus = 2
  }

  var i int = 0
  var j int = 0
  var count int = 0
  var maxlen int = 0
  var subs = map[string]int{}

  f, _ := os.Open(*filenamePtr)
  scanner := bufio.NewScanner(f)
  for scanner.Scan() {
    var str string
    if (nocase) {
      str = strings.ToLower(scanner.Text())
    } else {
      str = scanner.Text()
    }

    if ( len(str)-1 < strmax ) {
      maxlen = len(str)
    } else {
      maxlen = strmax
    }
    switch focus {
      case 0: //all substrings
        for i = 0; i < len(str); i++ {
          for j = i; j < maxlen; j++ {
            if ( (i-j)-1 <= -strmin ) {
              subs[str[i:j+1]]++
            }
          } //j
        } //i
      case 1: //suffix
        j = maxlen-1
        for i = 0; i < len(str); i++ {
          if ( (i-j)-1 <= -strmin ) {
            subs[str[i:j+1]]++
          }
        } //i
      case 2: //prefix
        i = 0
        for j = i; j < maxlen; j++ {
          if ( (i-j)-1 <= -strmin ) {
            subs[str[i:j+1]]++
          }
        } //j
    } //switch
    count++ //needed for % calc
  }
  f.Close()

  //sort
  var wubs = rankByWordCount(subs)
  //print output
  for _, p := range wubs {
    if (p.Value > 1) {
      percentage := ( float32(p.Value) / float32(count) ) * 100
      //we might want to ignore some uncommon strings
      if (percentage >= float32(threshold)) {
        //stats can be noisy
        if (nostats) {
          fmt.Printf( "%s\n", p.Key)
        } else {
          fmt.Printf( "%f\t%d\t%s\n", percentage, p.Value, p.Key)
        }
      }
    }
  }
}
