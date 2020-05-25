{ buildPythonPackage
, fetchPypi
, lib
}:

buildPythonPackage rec {
  pname = "pycodestyle";
  version = "2.6.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0bhr6ia0hmgx3nhgibc9pmkzhlh1zcqk707i5fbxgs702ll7v2n5";
  };

  # https://github.com/PyCQA/pycodestyle/blob/2.5.0/tox.ini#L14
  checkPhase = ''
    python -m pycodestyle --statistics pycodestyle.py
    python -m pycodestyle --max-doc-length=72 --testsuite testsuite
    python -m pycodestyle --max-doc-length=72 --doctest
    python -m unittest discover testsuite -vv
  '';

  meta = with lib; {
    description = "Python style guide checker (formerly called pep8)";
    homepage = "https://pycodestyle.readthedocs.io";
    license = licenses.mit;
    maintainers = with maintainers; [
      kamadorueda
    ];
  };
}
