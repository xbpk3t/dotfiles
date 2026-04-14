{lib, ...}: let
  regexMetaChars = ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"];
  escapeRegex = lib.replaceStrings regexMetaChars (map (char: "\\${char}") regexMetaChars);
in {
  mkExactNameRegex = names: "^(${lib.concatStringsSep "|" (map escapeRegex names)})$";
}
