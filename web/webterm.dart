
import 'dart:html';
import 'VT100.dart';
import 'dart:async';

class WebTerm {

  VT100 vt100;
  DivElement mainDiv = null;
  List<DivElement> lines = new List<DivElement>();

  int co = 120;
  int ln = 24;

  bool started = false;
  bool w = false;

  WebTerm(String div) {

    mainDiv = querySelector(div);

    mainDiv.style.fontFamily = "Monospace";
    mainDiv.style.overflowY = "scroll";
    mainDiv.style.overflowX = "scroll";

    vt100 = new VT100(ln, co, 1, 1);
    initLines(ln, co);

  }

  void process(String str) {

    if(str == null)
      return;

    for(int i = 0; i < str.length; i++) {
      String s = str[i];
      vt100.process(str[i]);
      drawDirty();
    }

  }

  void onDataLoaded(String s) {

    process(s);

    if(!started) {
      return;
    }

    request();
  }

  void request(){
    var url = "http://127.0.0.1:8080/line";
    var request = HttpRequest.getString(url).then(onDataLoaded);
  }

  void start() {

    if(!started) {
      started = true;
      request();
    } else {
      started = false;
    }

  }

  void initLines(int num, int width) {

    for(int x = 0; x <= num; x++) {

      DivElement line = new DivElement();

      line.classes.add("line");
      line.text = " ";
      lines.add(line);
      mainDiv.append(line);
    }

  }

  void drawDirty() {
    List<Line> dirtyLines = vt100.getDirtyLines();

    for(int i = 0; i < dirtyLines.length; i++) {
      Line dirty = dirtyLines[i];
      DivElement div = lines[dirty.getNR() - 1];
      List<int> bytes = dirty.getBytes();

      String n = "";
      for(int x=1; x < bytes.length; x++) {
        n = n + new String.fromCharCodes([bytes[x]]);
      }

      div.text = " ";
      div.appendText(n);
      dirty.setDirty(false);

    }

  }

}

