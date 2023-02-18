class Gene {
  private NeuronType sensor; 
  private short sensorSource; 
  private NeuronType target; 
  private short targetSource;
  private short weight;
  private byte[] geneBlueprint;
  
  private float weightScaler = 8192.0;
  
  /** This constructor creates a random gene
  */
  Gene(){
    byte[] gene = randomGenes();
    makeGene(gene);
  }
  
  /** This constructor creates a gene from a given hex string representation of a gene
   * e.g. a4f23501
  */
  Gene(String strGene){
    assert strGene != null && strGene.length() == 8 : strGene;
    
    byte[] newGene = new byte[4];
    newGene[0] = (byte)Integer.parseInt(strGene.substring(0,2), 16);
    newGene[1] = (byte)Integer.parseInt(strGene.substring(2,4), 16);
    newGene[2] = (byte)Integer.parseInt(strGene.substring(4,6), 16);
    newGene[3] = (byte)Integer.parseInt(strGene.substring(6,8), 16);
    makeGene(newGene);
  }
  
  /** This constructor creates a gene from a given byte array
    * the byte array should be 4 bytes long
  */
  Gene(byte[] gene){
    assert gene != null && gene.length == 4 : gene;
    makeGene(gene);
  }
  
  private void makeGene(byte[] gene){
    this.geneBlueprint = gene.clone();
    this.sensor = (gene[0] & 0x80) == 0?NeuronType.SENSOR : NeuronType.NEURON;
    this.sensorSource = (short)(gene[0] & 0x7F);
    this.target = (gene[1] & 0x80) == 0?NeuronType.NEURON : NeuronType.ACTION;
    this.targetSource = (short)(gene[1] & 0x7F);
    this.weight = (short)(((gene[2] & 0xFF) <<8) | (gene[3] & 0xFF) );
  }
  
  public byte[] getBlueprint(){
    return geneBlueprint;
  }
  
  public float getWeight(){
    return weight/weightScaler;
  }
  
  private byte[] randomGenes(){
   byte[] gene = new byte[4];
    new Random().nextBytes(gene);
    return gene;    
  }
  
}
