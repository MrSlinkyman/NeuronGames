# NeuronGames
You can almost consider this a fork/clone of https://github.com/davidrmiller/biosim4.  I translated @davidrmiller's code from C++ into Java/Processing.
It doesn't do everything biosim4 does, for example, I have not yet pulled over all of the analysis functionality.  Also, I used Processing so that I can run this
more realtime so you can see the little creatures moving about.

Kudos to David for an amazing [YouTube Video](https://www.youtube.com/watch?v=N3tRFayqVtk&t=3029s) explaining his simulator and how it works, as well as all the
tips in the video and the code to interpret what it does.

# Processing specific things
Some of the changes I've made in the Processing world.

1. As mentioned, I modified this to be more realtime.  In the original biosim4 code, the generation and sim step code are in multi-threaded loops.
In Processing I made those part of the main "draw" loop.  This way the environment, the grid, and the creatures can update the display with each sim step.
2. Since this is now in a realtime visualization window, I added some keyboard shortcuts for 
    * running(b)/pausing(p) the simulation, 
    * saving the current generation(s), and loading a new generation(l), and
    * saving the entire history of the current simulation(h), though this is probably going to be removed.  Takes forever and the files are huge.
3. I also added a way to interrogate individual creatures with the mouse.
    * Left Click - pauses/unpauses the simulation
    * Right Click - On a blank space just tells you what the coordinate is in both the grid-centric coordinate space and the real coordinate space.
    On a Creature it outputs some information about the creature including its genome and neural network configuration.
4. I added visualization of the barriers and goals (Challenges) to have a better idea of what the creatures are trying to accomplish.
    
# Java changes
Since I'm using Java I ended up adding more pieces to the enums.  E.g. The Sensor enum also includes its name so that doesn't have to be determined separately.
I also didn't make the configuration items a file, rather they are captured as enums.  I also changed some of the names based on my own preferences, no big other reason.

# Where will this go?
I didn't want to just make a port and be done with it.  While a fun exercise, my ultimate goal is to expand the evolution simulation to include resource utilization,
various kinds of energy usage, more interactivity between creatures (try to get predator/prey relationships evolving), and ultimately to get the "petri dish" to develop
into a balanced ecosystem.  

# Future enhancements
I'll probably start capturing these as Issues or something but intially I want to do the following:
* Moar Javadoc
* File based configuration similar to biosim4.ini such that parameters can change throughout simulation.
* Energy mechanics
* More interesting visualizations such as visual indicators of parents that are actually used to spawn the next generation, more interesting creature designs
like colors, genome inspired shapes, limbs for mobility as dictated by the sensors/actions, etc.
* Modify the start to have selectable Challenge and Barrier types instead of forcing it to be enum based.
* Support multiple Challenges at once
* Currently only supprts a petri dish type world with walls, modify to support an infinite seeming world (boundaries portal to the opposite side)
* Implement the other comparison methods
* Support saving simulation steps as frames to eventually create a video of an interesting population.  Maybe even support saving the entire history of a population...could be memory hog!
