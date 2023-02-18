class Environment {

  private java.util.List<Integer> deathQueue;
  private java.util.List<Object[]> moveQueue;
  private Creature[] creatures;
  private Grid environment;
  
  // TODO: refactor to a getter/setter
  public int[] genomeInitialRange = new int[]{4,8};
  public int maxNeurons = 4;

  Environment(int maxNeurons, int[] genomeRange) {
    this();
    this.maxNeurons = maxNeurons;
    this.genomeInitialRange = genomeRange;
  }
  
  Environment() {
    creatures = new Creature[]{};
    environment = new Grid();
    deathQueue = new java.util.ArrayList<Integer>();
    moveQueue = new java.util.ArrayList<Object[]>();
  }

  public void initialize(int population) {
    // Index == 0 is a special case
    creatures = new Creature[population+1];
  }

  public void queueForDeath(Creature deadCreature) {
    assert deadCreature.isAlive() : deadCreature;
    deathQueue.add(deadCreature.getIndex());
  }
  public void drainDeathQueue() {
    for(int index : deathQueue){
      Creature ghost = creatures[index];
      environment.set(ghost.getLocation(), GridState.EMPTY.getValue());
      ghost.setAlive(false);
    }
    
    deathQueue.clear();
    
  }
  public void queueForMove(Creature creature, Coordinate newLocation) {
    assert creature.isAlive() : creature;
    
    moveQueue.add(new Object[]{creature.getIndex(), newLocation});
  }
  public void drainMoveQueue() {
    
    for(Object[] record : moveQueue){
      Creature creature = creatures[(int)record[0]];
      if(creature.isAlive()){
        Coordinate newLocation = (Coordinate)record[1];
        Direction moveDirection = new Direction(newLocation.subtract(creature.getLocation()));
        if(environment.isEmptyAt(newLocation)){
          environment.set(creature.getLocation(), GridState.EMPTY.getValue());
          environment.set(newLocation, creature.getIndex());
          creature.setLocation(newLocation);
          creature.setLastMoveDirection(moveDirection);
        }
      }
    }
  }

  public int deathQueueSize() {
    return deathQueue.size();
  }

  // findCreature() does no error checking -- check first that loc is occupied
  public Creature findCreature(Coordinate coord) {
    return creatures[environment.at(coord)];
  }
  
  // Direct access:
  public Creature at(int index){
    return creatures[index];
  }
      
}
