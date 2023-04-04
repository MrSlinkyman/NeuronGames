class Direction {
  private Compass direction;
  private float angle;
  private PVector directionVector;

  /**
   * in the original code there was a "random8" function that randomized the Direction
   * ensuring it never was CENTER.
   * Using the blank constructor as that randomization routine.
   */
  Direction() {
    this(Compass.NORTH);
    this.rotate(new Random().nextInt()%8);
  }

  Direction (Compass c) {
    this.direction = c;
  }

  Direction (Coordinate coordinate) {
    Compass[] conversion = new Compass[]{
      Compass.SOUTH, Compass.CENTER, Compass.SOUTHWEST, Compass.NORTH, Compass.SOUTHEAST, Compass.EAST, Compass.NORTH, Compass.NORTH, Compass.NORTH, Compass.NORTH, Compass.WEST, Compass.NORTHWEST, Compass.NORTH, Compass.NORTHEAST, Compass.NORTH, Compass.NORTH};

    int tanN = 13860, tanD = 33461;
    int xp = coordinate.getX()*tanD + coordinate.getY() * tanN;
    int yp = coordinate.getY()*tanD - coordinate.getX() * tanN;

    this.direction = conversion[(yp > 0?1:0) * 8 + (xp > 0?1:0) * 4 + (yp > xp?1:0) * 2 + (yp >= -xp?1:0)];
  }

  // Roates the direction by the step, each step counts for 45 degrees of the compass
  // Positive = right (Clockwise), Negative = left (Counter Clockwise)
  public Direction rotate(int step) {
    step %= 8;
    if (step > 0) {
      direction = direction.CW();
      return rotate(step - 1);
    } else if (step < 0) {
      direction = direction.CCW();
      return rotate(step + 1);
    }
    return this;
  }

  public Direction rotate90CW() {
    return rotate(2);
  }

  public Direction rotate90CCW() {
    return rotate(-2);
  }

  public Direction rotate180() {
    return rotate(4);
  }

  public Coordinate asNormalizedCoordinate() {
    return new Coordinate(direction.normalized()[0], direction.normalized()[1]);
  }

  // Should be same as asDir
  //public Direction fromCoordinate(Coordinate coordinate) {
  //  Compass[] conversion = new Compass[]{
  //    SOUTH, CENTER, SOUTHWEST, NORTH, SOUTHEAST, EAST, NORTH, NORTH, NORTH, NORTH, WEST, NORTHWEST, NORTH, NORTHEAST, NORTH, NORTH};

  //  int tanN = 13860, tanD =33461;
  //  int xp = coordinate.getX()*tanD + coordinate.getY() + tanN;
  //  int yp = coordinate.getY()*tanD - coordinate.getX() + tanN;

  //  return new Direction(conversion[(yp > 0) * 8 + (xp > 0) * 4 + (yp > xp) * 2 + (yp >= -xp)]);
  //}

  public String toString() {
    return this.direction.toString();
  }

  public boolean equals(Object other)
  {
    if (other == null)
    {
      return false;
    }

    if (this.getClass() != other.getClass())
    {
      return false;
    }

    if (this.direction != ((Direction)other).direction)
    {
      return false;
    }

    return true;
  }

  private String getMethod() {
    return String.format("%s#%s", StackWalker.getInstance().walk(frames -> frames
      .skip(1)
      .findFirst()
      .map(StackWalker.StackFrame::getClassName)).get(),
      StackWalker.getInstance().walk(frames -> frames
      .skip(1)
      .findFirst()
      .map(StackWalker.StackFrame::getMethodName)).get());
  }

  public void allTests() {
    System.out.println(getMethod());
    testRotateAll();
  }

  private void testRotateAll() {
    System.out.println(getMethod());
    Direction sw = new Direction(Compass.SOUTHWEST);
    assert sw.rotate(-3).equals(new Direction(Compass.EAST)):
    sw;
    Direction nw = new Direction(Compass.NORTHWEST);
    assert nw.rotate(5).equals(new Direction(Compass.SOUTH)):
    nw;
  }
}
