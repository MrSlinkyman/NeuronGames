// Place the action neuron you want enabled prior to NUM_ACTIONS. Any //<>// //<>// //<>// //<>//
// that are after NUM_ACTIONS will be disabled in the simulator.
// If new items are added to this enum, also update the name functions
// in analysis.cpp.
// I means the action affects the individual internally (Indiv)
// W means the action also affects the environment (Peeps or Grid)
enum CreatureAction {
  MOVE_X("move X"), // W +- X component of movement
    MOVE_Y("move Y"), // W +- Y component of movement
    MOVE_FORWARD("move fwd"), // W continue last direction
    MOVE_RL("move R-L"), // W +- component of movement
    MOVE_RANDOM("move random"), // W
    SET_OSCILLATOR_PERIOD("set osc1"), // I
    SET_LONGPROBE_DIST("set longprobe dist"), // I
    SET_RESPONSIVENESS("set inv-responsiveness"), // I
    EMIT_SIGNAL0("emit signal 0"), // W
    MOVE_EAST("move east"), // W
    MOVE_WEST("move west"), // W
    MOVE_NORTH("move north"), // W
    MOVE_SOUTH("move south"), // W
    MOVE_LEFT("move left"), // W
    MOVE_RIGHT("move right"), // W
    MOVE_REVERSE("move reverse"), // W
    NUM_ACTIONS(""), // <<----------------- END OF ACTIVE ACTIONS MARKER
    KILL_FORWARD("kill fwd");      // W

  private final String name;

  CreatureAction(String name) {
    this.name = name;
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

  public void printAllActions() {
    Parameters.debugOutput("Actions:\n");
    for (CreatureAction action : values()) {
      if (action.ordinal() < NUM_ACTIONS.ordinal()) Parameters.debugOutput(action.getName());
    }
  }
}
