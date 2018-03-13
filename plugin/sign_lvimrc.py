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
  subprocess.check_call(
      'openssl genrsa -out %s 2048' % PRIVATE_KEY,
      shell=True)
  subprocess.check_call(
      'openssl rsa -pubout -in %s -out %s' % (PRIVATE_KEY, PUBLIC_KEY),
      shell=True)

def Sign(text):
  with TempFile() as temp:
    with open(temp, 'w') as tempf:
      tempf.write(text)
    return subprocess.check_output(
        'openssl dgst -sha256 -sign ~/.lvimrc_private.pem %s '
        '| base64 -w 0' % temp,
        shell=True)

def Verify(text, sign):
  with TempFile() as temp_sig_file:
    with open(temp_sig_file, 'w') as f:
      f.write(base64.b64decode(sign))
    with TempFile() as temp_file:
      with open(temp_file, 'w') as f:
        f.write(text)
      return subprocess.call(
          'openssl dgst -sha256 -verify %s -signature %s %s >/dev/null' %
          (PUBLIC_KEY, temp_sig_file, temp_file),
          shell=True) == 0

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
