/**
 * Gene
 * Structure: 8 hexadecimal digits
 * bits structure:
 * [from][to][weight]
 * * from/to = byte
 *          0 = source (input/internal or internal/output)
 *          1-7 = location (unsigned int mod # neurons)
 * * weight = short (divide to get small float around -4.0/4.0
 *
 * May use this only for testing, not for actual computation
 *
 */
class Gene {
  private NeuronType source;
  private short sourceNumber;
  private NeuronType target;
  private short targetNumber;
  private short weight;
  private byte[] startingBlueprint;

  private double weightScaler = 8192.0;

  /** This constructor creates a random gene
   */
  Gene() {
    makeGene(randomGenes());
  }

  /** This constructor creates a gene from a given hex string representation of a gene
   * e.g. a4f23501
   */
  Gene(String strGene) {
    assert strGene != null && strGene.length() == 8 :
    String.format("bad gene string:'%s'", strGene);

    byte[] newGene = new byte[4];
    newGene[0] = (byte)Integer.parseInt(strGene.substring(0, 2), 16);
    newGene[1] = (byte)Integer.parseInt(strGene.substring(2, 4), 16);
    newGene[2] = (byte)Integer.parseInt(strGene.substring(4, 6), 16);
    newGene[3] = (byte)Integer.parseInt(strGene.substring(6, 8), 16);
    makeGene(newGene);
  }

  /** This constructor creates a gene from a given byte array
   * the byte array should be 4 bytes long
   */
  Gene(byte[] gene) {
  assert gene != null && gene.length == 4 :
    String.format("Bad gene array:%s", gene);
    makeGene(gene);
  }

  Gene(long gene) {
    byte[] newGene = new byte[4];
    for (int i = 0; i < 4; i++) {
      newGene[3-i] = (byte)(gene >> 8*i);
    }
  }

  private void makeGene(byte[] gene) {
    this.startingBlueprint = gene;
    this.source = (gene[0] & 0x80) == 0? NeuronType.NEURON : NeuronType.SENSOR;
    this.sourceNumber = (short)Math.abs((gene[0] & 0x7F));
  assert sourceNumber >= 0 :
    String.format("found a negative sourceNumber:%d", sourceNumber);
    this.target = (gene[1] & 0x80) == 0? NeuronType.ACTION : NeuronType.NEURON;
    this.targetNumber = (short)Math.abs(gene[1] & 0x7F);
  assert targetNumber >= 0 :
    String.format("found a negative targetNumber:%d", targetNumber);
    this.weight = (short)(((gene[2] & 0xFF) <<8) | (gene[3] & 0xFF) );
  }

  public boolean matches(Gene comparison) {
    // Approximate gene match: Has to match same source, sink, with similar weight
    byte[] myBlueprint = getBlueprint();
    byte[] comparisonBlueprint = comparison.getBlueprint();

    for (int i = 0; i < 4; i++) {
      if (myBlueprint[i] != comparisonBlueprint[i]) return false;
    }

    return true;
  }

  public byte[] getBlueprint() {
    byte[] blueprint = new byte[4];
    blueprint[0] = (byte)(((source == NeuronType.SENSOR)?0x80:0x00) | sourceNumber & 0x7F);
    blueprint[1] = (byte)(((target == NeuronType.NEURON)?0x80:0x00) | targetNumber & 0x7F);
    blueprint[2] = (byte)(weight >> 8);
    blueprint[3] = (byte)(weight & 0xFF);
    return blueprint;
  }

  public String toString() {
    String str = "Gene:orig[";
    for (byte gene : startingBlueprint) {
      str += String.format("%02X", gene);
    }
    str+="],calc:[";
    for (byte gene : getBlueprint()) {
      str += String.format("%02X", gene);
    }
    str +="]=>";
    str+=String.format("[s(%s:%s), t(%s:%s), w:%f]",
      source,
      (NeuronType.SENSOR == source)?(sourceNumber < Sensor.values().length)?Sensor.values()[sourceNumber]:String.format("UNKNOWN:%d", sourceNumber):String.format("%d", sourceNumber),
      target,
      (NeuronType.ACTION == target)?(targetNumber < CreatureAction.values().length)?CreatureAction.values()[targetNumber]:String.format("UNKNOWN:%d", targetNumber):String.format("%d", targetNumber),
      getWeight());
    return str;
  }

  public String toIGraph() {
    return String.format("%s %s %d",
      (source == NeuronType.SENSOR)? (sourceNumber < Sensor.values().length)?Sensor.values()[sourceNumber].getShortName():String.format("N/A:%d", sourceNumber): String.format("N%d", sourceNumber),
      (target == NeuronType.ACTION)? (targetNumber < CreatureAction.values().length)?CreatureAction.values()[targetNumber].getShortName():String.format("N/A:%d", targetNumber): String.format("N%d", targetNumber),
      weight);
  }
  
  public double getWeight() {
    return weight/weightScaler;
  }

  private byte[] randomGenes() {
    byte[] gene = new byte[4];
    new Random().nextBytes(gene);
    return gene;
  }

  public NeuronType getSource() {
    return source;
  }

  public void setSensor(NeuronType source) {
    this.source = source;
  }

  public short getSourceNumber() {
    return sourceNumber;
  }

  public void setSourceNumber(short sourceNumber) {
    this.sourceNumber = sourceNumber;
  }

  public NeuronType getTarget() {
    return target;
  }

  public void setTarget(NeuronType target) {
    this.target = target;
  }

  public short getTargetNumber() {
    return targetNumber;
  }

  public void setTargetNumber(short targetNumber) {
    this.targetNumber = targetNumber;
  }

  public void setWeight(short weight) {
    this.weight = weight;
  }
  
  public void allTests(){
    testRandom();
  }
  
  private void testRandom(){
    Gene randomGene = new Gene();
    for(int i = 0; i < 100; i++){
      System.out.printf("Random gene: %s\n", randomGene);
      System.out.printf("Random gene: %s\n", randomGene.toIGraph());
      randomGene = new Gene();
    }
  }
}
