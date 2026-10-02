// ============================================================
// BFS NAVIGATION
// 10506 김범서
//
// 실행 한 번으로 전 과정 자동 진행
//
// - 글자 출력 함수 text() 사용 안 함
// - 숫자는 7세그먼트 도형으로 직접 그림
// - 탐색 알고리즘: FIFO Queue 기반 BFS
//
// 흐름
// 인트로
// → 1차 문제
// → BFS
// → parent 역추적
// → 최단경로
// → 차량 이동
// → 쿨타임
// → 2차 문제
// → BFS
// → 최단경로
// → 차량 이동
// → 아웃트로
//
// 약 1분 ~ 2분
// ============================================================


// ============================================================
// 지도
// ============================================================

final int COLS = 19;
final int ROWS = 11;

final float GAP = 52;

float originX;
float originY;


// ============================================================
// BFS
// ============================================================

boolean[][] visited =
  new boolean[COLS][ROWS];

int[][] parentX =
  new int[COLS][ROWS];

int[][] parentY =
  new int[COLS][ROWS];

int[][] distanceValue =
  new int[COLS][ROWS];


// 0 = 미방문
// 1 = Queue 안에 있음
// 2 = Queue에서 꺼내 처리 완료

int[][] nodeState =
  new int[COLS][ROWS];


float[][] appear =
  new float[COLS][ROWS];

float[][] wave =
  new float[COLS][ROWS];


// ============================================================
// FIFO Queue
// ============================================================

int[] queueX =
  new int[COLS * ROWS];

int[] queueY =
  new int[COLS * ROWS];

int queueHead = 0;
int queueTail = 0;


// ============================================================
// 막힌 도로
// ============================================================

// (x,y) ↔ (x+1,y)

boolean[][] horizontalBlocked =
  new boolean[COLS - 1][ROWS];


// (x,y) ↔ (x,y+1)

boolean[][] verticalBlocked =
  new boolean[COLS][ROWS - 1];


// ============================================================
// 출발 / 목적지
// ============================================================

int startX;
int startY;

int goalX;
int goalY;


// 0 = 첫 번째 문제
// 1 = 두 번째 문제

int scenario = 0;


// ============================================================
// 경로
// ============================================================

// 목적지 → 출발점

int[] traceX =
  new int[COLS * ROWS];

int[] traceY =
  new int[COLS * ROWS];

int traceLength = 0;


// 출발점 → 목적지

int[] pathX =
  new int[COLS * ROWS];

int[] pathY =
  new int[COLS * ROWS];

int pathLength = 0;


// ============================================================
// 장면
// ============================================================

final int INTRO      = 0;
final int MAP_WAIT   = 1;
final int SEARCH     = 2;
final int FOUND      = 3;
final int BACKTRACK  = 4;
final int ROUTE      = 5;
final int DRIVE      = 6;
final int ARRIVE     = 7;
final int COOLDOWN   = 8;
final int OUTRO      = 9;
final int END        = 10;

int scene = INTRO;

int sceneFrame = 0;


// ============================================================
// 시간
// ============================================================

// 인트로 약 4초

final int INTRO_TIME = 240;


// 문제 상황 감상 약 2.5초

final int MAP_WAIT_TIME = 150;


// BFS 한 층 약 0.47초

final int BFS_DELAY = 28;


// 목표 발견 약 1.5초

final int FOUND_TIME = 90;


// 역추적 속도

final int BACKTRACK_DELAY = 5;


// 경로 감상 약 2초

final int ROUTE_TIME = 120;


// 도착 연출 약 3초

final int ARRIVE_TIME = 180;


// 두 문제 사이 약 3초

final int COOLDOWN_TIME = 180;


// 아웃트로 약 5초

final int OUTRO_TIME = 300;


// ============================================================
// BFS 타이머
// ============================================================

int bfsTimer = 0;


// ============================================================
// 역추적
// ============================================================

int backtrackVisible = 0;

int backtrackTimer = 0;


// ============================================================
// 자동차
// ============================================================

float carX;
float carY;

float carAngle = 0;

int carSegment = 0;

float carT = 0;


// 한 칸 약 0.3초

final float CAR_SPEED =
  1.0 / 18.0;


// ============================================================
// 효과
// ============================================================

float goalFoundPulse = 0;

float arrivalPulse = 0;


// ============================================================
// 7 SEGMENT 숫자
//
//       A
//     F   B
//       G
//     E   C
//       D
//
// ============================================================

boolean[][] DIGIT_SEGMENTS = {

  // A     B      C      D      E      F      G

  {true,  true,  true,  true,  true,  true,  false}, // 0

  {false, true,  true,  false, false, false, false}, // 1

  {true,  true,  false, true,  true,  false, true }, // 2

  {true,  true,  true,  true,  false, false, true }, // 3

  {false, true,  true,  false, false, true,  true }, // 4

  {true,  false, true,  true,  false, true,  true }, // 5

  {true,  false, true,  true,  true,  true,  true }, // 6

  {true,  true,  true,  false, false, false, false}, // 7

  {true,  true,  true,  true,  true,  true,  true }, // 8

  {true,  true,  true,  true,  false, true,  true }  // 9
};


// ============================================================
// SETUP
// ============================================================

void setup() {

  size(1280, 720);

  frameRate(60);

  smooth(8);


  originX =
    (width - (COLS - 1) * GAP) / 2;


  originY = 95;


  setupScenario(0);

}


// ============================================================
// DRAW
// ============================================================

void draw() {

  background(
    5,
    9,
    16
  );


  sceneFrame++;


  // ==========================================================
  // INTRO
  // ==========================================================

  if (scene == INTRO) {

    drawIntro();


    if (
      sceneFrame >=
      INTRO_TIME
    ) {

      changeScene(
        MAP_WAIT
      );

    }


    return;

  }


  // ==========================================================
  // 기본 도시
  // ==========================================================

  drawBackgroundGlow();

  drawBuildings();

  drawRoads();

  drawBlockedRoads();

  updateEffects();

  drawBFSTree();

  drawBFSNodes();


  // ==========================================================
  // BFS 탐색 중 숫자 표시
  //
  // 같은 거리의 노드는 같은 숫자
  // ==========================================================

  if (
    scene == SEARCH ||
    scene == FOUND ||
    scene == BACKTRACK
  ) {

    drawDistanceNumbers();

  }


  drawStartPoint();

  drawGoalPoint();


  // ==========================================================
  // 지도 감상
  // ==========================================================

  if (
    scene == MAP_WAIT
  ) {

    if (
      sceneFrame >=
      MAP_WAIT_TIME
    ) {

      beginBFS();

      changeScene(
        SEARCH
      );

    }

  }


  // ==========================================================
  // BFS
  // ==========================================================

  else if (
    scene == SEARCH
  ) {

    bfsTimer++;


    if (
      bfsTimer >=
      BFS_DELAY
    ) {

      bfsTimer = 0;

      bfsOneLayer();

    }

  }


  // ==========================================================
  // 목표 발견
  // ==========================================================

  else if (
    scene == FOUND
  ) {

    if (
      sceneFrame >=
      FOUND_TIME
    ) {

      backtrackVisible = 1;

      backtrackTimer = 0;


      changeScene(
        BACKTRACK
      );

    }

  }


  // ==========================================================
  // 부모 노드 역추적
  // ==========================================================

  else if (
    scene == BACKTRACK
  ) {

    backtrackTimer++;


    if (
      backtrackTimer >=
      BACKTRACK_DELAY
    ) {

      backtrackTimer = 0;

      backtrackVisible++;


      if (
        backtrackVisible >=
        traceLength
      ) {

        backtrackVisible =
          traceLength;


        changeScene(
          ROUTE
        );

      }

    }

  }


  // ==========================================================
  // 최종 경로
  // ==========================================================

  else if (
    scene == ROUTE
  ) {

    if (
      sceneFrame >=
      ROUTE_TIME
    ) {

      prepareCar();

      changeScene(
        DRIVE
      );

    }

  }


  // ==========================================================
  // 자동차 이동
  // ==========================================================

  else if (
    scene == DRIVE
  ) {

    updateCar();

  }


  // ==========================================================
  // 도착
  // ==========================================================

  else if (
    scene == ARRIVE
  ) {

    arrivalPulse +=
      0.018;


    if (
      sceneFrame >=
      ARRIVE_TIME
    ) {

      if (
        scenario == 0
      ) {

        changeScene(
          COOLDOWN
        );

      }

      else {

        changeScene(
          OUTRO
        );

      }

    }

  }


  // ==========================================================
  // 역추적
  // ==========================================================

  if (
    scene == BACKTRACK
  ) {

    drawBacktrack();

  }


  // ==========================================================
  // 최종 경로
  // ==========================================================

  if (
    scene == ROUTE ||
    scene == DRIVE ||
    scene == ARRIVE ||
    scene == COOLDOWN ||
    scene == OUTRO
  ) {

    drawFinalPath();

    drawPathNumbers();

  }


  // ==========================================================
  // 자동차
  // ==========================================================

  if (
    scene == DRIVE ||
    scene == ARRIVE ||
    scene == COOLDOWN ||
    scene == OUTRO
  ) {

    drawCar();

  }


  // ==========================================================
  // 도착 효과
  // ==========================================================

  if (
    scene == ARRIVE
  ) {

    drawArrivalEffect();

  }


  // ==========================================================
  // 쿨타임
  // ==========================================================

  if (
    scene == COOLDOWN
  ) {

    drawCooldown();


    if (
      sceneFrame >=
      COOLDOWN_TIME
    ) {

      scenario = 1;


      setupScenario(1);


      changeScene(
        MAP_WAIT
      );

    }

  }


  // ==========================================================
  // 아웃트로
  // ==========================================================

  if (
    scene == OUTRO
  ) {

    drawOutro();


    if (
      sceneFrame >=
      OUTRO_TIME
    ) {

      changeScene(
        END
      );

    }

  }


  // ==========================================================
  // END
  // ==========================================================

  if (
    scene == END
  ) {

    background(0);

  }

}


// ============================================================
// 장면 변경
// ============================================================

void changeScene(
  int nextScene
) {

  scene =
    nextScene;


  sceneFrame = 0;

}


// ============================================================
// 시나리오
// ============================================================

void setupScenario(
  int number
) {

  clearRoadBlocks();

  resetBFS();


  // ==========================================================
  // 첫 번째 문제
  // ==========================================================

  if (
    number == 0
  ) {

    startX = 1;

    startY = 9;


    goalX = 17;

    goalY = 1;


    // 첫 장벽
    // 위쪽 y=2 통과

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 2
      ) {

        horizontalBlocked[4][y] =
          true;

      }

    }


    // 두 번째 장벽
    // 아래쪽 y=8 통과

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 8
      ) {

        horizontalBlocked[9][y] =
          true;

      }

    }


    // 세 번째 장벽
    // 위쪽 y=3 통과

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 3
      ) {

        horizontalBlocked[14][y] =
          true;

      }

    }


    horizontalBlocked[2][5] =
      true;


    horizontalBlocked[2][6] =
      true;


    verticalBlocked[6][3] =
      true;


    horizontalBlocked[7][4] =
      true;


    horizontalBlocked[11][5] =
      true;


    verticalBlocked[12][6] =
      true;

  }


  // ==========================================================
  // 두 번째 문제
  // ==========================================================

  else {

    startX = 1;

    startY = 1;


    goalX = 17;

    goalY = 9;


    // 첫 장벽
    // 아래쪽 y=7

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 7
      ) {

        horizontalBlocked[4][y] =
          true;

      }

    }


    // 두 번째 장벽
    // 위쪽 y=2

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 2
      ) {

        horizontalBlocked[9][y] =
          true;

      }

    }


    // 세 번째 장벽
    // 아래쪽 y=8

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        y != 8
      ) {

        horizontalBlocked[14][y] =
          true;

      }

    }


    verticalBlocked[2][3] =
      true;


    horizontalBlocked[6][7] =
      true;


    verticalBlocked[7][6] =
      true;


    horizontalBlocked[11][3] =
      true;


    verticalBlocked[12][4] =
      true;


    horizontalBlocked[16][6] =
      true;

  }


  carX =
    screenX(
      startX
    );


  carY =
    screenY(
      startY
    );


  arrivalPulse = 0;

  goalFoundPulse = 0;

}


// ============================================================
// 도로 통제 초기화
// ============================================================

void clearRoadBlocks() {

  for (
    int x = 0;
    x < COLS - 1;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      horizontalBlocked[x][y] =
        false;

    }

  }


  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS - 1;
      y++
    ) {

      verticalBlocked[x][y] =
        false;

    }

  }

}


// ============================================================
// BFS 초기화
// ============================================================

void resetBFS() {

  queueHead = 0;

  queueTail = 0;


  traceLength = 0;

  pathLength = 0;


  backtrackVisible = 0;


  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      visited[x][y] =
        false;


      parentX[x][y] =
        -1;


      parentY[x][y] =
        -1;


      distanceValue[x][y] =
        -1;


      nodeState[x][y] =
        0;


      appear[x][y] =
        0;


      wave[x][y] =
        0;

    }

  }

}


// ============================================================
// Queue 삽입
// ============================================================

void enqueue(
  int x,
  int y
) {

  queueX[queueTail] =
    x;


  queueY[queueTail] =
    y;


  queueTail++;

}


// ============================================================
// BFS 시작
// ============================================================

void beginBFS() {

  resetBFS();


  visited[startX][startY] =
    true;


  distanceValue[startX][startY] =
    0;


  nodeState[startX][startY] =
    1;


  appear[startX][startY] =
    1;


  enqueue(
    startX,
    startY
  );


  bfsTimer = 0;

}


// ============================================================
// BFS 한 층
//
// Queue의 현재 층 전체를 먼저 처리
// ============================================================

void bfsOneLayer() {

  if (
    queueHead >=
    queueTail
  ) {

    return;

  }


  int layerCount =
    queueTail -
    queueHead;


  for (
    int i = 0;
    i < layerCount;
    i++
  ) {

    int cx =
      queueX[queueHead];


    int cy =
      queueY[queueHead];


    queueHead++;


    nodeState[cx][cy] =
      2;


    tryVisit(
      cx,
      cy,
      cx + 1,
      cy
    );


    tryVisit(
      cx,
      cy,
      cx - 1,
      cy
    );


    tryVisit(
      cx,
      cy,
      cx,
      cy + 1
    );


    tryVisit(
      cx,
      cy,
      cx,
      cy - 1
    );

  }


  // 목적지 발견

  if (
    visited[goalX][goalY]
  ) {

    createPath();


    goalFoundPulse =
      1;


    changeScene(
      FOUND
    );

  }

}


// ============================================================
// BFS 이웃 확인
// ============================================================

void tryVisit(
  int fromX,
  int fromY,
  int toX,
  int toY
) {

  // 지도 밖

  if (
    toX < 0 ||
    toX >= COLS ||
    toY < 0 ||
    toY >= ROWS
  ) {

    return;

  }


  // 통제 도로

  if (
    roadBlocked(
      fromX,
      fromY,
      toX,
      toY
    )
  ) {

    return;

  }


  // 방문됨

  if (
    visited[toX][toY]
  ) {

    return;

  }


  // ==========================================================
  // BFS 핵심
  // ==========================================================

  visited[toX][toY] =
    true;


  parentX[toX][toY] =
    fromX;


  parentY[toX][toY] =
    fromY;


  distanceValue[toX][toY] =
    distanceValue[fromX][fromY]
    + 1;


  nodeState[toX][toY] =
    1;


  enqueue(
    toX,
    toY
  );


  appear[toX][toY] =
    0;


  wave[toX][toY] =
    1;

}


// ============================================================
// 도로 통제 확인
// ============================================================

boolean roadBlocked(
  int x1,
  int y1,
  int x2,
  int y2
) {

  if (
    y1 == y2
  ) {

    int left =
      min(
        x1,
        x2
      );


    return
      horizontalBlocked[left][y1];

  }


  int top =
    min(
      y1,
      y2
    );


  return
    verticalBlocked[x1][top];

}


// ============================================================
// BFS 최단경로 복원
// ============================================================

void createPath() {

  traceLength = 0;


  int x =
    goalX;


  int y =
    goalY;


  // 목표 -> 시작

  while (true) {

    traceX[traceLength] =
      x;


    traceY[traceLength] =
      y;


    traceLength++;


    if (
      x == startX &&
      y == startY
    ) {

      break;

    }


    int previousX =
      parentX[x][y];


    int previousY =
      parentY[x][y];


    x =
      previousX;


    y =
      previousY;

  }


  // 시작 -> 목표

  pathLength =
    traceLength;


  for (
    int i = 0;
    i < traceLength;
    i++
  ) {

    pathX[i] =
      traceX[
        traceLength - 1 - i
      ];


    pathY[i] =
      traceY[
        traceLength - 1 - i
      ];

  }

}


// ============================================================
// 효과 업데이트
// ============================================================

void updateEffects() {

  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        visited[x][y]
      ) {

        appear[x][y] =
          lerp(
            appear[x][y],
            1,
            0.13
          );

      }


      if (
        wave[x][y] > 0
      ) {

        wave[x][y] *=
          0.93;

      }

    }

  }


  if (
    goalFoundPulse > 0
  ) {

    goalFoundPulse *=
      0.945;

  }

}


// ============================================================
// 배경
// ============================================================

void drawBackgroundGlow() {

  noStroke();


  fill(
    15,
    50,
    90,
    18
  );


  ellipse(
    width / 2,
    height / 2,
    1150,
    640
  );


  fill(
    30,
    80,
    120,
    7
  );


  ellipse(
    width * 0.25,
    height * 0.35,
    550,
    430
  );


  ellipse(
    width * 0.75,
    height * 0.60,
    600,
    480
  );

}


// ============================================================
// 건물
// ============================================================

void drawBuildings() {

  for (
    int x = 0;
    x < COLS - 1;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS - 1;
      y++
    ) {

      float bx =
        originX +
        x * GAP +
        10;


      float by =
        originY +
        y * GAP +
        10;


      float bw =
        GAP - 20;


      float bh =
        GAP - 20;


      float shade =
        20 +
        (
          (
            x * 17 +
            y * 11
          )
          % 12
        );


      noStroke();


      fill(
        0,
        0,
        0,
        100
      );


      rect(
        bx + 4,
        by + 4,
        bw,
        bh,
        5
      );


      fill(
        shade,
        shade + 5,
        shade + 14
      );


      rect(
        bx,
        by,
        bw,
        bh,
        5
      );


      if (
        (
          x + y
        )
        % 4
        == 0
      ) {

        fill(
          70,
          120,
          150,
          40
        );


        ellipse(
          bx + 10,
          by + 10,
          4,
          4
        );

      }

    }

  }

}


// ============================================================
// 도로
// ============================================================

void drawRoads() {

  for (
    int x = 0;
    x < COLS - 1;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      drawRoadLine(
        screenX(x),
        screenY(y),
        screenX(x + 1),
        screenY(y)
      );

    }

  }


  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS - 1;
      y++
    ) {

      drawRoadLine(
        screenX(x),
        screenY(y),
        screenX(x),
        screenY(y + 1)
      );

    }

  }

}


// ============================================================
// 도로 한 줄
// ============================================================

void drawRoadLine(
  float x1,
  float y1,
  float x2,
  float y2
) {

  strokeCap(
    ROUND
  );


  stroke(
    38,
    44,
    55
  );


  strokeWeight(
    13
  );


  line(
    x1,
    y1,
    x2,
    y2
  );


  stroke(
    105,
    110,
    120,
    55
  );


  strokeWeight(
    1.2
  );


  line(
    x1,
    y1,
    x2,
    y2
  );

}


// ============================================================
// 막힌 도로
// ============================================================

void drawBlockedRoads() {

  for (
    int x = 0;
    x < COLS - 1;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        horizontalBlocked[x][y]
      ) {

        float mx =
          (
            screenX(x) +
            screenX(x + 1)
          )
          / 2;


        drawBarrier(
          mx,
          screenY(y),
          true,
          x,
          y
        );

      }

    }

  }


  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS - 1;
      y++
    ) {

      if (
        verticalBlocked[x][y]
      ) {

        float my =
          (
            screenY(y) +
            screenY(y + 1)
          )
          / 2;


        drawBarrier(
          screenX(x),
          my,
          false,
          x,
          y
        );

      }

    }

  }

}


// ============================================================
// 바리케이드
// ============================================================

void drawBarrier(
  float x,
  float y,
  boolean horizontalRoad,
  int sx,
  int sy
) {

  float pulse =
    0.5 +
    0.5 *
    sin(
      frameCount * 0.07 +
      sx +
      sy
    );


  noStroke();


  fill(
    255,
    40,
    60,
    20 +
    pulse * 20
  );


  ellipse(
    x,
    y,
    35 +
    pulse * 10,
    35 +
    pulse * 10
  );


  stroke(
    255,
    65,
    75
  );


  strokeWeight(
    5
  );


  if (
    horizontalRoad
  ) {

    line(
      x - 6,
      y - 11,
      x - 6,
      y + 11
    );


    line(
      x + 6,
      y - 11,
      x + 6,
      y + 11
    );

  }

  else {

    line(
      x - 11,
      y - 6,
      x + 11,
      y - 6
    );


    line(
      x - 11,
      y + 6,
      x + 11,
      y + 6
    );

  }

}


// ============================================================
// BFS 부모 트리
// ============================================================

void drawBFSTree() {

  if (
    scene < SEARCH
  ) {

    return;

  }


  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        visited[x][y] &&
        parentX[x][y] != -1
      ) {

        float alpha =
          72;


        if (
          scene >= ROUTE
        ) {

          alpha =
            22;

        }


        stroke(
          45,
          170,
          255,
          alpha
        );


        strokeWeight(
          2.5
        );


        line(
          screenX(x),
          screenY(y),

          screenX(
            parentX[x][y]
          ),

          screenY(
            parentY[x][y]
          )
        );

      }

    }

  }

}


// ============================================================
// BFS 노드
// ============================================================

void drawBFSNodes() {

  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        !visited[x][y]
      ) {

        continue;

      }


      float px =
        screenX(x);


      float py =
        screenY(y);


      noStroke();


      fill(
        45,
        160,
        255,
        145 *
        appear[x][y]
      );


      ellipse(
        px,
        py,
        8,
        8
      );


      // 현재 Queue

      if (
        nodeState[x][y] == 1 &&
        scene == SEARCH
      ) {

        float pulse =
          0.5 +
          0.5 *
          sin(
            frameCount * 0.15 +
            x * 0.7 +
            y * 0.5
          );


        noStroke();


        fill(
          75,
          225,
          255,
          130
        );


        ellipse(
          px,
          py,
          15 +
          pulse * 5,
          15 +
          pulse * 5
        );


        noFill();


        stroke(
          80,
          235,
          255,
          225
        );


        strokeWeight(
          3
        );


        ellipse(
          px,
          py,
          28 +
          pulse * 8,
          28 +
          pulse * 8
        );


        stroke(
          80,
          210,
          255,
          55
        );


        strokeWeight(
          2
        );


        ellipse(
          px,
          py,
          46 +
          pulse * 15,
          46 +
          pulse * 15
        );

      }


      // 새로 Queue에 들어온 노드

      if (
        wave[x][y] > 0.01
      ) {

        float radius =
          12 +
          (
            1 -
            wave[x][y]
          )
          * 58;


        noFill();


        stroke(
          70,
          215,
          255,
          210 *
          wave[x][y]
        );


        strokeWeight(
          2
        );


        ellipse(
          px,
          py,
          radius,
          radius
        );

      }

    }

  }

}


// ============================================================
// BFS 거리 숫자
//
// 같은 숫자가 한 층씩 확장된다.
// ============================================================

void drawDistanceNumbers() {

  for (
    int x = 0;
    x < COLS;
    x++
  ) {

    for (
      int y = 0;
      y < ROWS;
      y++
    ) {

      if (
        !visited[x][y]
      ) {

        continue;

      }


      int value =
        distanceValue[x][y];


      float px =
        screenX(x);


      float py =
        screenY(y) - 16;


      color numberColor;


      // Queue에 들어간 현재 frontier

      if (
        nodeState[x][y] == 1
      ) {

        numberColor =
          color(
            160,
            245,
            255,
            255
          );

      }

      else {

        numberColor =
          color(
            130,
            185,
            235,
            175
          );

      }


      // 어두운 배경

      noStroke();


      fill(
        5,
        10,
        18,
        180
      );


      float bubbleWidth =
        value < 10
        ? 17
        : 25;


      ellipse(
        px,
        py,
        bubbleWidth,
        16
      );


      drawNumber(
        value,
        px,
        py,
        0.45,
        numberColor
      );

    }

  }

}


// ============================================================
// 출발점
// ============================================================

void drawStartPoint() {

  float x =
    screenX(
      startX
    );


  float y =
    screenY(
      startY
    );


  float pulse =
    0.5 +
    0.5 *
    sin(
      frameCount * 0.08
    );


  noStroke();


  fill(
    50,
    255,
    145,
    25
  );


  ellipse(
    x,
    y,
    65 +
    pulse * 12,
    65 +
    pulse * 12
  );


  fill(
    50,
    255,
    145,
    70
  );


  ellipse(
    x,
    y,
    36 +
    pulse * 5,
    36 +
    pulse * 5
  );


  fill(
    50,
    255,
    145
  );


  ellipse(
    x,
    y,
    17,
    17
  );


  fill(255);


  ellipse(
    x,
    y,
    5,
    5
  );

}


// ============================================================
// 목표점
// ============================================================

void drawGoalPoint() {

  float x =
    screenX(
      goalX
    );


  float y =
    screenY(
      goalY
    );


  float pulse =
    0.5 +
    0.5 *
    sin(
      frameCount * 0.10
    );


  noStroke();


  fill(
    255,
    55,
    85,
    25
  );


  ellipse(
    x,
    y,
    68 +
    pulse * 12,
    68 +
    pulse * 12
  );


  fill(
    255,
    55,
    85,
    70
  );


  ellipse(
    x,
    y,
    38 +
    pulse * 5,
    38 +
    pulse * 5
  );


  fill(
    255,
    60,
    90
  );


  ellipse(
    x,
    y,
    19,
    19
  );


  fill(255);


  ellipse(
    x,
    y,
    6,
    6
  );


  if (
    goalFoundPulse > 0
  ) {

    float radius =
      25 +
      (
        1 -
        goalFoundPulse
      )
      * 170;


    noFill();


    stroke(
      255,
      75,
      105,
      255 *
      goalFoundPulse
    );


    strokeWeight(
      5
    );


    ellipse(
      x,
      y,
      radius,
      radius
    );


    ellipse(
      x,
      y,
      radius * 0.65,
      radius * 0.65
    );

  }

}


// ============================================================
// 역추적
// ============================================================

void drawBacktrack() {

  if (
    traceLength < 2
  ) {

    return;

  }


  int count =
    min(
      backtrackVisible,
      traceLength
    );


  strokeCap(
    ROUND
  );


  noFill();


  // Glow

  stroke(
    205,
    80,
    255,
    42
  );


  strokeWeight(
    20
  );


  beginShape();


  for (
    int i = 0;
    i < count;
    i++
  ) {

    vertex(
      screenX(
        traceX[i]
      ),

      screenY(
        traceY[i]
      )
    );

  }


  endShape();


  // 실제 경로

  stroke(
    215,
    100,
    255,
    225
  );


  strokeWeight(
    7
  );


  beginShape();


  for (
    int i = 0;
    i < count;
    i++
  ) {

    vertex(
      screenX(
        traceX[i]
      ),

      screenY(
        traceY[i]
      )
    );

  }


  endShape();


  if (
    count > 0
  ) {

    int i =
      count - 1;


    float pulse =
      16 +
      sin(
        frameCount * 0.22
      )
      * 5;


    noStroke();


    fill(
      235,
      145,
      255,
      230
    );


    ellipse(
      screenX(
        traceX[i]
      ),

      screenY(
        traceY[i]
      ),

      pulse,
      pulse
    );

  }

}


// ============================================================
// 최종 최단경로
// ============================================================

void drawFinalPath() {

  if (
    pathLength < 2
  ) {

    return;

  }


  strokeCap(
    ROUND
  );


  noFill();


  stroke(
    255,
    205,
    35,
    30
  );


  strokeWeight(
    24
  );


  beginShape();


  for (
    int i = 0;
    i < pathLength;
    i++
  ) {

    vertex(
      screenX(
        pathX[i]
      ),

      screenY(
        pathY[i]
      )
    );

  }


  endShape();


  stroke(
    255,
    215,
    45,
    80
  );


  strokeWeight(
    14
  );


  beginShape();


  for (
    int i = 0;
    i < pathLength;
    i++
  ) {

    vertex(
      screenX(
        pathX[i]
      ),

      screenY(
        pathY[i]
      )
    );

  }


  endShape();


  stroke(
    255,
    225,
    65
  );


  strokeWeight(
    6
  );


  beginShape();


  for (
    int i = 0;
    i < pathLength;
    i++
  ) {

    vertex(
      screenX(
        pathX[i]
      ),

      screenY(
        pathY[i]
      )
    );

  }


  endShape();

}


// ============================================================
// 최단경로 순서 숫자
//
// 0 → 1 → 2 → 3 ...
// ============================================================

void drawPathNumbers() {

  if (
    pathLength < 2
  ) {

    return;

  }


  for (
    int i = 0;
    i < pathLength;
    i++
  ) {

    float x =
      screenX(
        pathX[i]
      );


    float y =
      screenY(
        pathY[i]
      ) - 18;


    float bubbleWidth =
      i < 10
      ? 20
      : 29;


    // 검은 배경

    noStroke();


    fill(
      5,
      8,
      14,
      235
    );


    ellipse(
      x,
      y,
      bubbleWidth,
      18
    );


    // 노란색 번호

    drawNumber(
      i,
      x,
      y,
      0.50,
      color(
        255,
        235,
        85
      )
    );

  }

}


// ============================================================
// 자동차 준비
// ============================================================

void prepareCar() {

  carSegment = 0;

  carT = 0;


  carX =
    screenX(
      pathX[0]
    );


  carY =
    screenY(
      pathY[0]
    );


  if (
    pathLength > 1
  ) {

    carAngle =
      atan2(

        screenY(
          pathY[1]
        )
        - carY,

        screenX(
          pathX[1]
        )
        - carX
      );

  }

}


// ============================================================
// 자동차 이동
// ============================================================

void updateCar() {

  if (
    carSegment >=
    pathLength - 1
  ) {

    carX =
      screenX(
        goalX
      );


    carY =
      screenY(
        goalY
      );


    arrivalPulse = 0;


    changeScene(
      ARRIVE
    );


    return;

  }


  float x1 =
    screenX(
      pathX[
        carSegment
      ]
    );


  float y1 =
    screenY(
      pathY[
        carSegment
      ]
    );


  float x2 =
    screenX(
      pathX[
        carSegment + 1
      ]
    );


  float y2 =
    screenY(
      pathY[
        carSegment + 1
      ]
    );


  carT +=
    CAR_SPEED;


  float t =
    constrain(
      carT,
      0,
      1
    );


  float eased =
    t * t *
    (
      3 -
      2 * t
    );


  carX =
    lerp(
      x1,
      x2,
      eased
    );


  carY =
    lerp(
      y1,
      y2,
      eased
    );


  carAngle =
    atan2(
      y2 - y1,
      x2 - x1
    );


  if (
    carT >= 1
  ) {

    carSegment++;

    carT = 0;

  }

}


// ============================================================
// 자동차
// ============================================================

void drawCar() {

  pushMatrix();


  translate(
    carX,
    carY
  );


  rotate(
    carAngle
  );


  noStroke();


  fill(
    255,
    225,
    70,
    25
  );


  ellipse(
    0,
    0,
    62,
    62
  );


  fill(
    255,
    225,
    70,
    55
  );


  ellipse(
    0,
    0,
    43,
    43
  );


  fill(
    0,
    0,
    0,
    100
  );


  rectMode(
    CENTER
  );


  rect(
    -2,
    3,
    31,
    18,
    6
  );


  fill(
    255,
    220,
    55
  );


  rect(
    0,
    0,
    30,
    17,
    6
  );


  fill(
    35,
    65,
    85
  );


  rect(
    4,
    0,
    10,
    12,
    3
  );


  fill(
    255,
    255,
    220
  );


  ellipse(
    14,
    -5,
    4,
    4
  );


  ellipse(
    14,
    5,
    4,
    4
  );


  rectMode(
    CORNER
  );


  popMatrix();

}


// ============================================================
// 도착
// ============================================================

void drawArrivalEffect() {

  float x =
    screenX(
      goalX
    );


  float y =
    screenY(
      goalY
    );


  float radius =
    arrivalPulse *
    250;


  float alpha =
    max(
      0,
      200 -
      arrivalPulse * 170
    );


  noFill();


  stroke(
    255,
    225,
    75,
    alpha
  );


  strokeWeight(
    5
  );


  ellipse(
    x,
    y,
    radius,
    radius
  );


  stroke(
    60,
    255,
    150,
    alpha * 0.8
  );


  strokeWeight(
    3
  );


  ellipse(
    x,
    y,
    radius * 0.65,
    radius * 0.65
  );


  float completion =
    constrain(
      sceneFrame / 90.0,
      0,
      1
    );


  noStroke();


  fill(

    lerp(
      255,
      55,
      completion
    ),

    lerp(
      60,
      255,
      completion
    ),

    lerp(
      90,
      145,
      completion
    )
  );


  ellipse(
    x,
    y,
    21,
    21
  );

}


// ============================================================
// 쿨타임
// ============================================================

void drawCooldown() {

  float t =
    constrain(
      sceneFrame /
      float(
        COOLDOWN_TIME
      ),
      0,
      1
    );


  float fade =
    constrain(

      map(
        t,
        0.30,
        1.0,
        0,
        1
      ),

      0,
      1
    );


  noStroke();


  fill(
    0,
    0,
    0,
    fade * 255
  );


  rect(
    0,
    0,
    width,
    height
  );


  if (
    t > 0.45
  ) {

    float local =
      map(
        t,
        0.45,
        1,
        0,
        1
      );


    float radius =
      local * 500;


    noFill();


    stroke(
      70,
      190,
      255,
      130 *
      (
        1 - local
      )
    );


    strokeWeight(
      3
    );


    ellipse(
      width / 2,
      height / 2,
      radius,
      radius
    );

  }

}


// ============================================================
// INTRO
// ============================================================

void drawIntro() {

  background(
    4,
    8,
    15
  );


  float cx =
    width / 2;


  float cy =
    height / 2;


  float fade =
    constrain(
      sceneFrame / 90.0,
      0,
      1
    );


  // 지도

  stroke(
    55,
    105,
    140,
    35 * fade
  );


  strokeWeight(
    1
  );


  for (
    int i = -9;
    i <= 9;
    i++
  ) {

    line(
      cx - 340,
      cy + i * 30,

      cx + 340,
      cy + i * 30
    );

  }


  for (
    int i = -11;
    i <= 11;
    i++
  ) {

    line(
      cx + i * 30,
      cy - 250,

      cx + i * 30,
      cy + 250
    );

  }


  // 탐색 파동

  float radar =
    (
      frameCount % 150
    )
    / 150.0;


  float radius =
    radar * 400;


  noFill();


  stroke(
    60,
    200,
    255,
    170 *
    (
      1 - radar
    )
  );


  strokeWeight(
    3
  );


  ellipse(
    cx,
    cy,
    radius,
    radius
  );


  // 출발

  float sx =
    cx - 230;


  float sy =
    cy + 120;


  float pulse =
    0.5 +
    0.5 *
    sin(
      frameCount * 0.09
    );


  noStroke();


  fill(
    55,
    255,
    145,
    35
  );


  ellipse(
    sx,
    sy,
    58 +
    pulse * 10,
    58 +
    pulse * 10
  );


  fill(
    55,
    255,
    145
  );


  ellipse(
    sx,
    sy,
    18,
    18
  );


  // 목표

  float gx =
    cx + 230;


  float gy =
    cy - 120;


  fill(
    255,
    55,
    90,
    35
  );


  ellipse(
    gx,
    gy,
    60 +
    pulse * 10,
    60 +
    pulse * 10
  );


  fill(
    255,
    55,
    90
  );


  ellipse(
    gx,
    gy,
    20,
    20
  );


  // 자동차

  float carAppear =
    constrain(
      (
        sceneFrame - 90
      )
      / 70.0,
      0,
      1
    );


  pushMatrix();


  translate(
    cx,
    cy
  );


  rotate(
    -PI / 4
  );


  noStroke();


  fill(
    255,
    225,
    65,
    255 *
    carAppear
  );


  rectMode(
    CENTER
  );


  rect(
    0,
    0,
    42,
    22,
    7
  );


  fill(
    40,
    70,
    90,
    255 *
    carAppear
  );


  rect(
    6,
    0,
    14,
    15,
    3
  );


  rectMode(
    CORNER
  );


  popMatrix();

}


// ============================================================
// OUTRO
// ============================================================

void drawOutro() {

  float t =
    constrain(
      sceneFrame /
      float(
        OUTRO_TIME
      ),
      0,
      1
    );


  float fade =
    pow(
      t,
      1.6
    );


  noStroke();


  fill(
    0,
    0,
    0,
    255 * fade
  );


  rect(
    0,
    0,
    width,
    height
  );


  if (
    t > 0.35 &&
    t < 0.90
  ) {

    float local =
      map(
        t,
        0.35,
        0.90,
        0,
        1
      );


    float leftX =
      lerp(
        width / 2 - 110,
        width / 2,
        local
      );


    float rightX =
      lerp(
        width / 2 + 110,
        width / 2,
        local
      );


    noStroke();


    fill(
      55,
      255,
      145,
      200 *
      (
        1 - local
      )
    );


    ellipse(
      leftX,
      height / 2,
      20,
      20
    );


    fill(
      255,
      60,
      90,
      200 *
      (
        1 - local
      )
    );


    ellipse(
      rightX,
      height / 2,
      20,
      20
    );


    fill(
      255,
      225,
      70,
      230 * local
    );


    ellipse(
      width / 2,
      height / 2,
      10 +
      local * 20,
      10 +
      local * 20
    );

  }

}


// ============================================================
// 숫자 전체 그리기
//
// text() 사용 안 함
// ============================================================

void drawNumber(
  int value,
  float centerX,
  float centerY,
  float scaleValue,
  color c
) {

  if (
    value < 0
  ) {

    return;

  }


  // 0

  if (
    value == 0
  ) {

    drawDigit(
      0,
      centerX,
      centerY,
      scaleValue,
      c
    );


    return;

  }


  int temp =
    value;


  int digitCount =
    0;


  int[] digits =
    new int[5];


  while (
    temp > 0
  ) {

    digits[digitCount] =
      temp % 10;


    temp =
      temp / 10;


    digitCount++;

  }


  float digitWidth =
    9 * scaleValue;


  float spacing =
    3 * scaleValue;


  float totalWidth =
    digitCount *
    digitWidth
    +
    (
      digitCount - 1
    )
    *
    spacing;


  float startX =
    centerX -
    totalWidth / 2
    +
    digitWidth / 2;


  for (
    int i = 0;
    i < digitCount;
    i++
  ) {

    int digit =
      digits[
        digitCount - 1 - i
      ];


    drawDigit(
      digit,

      startX +
      i *
      (
        digitWidth +
        spacing
      ),

      centerY,

      scaleValue,

      c
    );

  }

}


// ============================================================
// 숫자 1개
// ============================================================

void drawDigit(
  int digit,
  float x,
  float y,
  float s,
  color c
) {

  float horizontalLength =
    7 * s;


  float verticalLength =
    7 * s;


  float thickness =
    2.2 * s;


  float upperY =
    y -
    5 * s;


  float middleY =
    y;


  float lowerY =
    y +
    5 * s;


  float leftX =
    x -
    4 * s;


  float rightX =
    x +
    4 * s;


  noStroke();

  fill(c);


  rectMode(
    CENTER
  );


  // A

  if (
    DIGIT_SEGMENTS[digit][0]
  ) {

    rect(
      x,
      upperY,
      horizontalLength,
      thickness,
      thickness
    );

  }


  // B

  if (
    DIGIT_SEGMENTS[digit][1]
  ) {

    rect(
      rightX,
      y -
      2.5 * s,
      thickness,
      verticalLength,
      thickness
    );

  }


  // C

  if (
    DIGIT_SEGMENTS[digit][2]
  ) {

    rect(
      rightX,
      y +
      2.5 * s,
      thickness,
      verticalLength,
      thickness
    );

  }


  // D

  if (
    DIGIT_SEGMENTS[digit][3]
  ) {

    rect(
      x,
      lowerY,
      horizontalLength,
      thickness,
      thickness
    );

  }


  // E

  if (
    DIGIT_SEGMENTS[digit][4]
  ) {

    rect(
      leftX,
      y +
      2.5 * s,
      thickness,
      verticalLength,
      thickness
    );

  }


  // F

  if (
    DIGIT_SEGMENTS[digit][5]
  ) {

    rect(
      leftX,
      y -
      2.5 * s,
      thickness,
      verticalLength,
      thickness
    );

  }


  // G

  if (
    DIGIT_SEGMENTS[digit][6]
  ) {

    rect(
      x,
      middleY,
      horizontalLength,
      thickness,
      thickness
    );

  }


  rectMode(
    CORNER
  );

}


// ============================================================
// 좌표
// ============================================================

float screenX(
  int x
) {

  return
    originX +
    x * GAP;

}


float screenY(
  int y
) {

  return
    originY +
    y * GAP;

}
