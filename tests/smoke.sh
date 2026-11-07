#!/usr/bin/env bash
# Exercise the Octave features MATL Online relies on. Run as root inside the image.

set -euo pipefail

cd "$(mktemp -d)"

for package in io-2.6.4 statistics-1.4.3 symbolic-2.9.0 image-2.14.0; do
  wget -q "https://github.com/suever/matl-online-octave-packages/raw/main/${package}.tar.gz"
  octave-cli --eval "pkg install ${package}.tar.gz"
done

cat > hello.cc <<'EOF'
#include <octave/oct.h>

DEFUN_DLD (hello, , , "")
{
  return octave_value (42);
}
EOF
mkoctfile hello.cc

octave-cli --eval '
  pkg load image
  pkg load statistics

  assert (graphics_toolkit (), "gnuplot")
  assert (hello (), 42)

  assert (regexprep ("abc", "b", "x"), "axc")
  assert (real (ifft (fft (1:8))), 1:8, 1e-12)

  A = sparse ([4 1 0; 1 3 0; 0 0 2]);
  assert (A \ [1; 2; 3], full (A) \ [1; 2; 3], 1e-12)
  assert (full (chol (A)), chol (full (A)), 1e-12)

  [~, fmin] = glpk ([-1; -1], [1 1], 1, [0; 0], [], "U", "CC", 1);
  assert (fmin, -1, 1e-9)
  convhulln ([0 0; 1 0; 0 1; 1 1; 0.5 0.5]);

  data = magic (4);
  save ("-hdf5", "data.h5", "data");
  clear data
  load ("data.h5");
  assert (data, magic (4))

  imwrite (uint8 (magic (8)), "image.png");
  assert (imread ("image.png"), uint8 (magic (8)))

  audiowrite ("audio.wav", sin ((1:100)(:)) / 2, 8000);
  assert (exist ("audio.wav", "file"), 2)

  figure ("visible", "off");
  plot (1:10);
  print ("-dpng", "-r72", "plot.png");
  assert (exist ("plot.png", "file"), 2)

  disp ("smoke test passed")
'
