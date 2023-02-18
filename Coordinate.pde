class Coordinate {
  private int x, y;
  
  Coordinate(int x, int y){
    this.x = x;
    this.y = y;
  }
  
  public double length() {
    return Math.sqrt(x*x + y*y);
  }
  
  public int getX(){
    return this.x;
  }
  
  public int getY(){
    return this.y;
  }
  
  public Coordinate add(Coordinate right){
    return new Coordinate(this.x + right.getX(), this.y + right.getY());
  }
  
  public Coordinate subtract(Coordinate right){
    return new Coordinate(this.x - right.getX(), this.y - right.getY());
  }
  
}
