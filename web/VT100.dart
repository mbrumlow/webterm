

class VT100 {

  List<Line> lines = new List<Line>();

  int ln;
  int co;


  int cx;
  int cy;

  int top;
  int bot;

  bool offsetMode = false;

  bool esc = false;

  bool leftBracket = false;
  int leftBracketPos = 0;
  int leftBracketX = 1;
  int leftBracketY = 1;
  int leftBracketMode = -1;
  bool leftBracketQuestionMark = false;
  String leftBracketS = "";


  bool openP = false;
  bool closeP = false;

  bool autoWrap = false;

  bool wrap = false;

  VT100(int lines, int columns, int y, int x) {

    this.ln = lines;
    this.co = columns;
    this.top = 1;
    this.bot = lines;
    this.cx = x;
    this.cy = y;

    resetLines();
    resetLeftBracket();

  }

  List getDirtyLines(){
    List<Line> dirty = new List<Line>();
    for(int i = 1; i < ln; i++) {
      if(lines[i].dirty) {
        dirty.add(lines[i]);
      }
    }

    return dirty;

  }

  List getCur() {
    return [cy, cx];
  }

  bool getAutoWrap() {
    return autoWrap;
  }

  void setAutoWrap(bool autoWrap) {
    this.autoWrap = autoWrap;
  }

  void resetLeftBracket(){
    leftBracketX = 1;
    leftBracketY = 1;
    leftBracketS = "";
    leftBracket = false;
    leftBracketMode = -1;
    leftBracketQuestionMark = false;
    esc = false;
  }

  void parseX() {
    if(leftBracketS.length > 0) {
      leftBracketX = int.parse(leftBracketS);
    }
    leftBracketS = "";
  }

  void parseY() {
    if(leftBracketS.length > 0) {
      leftBracketY = int.parse(leftBracketS);
    }
    leftBracketS = "";
  }

  void setCX(int x) {

    if(x > co) {
      x = co;
    }

    if(x < 1) {
      x = 1;
    }

    this.cx = x;

  }

  void setCY(int y) {

    int maxY;
    int minY;

    if(offsetMode) {
      minY = top;
      maxY = bot;
    } else {
      minY = 1;
      maxY = ln;
    }

    if(y > maxY) {
      y = maxY;
    }

    if(y < minY) {
      y = minY;
    }

    this.cy = y;

  }

  void process(String s){

    if(s == null)
      return;

    List<int> codeUnits = s.codeUnits;


    for(int i =0; i < codeUnits.length; i++) {

      int code = codeUnits[i];

      if((cy == 4) && (cx == 74)) {
        i = i;
      }

      if(code == 64) {

        int xx = 234;

        i = i;

      }

      if(leftBracket) {

        switch(code) {

          case 48: // 0
          case 49: // 1
          case 50: // 2
          case 51: // 3
          case 52: // 4
          case 53: // 5
          case 54: // 6
          case 55: // 7
          case 56: // 8
          case 57: // 9
            leftBracketMode = code;
            leftBracketS += new String.fromCharCodes([codeUnits[i]]);
            break;

          case 59: // ;
            parseY();
            break;

          case 63: // ?
            leftBracketQuestionMark = true;
            break;

          case 65: // A - ESC[A
            parseX();
            setCur(cx, cy - leftBracketX);
            resetLeftBracket();
            break;

          case 66: // B- ESC[B
            parseX();
            setCur(cx, cy + leftBracketX);
            resetLeftBracket();
            break;

          case 67: // C - ESC[C
            parseX();
            setCur(cx + leftBracketX, cy);
            resetLeftBracket();
            break;

          case 68: // D - ESC[D
            parseX();
            setCur(cx - leftBracketX, cy);
            resetLeftBracket();
            break;

          case 74: // J
            parseX();
            switch(leftBracketMode) {
              case -1: // ESC[J
              case  0: // ESC[0J
                lines[cy].EL0(cx);
                for(int x = cy+1; x <= ln; x++) {
                  lines[x].EL2();
                }
                break;
              case  1: // ESC[1J
                lines[cy].EL1(cx);
                for(int x = 1; x > cy - 1; x++) {
                  lines[x].EL2();
                }
                break;
              case  2: // ESC[2J
                for(int x = 1; x <= ln; x++) {
                  lines[x].EL2();
                }
                break;
            }
            resetLeftBracket();
            break;

          case 75: // K
            parseX();
            switch(leftBracketMode) {

              case -1: // ESC[K
              case  0: // ESC[0K
                lines[cy].EL0(cx);
                break;
              case  1: // ESC[1K
                lines[cy].EL1(cx);
                break;
              case  2: // ESC[2K
                lines[cy].EL2();
            }
            resetLeftBracket();
            break;

          case 72: // H - ESC[H
          case 102: // f ESC[f
            parseX();
            setCur(leftBracketX, leftBracketY);
            resetLeftBracket();
            break;

          case 76:  // L - ESC[?L
          case 104: // h - ESC[?h
            if(leftBracketQuestionMark) {
              switch(leftBracketMode) {
                case 55: // 6
                  offsetMode = (104 == code);
                  break;
                case 56: // 7
                  autoWrap = (104 == code);
                  break;
                default:
              }
            }

            resetLeftBracket();
            break;

          case 109: // m - ESC[m  FIXME: implement
            resetLeftBracket();
            break;

          case 114: // r - ESC[r
            parseX();
            top = leftBracketY;
            bot = leftBracketX;
            resetLeftBracket();
            break;

          default:
            resetLeftBracket();

        }

      } else if(openP){

        openP = false;
        esc = false;

      } else if(closeP) {

        closeP = false;
        esc = false;

      } else if(esc) {

        switch(code) {

          case 40:
            openP = true;
            break;

          case 41:
            closeP = true;
            break;

          case 91: // [ - ESC[
            leftBracketPos = i;
            leftBracket = true;
            break;

          case 61: // = - ESC=
          case 62: // > - ESC>
          default:
            esc = false;
        }

      } else {

        if(cy == 4) {

          int xwewer = 23423;

        }

        switch(code) {

          case 8: // BS
            backSpace();
            break;

          case 27: // ESC
            esc = true;
            break;

          case 15: // SI
            break;

          case 10: // NL
            newLine();
            break;

          case 13: // CR
            carriageReturn();
            break;

          default:
            writeCode(code);

        }

      }

    }

  }

  void writeCode(int code) {

    if(wrap) {
      if(cy >= ln) {
        newLine();
      }
      setCur(1, cy + 1);
    }

    lines[cy].SET(cx, code);

    if(cx == co) {
      wrap = true;
    }

    if(cx < co ) {
      setCur(cx + 1, cy);
    }

  }

  void setCur(int x, int y) {
    setCX(x);
    setCY(y);
    wrap = false;
  }

  void backSpace() {
    setCur(cx - 1, cy);
    wrap = false;
  }

  void carriageReturn() {
    setCur(1, cy);
    wrap = false;
  }

  void newLine() {




    if(cy == bot) {

      scrollRegion(1, top, co, ((bot - top) + 1) , 0, 1);

    } else {
      setCY(cy + 1);
    }

    wrap = false;
  }

  void resetLines() {
    for(int x = 0; x <= ln; x++) {
      Line line = new Line(x, co);
      lines.add(line);
    }
  }

  void scrollRegion(int x, int y, int w, int h, int xInc, int yInc) {


    for(int i = y; i <= h; i++) {
      for(int p = x; p <= w; p++){
        if(i <= (h - yInc)  ) {
          lines[i].SET(p, lines[i+1].GET(p));
        } else {
          lines[i].SET(p, 32);
        }
      }
    }

  }

}

class Line {

  List<int> line = new List<int>();
  bool dirty = false;
  int nr;

  Line(int nr, int size) {
    for(int x = 0; x <= size; x++) {
      line.add(32);
    }
    dirty = false;
    this.nr = nr;
  }

  int getNR() {
    return nr;
  }

  List<int> getBytes() {
    return line;
  }

  void setDirty(bool dirty) {
    this.dirty = dirty;
  }

  int GET(int pos) {
    if(pos > 0 && pos < line.length) {
      return line[pos];
    }
    return 32;
  }

  void SET(int pos, int key){
    if(pos < line.length) {
      line[pos] = key;
    }
    setDirty(true);
  }

  void EL0(int pos) {
    for(int x = pos; x < line.length; x++) {
      line[x] = 32; // SPACE
    }
    setDirty(true);
  }

  void EL1(int pos) {
    for(int x = 0; x <= pos; x++) {
      line[x] = 32; // SPACE
    }
    setDirty(true);
  }

  void EL2() {
    for(int x = 0; x < line.length; x++) {
      line[x] = 32; // SPACE
    }
    setDirty(true);
  }

}