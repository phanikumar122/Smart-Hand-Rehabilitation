"""Run production ACK formatting with avr-libc, not the host libc.

Pass the AVR core's avr-g++ path. Requires simavr on PATH. No hardware is used.
"""

import argparse
from pathlib import Path
import subprocess
import tempfile


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("compiler", help="Path to the AVR core's avr-g++")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent

source = r"""
#include <avr/io.h>
#include "glove_core.h"

void writeByte(char byte) {
  while (!(UCSR0A & _BV(UDRE0))) {}
  UDR0 = byte;
}

void output(const char *line) {
  for (; *line; ++line) writeByte(*line);
  writeByte('\n');
}

void command(GloveCore &glove, const char *text) {
  for (; *text; ++text) glove.receive(*text, 0);
}

int main() {
  UBRR0 = 103;
  UCSR0B = _BV(TXEN0);
  UCSR0C = _BV(UCSZ01) | _BV(UCSZ00);
  GloveCore glove(output);
  command(glove, "<Q:1:VIB:3,1>");
  command(glove, "<Q:2:VIB:ALL,0>");
  for (;;) {}
}
"""

with tempfile.TemporaryDirectory(prefix="smart-glove-avr-") as directory:
    binary = Path(directory) / "ack.elf"
    subprocess.run([
        args.compiler, "-mmcu=atmega328p", "-std=gnu++11", "-Os",
        "-I", str(root / "smart_glove"), "-x", "c++", "-", "-o", str(binary),
    ], input=source, text=True, check=True)
    try:
        result = subprocess.run([
            "simavr", "-m", "atmega328p", "-f", "16000000", str(binary),
        ], capture_output=True, timeout=3, check=True)
        output = result.stdout + result.stderr
    except subprocess.TimeoutExpired as error:
        # The sketch deliberately idles after emitting its UART replies.
        output = (error.stdout or b"") + (error.stderr or b"")
    for expected in (b"ACK,1,VIB,3,1,4", b"ACK,2,VIB,ALL,0,0"):
        if expected not in output:
            raise SystemExit(f"Missing {expected!r}; simulator output: {output!r}")
    print("AVR individual and all-motor acknowledgements passed")