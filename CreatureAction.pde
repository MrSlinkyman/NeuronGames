// Place the action neuron you want enabled prior to NUM_ACTIONS. Any //<>// //<>// //<>//
// that are after NUM_ACTIONS will be disabled in the simulator.
// If new items are added to this enum, also update the name functions
// in analysis.cpp.
// I means the action affects the individual internally (Indiv)
// W means the action also affects the environment (Peeps or Grid)
enum CreatureAction {
  MOVE_X("move X", "MvX"), // W +- X component of movement
  MOVE_Y("move Y", "MvY"), // W +- Y component of movement
  MOVE_FORWARD("move fwd", "Mfd"), // W continue last direction
  MOVE_RL("move R-L", "MRL"), // W +- component of movement
  MOVE_RANDOM("move random", "Mrn"), // W
  SET_OSCILLATOR_PERIOD("set osc1", "OSC"), // I
  SET_LONGPROBE_DIST("set longprobe dist", "LPD"), // I
  SET_RESPONSIVENESS("set inv-responsiveness", "Res"), // I
  EMIT_SIGNAL0("emit pheromone", "SG"), // W
  MOVE_EAST("move east", "MvE"), // W
  MOVE_WEST("move west", "MvW"), // W
  MOVE_NORTH("move north", "MvN"), // W
  MOVE_SOUTH("move south", "MvS"), // W
  MOVE_LEFT("move left", "MvL"), // W
  MOVE_RIGHT("move right", "MvR"), // W
  MOVE_REVERSE("move reverse", "Mrv"), // W
  NUM_ACTIONS(), // <<----------------- END OF ACTIVE ACTIONS MARKER
  KILL_FORWARD("kill fwd", "Klf");      // W

  private final String name;
  private final String shortName;

  CreatureAction() {
    name = "";
    shortName = "";
  }
  CreatureAction(String name, String shortName) {
    this.name = name;
    this.shortName = shortName;
  }

  /**
   * Only a subset of all possible actions might be enabled (i.e., compiled in).
   * This returns true if the specified action is enabled. See sensors-actions.h
   * for how to enable sensors and actions during compilation.
   */
  public boolean isEnabled() {
    return NUM_ACTIONS.ordinal() > ordinal();
  }

  /**
   * Returns the name of this action.
   */
  public String getName() {
    return name;
  }

  /**
   * Returns the short name of this action.
   */
  public String getShortName() {
    return shortName;
  }

  public void printAllActions() {
    Parameters.debugOutput("Actions:\n");
    for (CreatureAction action : values()) {
      if (action.ordinal() < NUM_ACTIONS.ordinal()) Parameters.debugOutput(action.getName());
    }
  }
}
