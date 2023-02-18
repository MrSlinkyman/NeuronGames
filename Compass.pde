enum Compass {
    SOUTHWEST("SW", 0, 3, 1),
    SOUTH("S", 1, 0, 2),
    SOUTHEAST("SE", 2, 1, 5),
    WEST("W", 3, 6, 0),
    CENTER("C", 4, 4, 4),
    EAST("E", 5, 2, 8),
    NORTHWEST("NW", 6, 7, 3),
    NORTH("N",7, 8, 6),
    NORTHEAST("NE",8, 5, 7);
    
    private final String acronym;
    private final int value;
    private final int right;
    private final int left;
    
    Compass(String acronym, int value, int right, int left){
      this.acronym = acronym;
      this.value = value;
      this.right = right;
      this.left = left;
    }
    
    static Compass findByValue(int value){
      for (Compass c : Compass.values()){
        if(c.value == value) return c;
      }
      return null;
    }
    
    Compass findByAcronynm(String acronym){
     for (Compass c : Compass.values()){
        if(c.acronym == acronym) return c;
      }
      return null;
    }
    
    Compass CW(){
      return findByValue(right);
    }
    
    Compass CCW(){
      return findByValue(left);
    }
    
}
  
