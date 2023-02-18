enum GridState {
  EMPTY(0),
  BARRIER(Integer.MAX_VALUE);
  
  private int value;
  
  GridState(int value){
    this.value = value;
  }
  
  public GridState findByValue(int value){
    for(GridState item : GridState.values()){
      if(item.value == value) return item;
    }
    return null;
  }
  
  public int getValue(){
    return value;
  }
}
