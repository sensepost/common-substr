use std::collections::HashMap;
use std::fs::File;
use std::io::{self, Write, BufRead, BufReader};
//use fnv::FnvHashMap;
use fasthash::RandomState;
use fasthash::sea::Hash64;
use std::env;

// Handles printing our bytes as the output buffer
fn output(out: &mut Vec<u8>, percent: f32, val: &usize, bytes: &[u8]) {
  let mut counter = 0;
  for x in bytes {
    counter += 1;
    if *x == 00 { break; }
  }
  let s = format!("{}\t{}\t", percent, val);
  out.extend_from_slice(s.as_bytes());
  out.extend_from_slice(&bytes[0..counter]);
  out.extend_from_slice(&[b'\n']);
  if out.len() >= 8192 - 300 {
    io::stdout().write_all(&out).unwrap();
    out.clear();
  }
}

fn main() {
  let strmax = 32;
  let strmin = 2;
  let mut maxlen = strmax;
  // We don't need hashmap protections, we want speed, this is faster than FNV too
  let s = RandomState::<Hash64>::new();
  let mut subs = HashMap::with_hasher(s);
  //let mut subs: FnvHashMap<[u8;32], usize> = FnvHashMap::default();
  //let mut subs: HashMap<[u8;32], usize> = HashMap::new();
  let mut count = 0;

  let args: Vec<String> = env::args().collect();
  let file = File::open(&args[1]).unwrap();
  let mut reader = BufReader::new(file);

  loop {
    let mut line = Vec::default();
    // We need to read bytes, not UTF-8 Strings
    let readsize = match reader.read_until(b'\n',&mut line) {
      Ok(num) => num,
      Err(_) => break,
    };
    // EOF check
    if readsize == 0 {
      break;
    }
    // We're using a Vec of fixed size u8's, which is limited to a max of 32
    let line_buf = &line[0..line.len()-1];
    if line_buf.len() < strmax {
      maxlen = line_buf.len()+1;
    }
    // Windows are a neat way to get an iterator and a sized slice
    for i in 0..maxlen {
      for win in line_buf.windows(strmin+i) {
        // Convert our window slice to our fixed byte slice
        let mut foo: [u8; 32] = Default::default();
        foo[..win.len()].copy_from_slice(&win);
        // Insert 0 if the key didn't exist then add one to it, or just add one if it did
        *(subs.entry(foo)).or_insert(0) += 1;
      }
    } //i
    // We use this for percent calcs later
    count += 1;
  } 

  // Sort subs by value, highest to lowest
  let mut wubs: Vec<(&[u8; 32], &usize)> = subs.iter().collect();
  wubs.sort_by(|a, b| b.1.cmp(a.1));

  // Our output buffer
  let mut out = Vec::with_capacity(8192);
  let cnt = count as f32;
  // Print the results and calc the percentage
  for (key, value) in wubs {
    if *value > 1 {
      let val = *value as f32;
      let percentage: f32 = val/cnt * 100.0;
      output(&mut out, percentage,value,key);
    }
  }
  // Flush anything remaining in the buffer
  if out.len() != 0 {
    io::stdout().write_all(&out).unwrap();
  }
}
