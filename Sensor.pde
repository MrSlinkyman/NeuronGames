// Place the sensor neuron you want enabled prior to NUM_SENSES. Any
// that are after NUM_SENSES will be disabled in the simulator.
// If new items are added to this enum, also update the name functions
// in analysis.cpp.
// I means data about the individual, mainly stored in Indiv
// W means data about the environment, mainly stored in Peeps or Grid
enum Sensor {
  LOC_X("loc X"), // I distance from left edge
    LOC_Y("loc Y"), // I distance from bottom
    BOUNDARY_DIST_X("boundary dist X"), // I X distance to nearest edge of world
    BOUNDARY_DIST("boundary dist"), // I distance to nearest edge of world
    BOUNDARY_DIST_Y("boundary dist Y"), // I Y distance to nearest edge of world
    GENETIC_SIM_FWD("genetic similarity fwd"), // I genetic similarity forward
    LAST_MOVE_DIR_X("last move dir X"), // I +- amount of X movement in last movement
    LAST_MOVE_DIR_Y("last move dir Y"), // I +- amount of Y movement in last movement
    LONGPROBE_POP_FWD("long probe population fwd"), // W long look for population forward
    LONGPROBE_BAR_FWD("long probe barrier fwd"), // W long look for barriers forward
    POPULATION("population"), // W population density in neighborhood
    POPULATION_FWD("population fwd"), // W population density in the forward-reverse axis
    POPULATION_LR("population LR"), // W population density in the left-right axis
    OSC1("osc1"), // I oscillator +-value
    AGE("age"), // I
    BARRIER_FWD("short probe barrier fwd-rev"), // W neighborhood barrier distance forward-reverse axis
    BARRIER_LR("short probe barrier left-right"), // W neighborhood barrier distance left-right axis
    RANDOM("random"), //   random sensor value, uniform distribution
    SIGNAL0("signal 0"), // W strength of signal0 in neighborhood
    SIGNAL0_FWD("signal 0 fwd"), // W strength of signal0 in the forward-reverse axis
    SIGNAL0_LR("signal 0 LR"), // W strength of signal0 in the left-right axis
    NUM_SENSES("");

  private final String text;

  Sensor(String text) {
    this.text = text;
  }

  public String getText() {
    return text;
  }

  public void printAllSensors() {
    System.out.println("Sensors:");
    for (Sensor sensor : values()) {
      if (sensor.ordinal() < NUM_SENSES.ordinal())
        System.out.println(sensor.getText());
    }
  }
}
