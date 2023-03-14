/** //<>//
  * I means the action affects the individual internally (Creature)
  * W means the action also affects the environment (Environment or Grid)
  */
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
    ROTATE("Rotate relative to creature", "Rr"), // W
    ROTATE_ABSOLUTE("Rotate relative to world", "Ra"),
    //NUM_ACTIONS(), // <<----------------- END OF ACTIVE ACTIONS MARKER
    KILL_FORWARD("kill fwd", "Klf", false);      // W

  private final String name;
  private final String shortName;
  private final boolean enabled;

  CreatureAction() {
    name = "";
    shortName = "";
    enabled = false;
  }

  /**
   * CreatureActions made with this constructor will default to enabled
   */
  CreatureAction(String name, String shortName) {
    this.name = name;
    this.shortName = shortName;
    enabled = true;
  }

  /**
   * CreatureActions made with this constructor can set whether or not the action is enabled
   */
  CreatureAction(String name, String shortName, boolean enabled) {
    this.name = name;
    this.shortName = shortName;
    this.enabled = enabled;
  }

  /**
   * Only a subset of all possible actions might be enabled (i.e., compiled in).
   * This returns true if the specified action is enabled.
   */
  public boolean isEnabled() {
    return enabled;
  }

  public String getName() {
    return name;
  }

  public String getShortName() {
    return shortName;
  }

  public static void printAllActions() {
    Parameters.debugOutput("Actions:\n");
    for (CreatureAction action : values()) {
      if (action.isEnabled()) Parameters.debugOutput(action.getName());
    }
  }
}
