import base64
import contextlib
import os
import subprocess
import sys
import tempfile

PRIVATE_KEY = os.path.expanduser('~/.lvimrc_private.pem')
PUBLIC_KEY = os.path.expanduser('~/.lvimrc_public.pem')
LVIMRC_SIGNATURE_HEAD = '" lvimrc_sign='

@contextlib.contextmanager
def TempFile():
  with tempfile.NamedTemporaryFile(delete=False) as f:
    path = f.name
    try:
      yield path
    finally:
      if os.path.exists(path):
        os.unlink(path)

def GenerateKeys():
  subprocess.check_call(['openssl', 'genrsa', '-out', PRIVATE_KEY, '2048'])
  subprocess.check_call(
      ['openssl', 'rsa', '-pubout', '-in', PRIVATE_KEY, '-out', PUBLIC_KEY])


def Sign(text):
  with TempFile() as temp:
    with open(temp, 'w') as tempf:
      tempf.write(text)
    return base64.b64encode(
        subprocess.check_output(
            ['openssl', 'dgst', '-sha256', '-sign', PRIVATE_KEY, temp]))


def Verify(text, sign):
  with TempFile() as temp_sig_file:
    with open(temp_sig_file, 'w') as f:
      f.write(base64.b64decode(sign))
    with TempFile() as temp_file:
      with open(temp_file, 'w') as f:
        f.write(text)
      with open(os.devnull, 'w') as devnull:
        return subprocess.call(
            [
                'openssl', 'dgst', '-sha256', '-verify', PUBLIC_KEY,
                '-signature', temp_sig_file, temp_file
            ],
            stdout=devnull,
            stderr=devnull) == 0


def SplitSign(text):
  lines = text.splitlines(True)
  if lines and lines[-1].startswith(LVIMRC_SIGNATURE_HEAD):
    sign = lines.pop()[len(LVIMRC_SIGNATURE_HEAD):].strip()
  else:
    sign = None
  return (''.join(lines), sign)

def main():
  if not os.path.exists(PRIVATE_KEY):
    print "Keys not exists, generating keys..."
    GenerateKeys()

  if len(sys.argv) <= 1:
    print "Usage: %s [lvimrc]" % __file__
    sys.exit(0)

  lvimrc = sys.argv[1]
  with open(lvimrc, 'r') as f:
    text, _ = SplitSign(f.read())
    text += LVIMRC_SIGNATURE_HEAD + Sign(text) + '\n'

  with open(lvimrc, 'w') as f:
    f.write(text)

if __name__ == '__main__':
  main()
