class Grid {
  private int[][] data;
  
  Grid(){
  }
  
  void initialize(int width, int height){
    data = new int[width][height];
  }
  
  public void zeroFill(){
    for(int i = 0; i < data.length; i++){
      for(int j = 0; j < data[i].length; j++){
        data[i][j] = 0;
      }
    }
  }
  
  public int getSizeX(){
    return data.length;
  }
  
  public int getSizeY(){
    return data[0].length;
  }
  
  public boolean isEmptyAt(Coordinate coord){
    return 0==data[coord.getX()][coord.getY()];
  }
  
  public int at(Coordinate coord){
    return data[coord.getX()][coord.getY()];
  }
  
  public void set(Coordinate location, int value){
    data[location.getX()][location.getY()] = value;
  }
}
