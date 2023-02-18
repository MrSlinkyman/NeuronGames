class Creature {
  private int index;
  private Coordinate location;
  private Genome genome;

  private int age;
  private boolean alive;
  private Direction lastMoveDirection;
  private NeuralNet brain;
  private double responsiveness;
  private int longProbeDistance; // This should be set at the main level
  private boolean challengeBits;


  Creature(int index, Coordinate location, Genome genome) {
    Random rand = new Random();
    this.index = index;
    this.location = location;
    this.genome = genome;
    this.age = 0;
    this.alive = true;
    this.lastMoveDirection = new Direction(Compass.findByValue(rand.nextInt(8)));
    initializeBrain(genome);
    responsiveness = 0.5;
    challengeBits = false;
    createWiringFromGenome();
  }

  private void initializeBrain(Genome genome) {
    //brain = new NeuralNet();
  }

  public boolean isAlive() {
    return alive;
  }

  public void setAlive(boolean alive) {
    this.alive = alive;
  }

  public int getIndex() {
    return index;
  }

  public Coordinate getLocation() {
    return location;
  }

  public void setLocation(Coordinate newLocation) {
    location = newLocation;
  }
  
  public void setLastMoveDirection(Direction direction){
    this.lastMoveDirection = direction;
  }
  
  private void createWiringFromGenome(){
  }
  
}
