# Shared modules between all systems
{
  mylib,
  profile,
  ...
}: {
  imports =
    [../base]
    ++ (mylib.scanPaths ./.)
    ++ (mylib.scanPaths ../../profiles/${profile});
}
