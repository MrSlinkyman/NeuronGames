// I means data about the individual, mainly stored in Creature
// W means data about the environment, mainly stored in Environment or Grid
enum Sensor {
  // Location sensors
  LOC_X("loc X", "Lx"), // I distance from left edge
  LOC_Y("loc Y", "Ly"), // I distance from bottom

  // Border sensors
  BOUNDARY_DIST_X("boundary dist X", "EDx"), // I X distance to nearest edge of world
  BOUNDARY_DIST("boundary dist", "ED"), // I distance to nearest edge of world
  BOUNDARY_DIST_Y("boundary dist Y", "EDy"), // I Y distance to nearest edge of world

  GENETIC_SIM_FWD("genetic similarity fwd", "Gen"), // I genetic similarity forward

  // Movement sensors
  LAST_MOVE_DIR_X("last move dir X", "LMx"), // I +- amount of X movement in last movement
  LAST_MOVE_DIR_Y("last move dir Y", "LMy"), // I +- amount of Y movement in last movement

  LONGPROBE_POP_FWD("long probe population fwd", "LPf"), // W long look for population forward
  LONGPROBE_BAR_FWD("long probe barrier fwd", "LPb"), // W long look for barriers forward

  // Population density
  POPULATION("population", "Pop"), // W population density in neighborhood
  POPULATION_FWD("population fwd", "Pfd"), // W population density in the forward-reverse axis
  POPULATION_LR("population LR", "Plr"), // W population density in the left-right axis

  OSC1("osc1", "Osc"), // I oscillator +-value
  AGE("age", "Age"), // I

  // Barriers
  BARRIER_FWD("short probe barrier fwd-rev", "Bfd"), // W neighborhood barrier distance forward-reverse axis
  BARRIER_LR("short probe barrier left-right", "Blr"), // W neighborhood barrier distance left-right axis

  RANDOM("random", "Rnd"), //   random sensor value, uniform distribution

  // Pheromones
  SIGNAL0("signal 0", "Sg"), // W strength of signal0/pheromone in neighborhood
  SIGNAL0_FWD("signal 0 fwd", "Sfd"), // W strength of signal0/pheromone in the forward-reverse axis
  SIGNAL0_LR("signal 0 LR", "Slr") // W strength of signal0/pheromone in the left-right axis
  ;

  private final String text;
  private final String shortName;
  private final boolean enabled; 

  Sensor() {
    this.text = "";
    this.shortName = "";
    enabled = false;
  }
  
  Sensor(String text, String shortName) {
    this(text, shortName, true);
  }

  Sensor(String text, String shortName, boolean enabled) {
    this.text = text;
    this.shortName = shortName;
    this.enabled = enabled;
  }

  public String getText() {
    return text;
  }

  public String getShortName() {
    return shortName;
  }
  
  public boolean isEnabled(){
    return enabled;
  }

  public static void printAllSensors() {
    System.out.println("Sensors:");
    for (Sensor sensor : values()) {
      if (sensor.isEnabled())
        System.out.printf("%s (%s)\n",sensor.getText(), sensor.getShortName());
    }
  }
}
