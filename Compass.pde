enum Compass {
  SOUTHWEST("SW", 0, 3, 1, -1, -1),
    SOUTH("S", 1, 0, 2, 0, -1),
    SOUTHEAST("SE", 2, 1, 5, 1, -1),
    WEST("W", 3, 6, 0, -1, 0),
    CENTER("C", 4, 4, 4, 0, 0),
    EAST("E", 5, 2, 8, 1, 0),
    NORTHWEST("NW", 6, 7, 3, -1, -1),
    NORTH("N", 7, 8, 6, 0, 1),
    NORTHEAST("NE", 8, 5, 7, 1, 1);

  private final String acronym;
  private final int value;
  private final int right;
  private final int left;
  private final int x;
  private final int y;

  Compass(String acronym, int value, int right, int left, int x, int y) {
    this.acronym = acronym;
    this.value = value;
    this.right = right;
    this.left = left;
    this.x = x;
    this.y = y;
  }

  static Compass findByValue(int value) {
    for (Compass c : Compass.values()) {
      if (c.value == value) return c;
    }
    return null;
  }

  Compass findByAcronynm(String acronym) {
    for (Compass c : Compass.values()) {
      if (c.acronym == acronym) return c;
    }
    return null;
  }

  Compass CW() {
    return findByValue(right);
  }

  Compass CCW() {
    return findByValue(left);
  }

  int[] normalized() {
    return new int[]{x, y};
  }
}
