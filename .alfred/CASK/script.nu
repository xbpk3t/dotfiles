#!/usr/bin/env nu

use ../common.nu *

def get-target-dir [dir?: string] {
  ($dir | default "~/Desktop/" | str trim | path expand)
}

def get-filename [] {
  let filename = ($env.new_file | default "" | str trim)
  if ($filename | is-empty) {
    print "missing env new_file"
    exit 1
  }
  $filename
}

def create-file [target_dir: string, filename: string] {
  let full_path = (path join $target_dir $filename)
  if (path exists $full_path) {
    print $"($filename) already exists"
  } else {
    touch $full_path
    print $"($filename) created in ($target_dir)"
  }
}

def open-dir [target_dir: string] {
  try { ^open $target_dir } catch {|_e| null }
}

export def main [dir?: string] {
  ensure-path
  let target_dir = (get-target-dir $dir)
  let filename   = (get-filename)
  create-file $target_dir $filename
  open-dir $target_dir
}

main
