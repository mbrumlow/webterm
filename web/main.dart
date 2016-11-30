// Copyright (c) 2016, mbrumlow. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import "webterm.dart";

WebTerm wterm = null;

void main() {
  wterm = new WebTerm("#webterm_container");
  querySelector("#webterm_container").onClick.listen(start);
}

void start(MouseEvent ) {
  wterm.start();
}