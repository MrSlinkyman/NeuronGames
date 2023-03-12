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
 */class Gene {
  private NeuronType sensor;
  private short sensorSource;
  private NeuronType target;
  private short targetSource;
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
    assert strGene != null && strGene.length() == 8 : String.format("bad gene string:'%s'", strGene);

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
  assert gene != null && gene.length == 4 : String.format("Bad gene array:%s", gene);
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
    this.sensor = (gene[0] & 0x80) == 0? NeuronType.NEURON : NeuronType.SENSOR;
    this.sensorSource = (short)Math.abs((gene[0] & 0x7F));
  assert sensorSource >= 0 :
    String.format("found a negative sensorSource:%d", sensorSource);
    this.target = (gene[1] & 0x80) == 0? NeuronType.ACTION : NeuronType.NEURON;
    this.targetSource = (short)Math.abs(gene[1] & 0x7F);
  assert targetSource >= 0 :
    String.format("found a negative targetSource:%d", targetSource);
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
    blueprint[0] = (byte)(((sensor == NeuronType.SENSOR)?0x80:0x00) | sensorSource & 0x7F);
    blueprint[1] = (byte)(((target == NeuronType.NEURON)?0x80:0x00) | targetSource & 0x7F);
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
    str+=String.format("[s(%s:%s), t(%s:%s), w:%f]", sensor, (NeuronType.SENSOR == sensor)?Sensor.values()[sensorSource]:String.format("%d",sensorSource), target, (NeuronType.ACTION == target)?CreatureAction.values()[targetSource]:String.format("%d",targetSource), getWeight());
    return str;
  }

  public double getWeight() {
    return weight/weightScaler;
  }

  private byte[] randomGenes() {
    byte[] gene = new byte[4];
    new Random().nextBytes(gene);
    return gene;
  }

  public NeuronType getSensor() {
    return sensor;
  }

  public void setSensor(NeuronType sensor) {
    this.sensor = sensor;
  }

  public short getSensorSource() {
    return sensorSource;
  }

  public void setSensorSource(short sensorSource) {
    this.sensorSource = sensorSource;
  }

  public NeuronType getTarget() {
    return target;
  }

  public void setTarget(NeuronType target) {
    this.target = target;
  }

  public short getTargetSource() {
    return targetSource;
  }

  public void setTargetSource(short targetSource) {
    this.targetSource = targetSource;
  }

  public void setWeight(short weight) {
    this.weight = weight;
  }
}
